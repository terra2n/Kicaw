-- Supabase Data Seeder for Smart Room ECO2
-- Generates 30 days of realistic history for sensor logs, activity logs, and daily summaries.

DO $$
DECLARE
  v_date DATE;
  v_timestamp TIMESTAMPTZ;
  v_temp REAL;
  v_humidity REAL;
  v_co2 INTEGER;
  v_motion BOOLEAN;
  v_lamp BOOLEAN;
  v_fan BOOLEAN;
  v_hour INTEGER;
  v_day_offset INTEGER;
  v_room TEXT := 'ruangan_01';
BEGIN
  -- Truncate existing logs to ensure clean state
  TRUNCATE TABLE sensor_logs RESTART IDENTITY CASCADE;
  TRUNCATE TABLE activity_logs RESTART IDENTITY CASCADE;
  TRUNCATE TABLE daily_summaries RESTART IDENTITY CASCADE;

  -- Ensure room_status has the single row
  INSERT INTO room_status (id, room_name, temperature_c, humidity_percent, co2_ppm, motion_detected, lamp_status, fan_status, updated_at)
  VALUES (1, v_room, 24.5, 62.0, 420, false, false, false, NOW())
  ON CONFLICT (id) DO UPDATE SET
    room_name = EXCLUDED.room_name,
    temperature_c = EXCLUDED.temperature_c,
    humidity_percent = EXCLUDED.humidity_percent,
    co2_ppm = EXCLUDED.co2_ppm,
    motion_detected = EXCLUDED.motion_detected,
    lamp_status = EXCLUDED.lamp_status,
    fan_status = EXCLUDED.fan_status,
    updated_at = NOW();

  -- Loop through the last 30 days
  FOR v_day_offset IN REVERSE 30..1 LOOP
    v_date := CURRENT_DATE - v_day_offset;
    
    -- Generate hourly sensor data for each day
    FOR v_hour IN 0..23 LOOP
      v_timestamp := v_date + (v_hour * INTERVAL '1 hour') + (random() * 5 * INTERVAL '1 minute');
      
      -- Temperature model: cooler at night/early morning, warmer in the afternoon
      -- Sine wave with peak at 14:00 (2 PM)
      v_temp := 24.0 + 3.5 * sin((v_hour - 8)::DOUBLE PRECISION * pi() / 12.0) + (random() - 0.5) * 0.8;
      
      -- Humidity model: inverse of temperature
      v_humidity := 68.0 - 12.0 * sin((v_hour - 8)::DOUBLE PRECISION * pi() / 12.0) + (random() - 0.5) * 1.5;
      
      -- Motion detection and CO2 model
      -- People are typically in the room during work hours (8:00 to 18:00) or evening (19:00 to 22:00)
      IF (v_hour >= 8 AND v_hour <= 17 AND random() < 0.75) OR 
         (v_hour >= 19 AND v_hour <= 21 AND random() < 0.6) THEN
        v_motion := true;
        -- CO2 rises when people are present
        v_co2 := 550 + (random() * 350)::INTEGER;
        -- Lamp is ON if it's dark (morning/evening) or randomly
        IF v_hour < 7 OR v_hour >= 17 THEN
          v_lamp := true;
        ELSE
          v_lamp := random() < 0.3; -- occasionally on during day
        END IF;
      ELSE
        v_motion := false;
        -- CO2 drops to outdoor base levels
        v_co2 := 380 + (random() * 50)::INTEGER;
        v_lamp := false;
      END IF;

      -- Fan is ON if temperature is high (> 26.0)
      v_fan := (v_temp > 26.0);

      -- Insert sensor log
      INSERT INTO sensor_logs (room_name, temperature_c, humidity_percent, co2_ppm, motion_detected, lamp_status, fan_status, recorded_at)
      VALUES (v_room, round(v_temp::numeric, 1), round(v_humidity::numeric, 1), v_co2, v_motion, v_lamp, v_fan, v_timestamp);

      -- Insert activity logs on state changes
      -- To make it simple, we insert some events throughout the day
      IF v_motion AND random() < 0.3 THEN
        -- Motion detected event
        INSERT INTO activity_logs (room_name, event_type, description, metadata, created_at)
        VALUES (v_room, 'motion_detected', 'Gerakan terdeteksi di ruangan', jsonb_build_object('co2_ppm', v_co2), v_timestamp);
        
        -- If lamp was off, turn it on
        IF v_lamp THEN
          INSERT INTO activity_logs (room_name, event_type, description, metadata, created_at)
          VALUES (v_room, 'lamp_on', 'Lampu dinyalakan otomatis', jsonb_build_object('wattage', 3.0), v_timestamp + INTERVAL '5 seconds');
        END IF;
      ELSIF NOT v_motion AND random() < 0.2 AND v_hour >= 8 AND v_hour <= 22 THEN
        -- Motion cleared event
        INSERT INTO activity_logs (room_name, event_type, description, metadata, created_at)
        VALUES (v_room, 'motion_cleared', 'Ruangan kosong (tidak ada gerakan)', NULL, v_timestamp);
        
        -- Turn off lamp
        IF NOT v_lamp THEN
          INSERT INTO activity_logs (room_name, event_type, description, metadata, created_at)
          VALUES (v_room, 'lamp_off', 'Lampu dimatikan otomatis untuk hemat energi', NULL, v_timestamp + INTERVAL '10 seconds');
        END IF;
      END IF;

      -- CO2 alert event if CO2 > 800
      IF v_co2 > 800 AND random() < 0.2 THEN
        INSERT INTO activity_logs (room_name, event_type, description, metadata, created_at)
        VALUES (v_room, 'co2_alert', 'Konsentrasi CO₂ tinggi!', jsonb_build_object('co2_ppm', v_co2), v_timestamp + INTERVAL '1 minute');
      END IF;
    END LOOP;
    
    -- Call the database function to aggregate daily summaries for this date
    -- This keeps summaries in sync with sensor/activity logs!
    PERFORM aggregate_daily_summary(v_room, v_date);
  END LOOP;

  -- Update live room_status with the last generated values
  UPDATE room_status
  SET
    temperature_c = round(v_temp::numeric, 1),
    humidity_percent = round(v_humidity::numeric, 1),
    co2_ppm = v_co2,
    motion_detected = v_motion,
    lamp_status = v_lamp,
    fan_status = v_fan,
    updated_at = NOW()
  WHERE id = 1;
  
END $$;
