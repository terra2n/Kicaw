-- Supabase Database Schema for Smart Room ECO2
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/_/sql

-- Enable Realtime for all tables
BEGIN;

-- ============================================
-- 1. ROOM STATUS (Live Data)
-- ============================================
CREATE TABLE IF NOT EXISTS room_status (
  id BIGINT PRIMARY KEY DEFAULT 1,
  room_name TEXT NOT NULL DEFAULT 'ruangan_01',
  temperature_c REAL,
  humidity_percent REAL,
  co2_ppm INTEGER,
  motion_detected BOOLEAN DEFAULT FALSE,
  lamp_status BOOLEAN DEFAULT FALSE,
  fan_status BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Ensure only one room_status record
  CONSTRAINT single_room_status CHECK (id = 1)
);

-- Insert initial record
INSERT INTO room_status (id, room_name) VALUES (1, 'ruangan_01')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 2. SENSOR LOGS (Historical Data)
-- ============================================
CREATE TABLE IF NOT EXISTS sensor_logs (
  id BIGSERIAL PRIMARY KEY,
  room_name TEXT NOT NULL DEFAULT 'ruangan_01',
  temperature_c REAL,
  humidity_percent REAL,
  co2_ppm INTEGER,
  motion_detected BOOLEAN,
  lamp_status BOOLEAN,
  fan_status BOOLEAN,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_sensor_logs_recorded_at ON sensor_logs(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_sensor_logs_room_name ON sensor_logs(room_name);

-- ============================================
-- 3. DAILY SUMMARIES (Aggregated Data)
-- ============================================
CREATE TABLE IF NOT EXISTS daily_summaries (
  id BIGSERIAL PRIMARY KEY,
  room_name TEXT NOT NULL DEFAULT 'ruangan_01',
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  avg_temperature_c REAL,
  avg_humidity_percent REAL,
  avg_co2_ppm REAL,
  max_co2_ppm INTEGER,
  min_co2_ppm INTEGER,
  motion_count INTEGER DEFAULT 0,
  lamp_on_minutes INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Ensure one summary per room per day
  UNIQUE(room_name, date)
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_daily_summaries_date ON daily_summaries(date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_summaries_room_name ON daily_summaries(room_name);

-- ============================================
-- 4. ACTIVITY LOGS (Event History)
-- ============================================
CREATE TABLE IF NOT EXISTS activity_logs (
  id BIGSERIAL PRIMARY KEY,
  room_name TEXT NOT NULL DEFAULT 'ruangan_01',
  event_type TEXT NOT NULL, -- 'motion_detected', 'motion_cleared', 'lamp_on', 'lamp_off', 'co2_alert', etc
  description TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_logs_event_type ON activity_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_activity_logs_room_name ON activity_logs(room_name);

-- ============================================
-- 5. ENABLE REALTIME
-- ============================================
-- Enable realtime for room_status safely
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_rel pr
    JOIN pg_class c ON c.oid = pr.prrelid
    JOIN pg_publication p ON p.oid = pr.prpubid
    WHERE p.pubname = 'supabase_realtime'
      AND c.relname = 'room_status'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE room_status;
  END IF;
END $$;

-- Enable realtime for sensor_logs safely
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_rel pr
    JOIN pg_class c ON c.oid = pr.prrelid
    JOIN pg_publication p ON p.oid = pr.prpubid
    WHERE p.pubname = 'supabase_realtime'
      AND c.relname = 'sensor_logs'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE sensor_logs;
  END IF;
END $$;

-- Enable realtime for activity_logs safely
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_rel pr
    JOIN pg_class c ON c.oid = pr.prrelid
    JOIN pg_publication p ON p.oid = pr.prpubid
    WHERE p.pubname = 'supabase_realtime'
      AND c.relname = 'activity_logs'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE activity_logs;
  END IF;
END $$;

-- ============================================
-- 6. ROW LEVEL SECURITY (RLS)
-- ============================================
-- Enable RLS
ALTER TABLE room_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE sensor_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to make it idempotent
DROP POLICY IF EXISTS "Allow anonymous read" ON room_status;
DROP POLICY IF EXISTS "Allow anonymous read" ON sensor_logs;
DROP POLICY IF EXISTS "Allow anonymous read" ON daily_summaries;
DROP POLICY IF EXISTS "Allow anonymous read" ON activity_logs;

DROP POLICY IF EXISTS "Allow anonymous insert" ON room_status;
DROP POLICY IF EXISTS "Allow anonymous insert" ON sensor_logs;
DROP POLICY IF EXISTS "Allow anonymous insert" ON daily_summaries;
DROP POLICY IF EXISTS "Allow anonymous insert" ON activity_logs;

DROP POLICY IF EXISTS "Allow anonymous update" ON room_status;
DROP POLICY IF EXISTS "Allow anonymous update" ON daily_summaries;

-- Policy: Allow anonymous read for all tables
CREATE POLICY "Allow anonymous read" ON room_status FOR SELECT USING (true);
CREATE POLICY "Allow anonymous read" ON sensor_logs FOR SELECT USING (true);
CREATE POLICY "Allow anonymous read" ON daily_summaries FOR SELECT USING (true);
CREATE POLICY "Allow anonymous read" ON activity_logs FOR SELECT USING (true);

-- Policy: Allow anonymous insert for sensor_logs and activity_logs
CREATE POLICY "Allow anonymous insert" ON sensor_logs FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow anonymous insert" ON activity_logs FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow anonymous insert" ON daily_summaries FOR INSERT WITH CHECK (true);

-- Policy: Allow anonymous insert for room_status
-- PENTING: Dibutuhkan agar UPSERT (Prefer: resolution=merge-duplicates) dari ESP32 bisa jalan
-- Tanpa ini, HTTP POST ke room_status akan gagal dengan 403 RLS Violation
CREATE POLICY "Allow anonymous insert" ON room_status FOR INSERT WITH CHECK (true);

-- Policy: Allow anonymous update for room_status and daily_summaries
CREATE POLICY "Allow anonymous update" ON room_status FOR UPDATE USING (true);
CREATE POLICY "Allow anonymous update" ON daily_summaries FOR UPDATE USING (true);

-- ============================================
-- 7. FUNCTIONS
-- ============================================

-- Function to aggregate daily summaries
CREATE OR REPLACE FUNCTION aggregate_daily_summary(p_room_name TEXT, p_date DATE)
RETURNS VOID AS $$
DECLARE
  v_avg_temp REAL;
  v_avg_humidity REAL;
  v_avg_co2 REAL;
  v_max_co2 INTEGER;
  v_min_co2 INTEGER;
  v_motion_count INTEGER;
  v_lamp_minutes INTEGER;
BEGIN
  -- Calculate averages from sensor_logs
  SELECT
    AVG(temperature_c),
    AVG(humidity_percent),
    AVG(co2_ppm),
    MAX(co2_ppm),
    MIN(co2_ppm)
  INTO v_avg_temp, v_avg_humidity, v_avg_co2, v_max_co2, v_min_co2
  FROM sensor_logs
  WHERE room_name = p_room_name
    AND DATE(recorded_at) = p_date;

  -- Count motion events
  SELECT COUNT(*)
  INTO v_motion_count
  FROM activity_logs
  WHERE room_name = p_room_name
    AND DATE(created_at) = p_date
    AND event_type = 'motion_detected';

  -- Calculate lamp on minutes (simplified: count lamp_on events * 5 minutes)
  SELECT COUNT(*) * 5
  INTO v_lamp_minutes
  FROM activity_logs
  WHERE room_name = p_room_name
    AND DATE(created_at) = p_date
    AND event_type = 'lamp_on';

  -- Upsert daily summary
  INSERT INTO daily_summaries (
    room_name, date, avg_temperature_c, avg_humidity_percent,
    avg_co2_ppm, max_co2_ppm, min_co2_ppm, motion_count, lamp_on_minutes
  ) VALUES (
    p_room_name, p_date, v_avg_temp, v_avg_humidity,
    v_avg_co2, v_max_co2, v_min_co2, v_motion_count, v_lamp_minutes
  )
  ON CONFLICT (room_name, date)
  DO UPDATE SET
    avg_temperature_c = EXCLUDED.avg_temperature_c,
    avg_humidity_percent = EXCLUDED.avg_humidity_percent,
    avg_co2_ppm = EXCLUDED.avg_co2_ppm,
    max_co2_ppm = EXCLUDED.max_co2_ppm,
    min_co2_ppm = EXCLUDED.min_co2_ppm,
    motion_count = EXCLUDED.motion_count,
    lamp_on_minutes = EXCLUDED.lamp_on_minutes;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clean up old sensor logs (keep last 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_logs()
RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  DELETE FROM sensor_logs
  WHERE recorded_at < NOW() - INTERVAL '30 days';

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

COMMIT;
