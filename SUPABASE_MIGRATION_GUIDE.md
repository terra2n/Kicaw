# 🚀 Firebase to Supabase Migration - Battle Plan

## 📋 Overview
Migrate from Firebase (Realtime Database + Firestore) to Supabase (PostgreSQL + Realtime)

**Timeline:** 12-14 hours  
**Cost:** FREE (no credit card required)  
**Difficulty:** Medium-Hard

---

## 🎯 Phase 1: Supabase Setup (1-2 hours)

### Step 1: Create Supabase Account
1. Go to https://supabase.com
2. Sign up with GitHub
3. Create new project:
   - **Name:** `smart-room-eco2`
   - **Database Password:** (save this!)
   - **Region:** Southeast Asia (Singapore)
   - **Pricing:** Free tier (Hobby plan)

### Step 2: Get Credentials
After project created:
1. Go to **Settings** → **API**
2. Copy these:
   - **Project URL:** `https://xxxxx.supabase.co`
   - **anon/public key:** `eyJhbGc...` (safe to expose)
   - **service_role key:** `eyJhbGc...` (KEEP SECRET!)

### Step 3: Database Schema
Run this SQL in Supabase SQL Editor:

```sql
-- Enable realtime for all tables
alter publication supabase_realtime add all;

-- Table: room_status (live data)
create table room_status (
  id serial primary key,
  room_name text not null default 'ruangan_01',
  temperature_c float,
  humidity_percent float,
  co2_ppm int,
  motion_detected boolean default false,
  lamp_status boolean default false,
  fan_status boolean default false,
  updated_at timestamp with time zone default now()
);

-- Table: sensor_logs (historical data)
create table sensor_logs (
  id bigserial primary key,
  room_name text not null,
  temperature_c float,
  humidity_percent float,
  co2_ppm int,
  motion_detected boolean,
  lamp_status boolean,
  fan_status boolean,
  recorded_at timestamp with time zone default now()
);

-- Table: daily_summaries (aggregated data)
create table daily_summaries (
  id serial primary key,
  room_name text not null,
  date date not null,
  avg_temperature_c float,
  avg_humidity_percent float,
  avg_co2_ppm float,
  max_co2_ppm int,
  min_co2_ppm int,
  motion_count int default 0,
  lamp_on_minutes int default 0,
  unique(room_name, date)
);

-- Table: activity_logs (events)
create table activity_logs (
  id bigserial primary key,
  room_name text not null,
  event_type text not null, -- 'motion_detected', 'lamp_on', 'lamp_off', 'co2_alert', etc
  description text,
  metadata jsonb,
  created_at timestamp with time zone default now()
);

-- Indexes for performance
create index idx_sensor_logs_recorded_at on sensor_logs(recorded_at desc);
create index idx_sensor_logs_room on sensor_logs(room_name);
create index idx_daily_summaries_date on daily_summaries(date desc);
create index idx_activity_logs_created_at on activity_logs(created_at desc);

-- Row Level Security (RLS) - allow all for now
alter table room_status enable row level security;
alter table sensor_logs enable row level security;
alter table daily_summaries enable row level security;
alter table activity_logs enable row level security;

-- RLS Policies (allow all operations with anon key)
create policy "Allow all operations" on room_status for all using (true) with check (true);
create policy "Allow all operations" on sensor_logs for all using (true) with check (true);
create policy "Allow all operations" on daily_summaries for all using (true) with check (true);
create policy "Allow all operations" on activity_logs for all using (true) with check (true);
```

### Step 4: Create Supabase Edge Function (for aggregation)
Create file: `supabase/functions/aggregate-daily/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const yesterday = new Date()
  yesterday.setDate(yesterday.getDate() - 1)
  const dateStr = yesterday.toISOString().split('T')[0]

  // Aggregate sensor data
  const { data: logs, error } = await supabase
    .from('sensor_logs')
    .select('*')
    .gte('recorded_at', yesterday.toISOString())
    .lt('recorded_at', new Date().toISOString())

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  if (!logs || logs.length === 0) {
    return new Response(JSON.stringify({ message: 'No data to aggregate' }), {
      headers: { 'Content-Type': 'application/json' }
    })
  }

  // Calculate averages
  const avgTemp = logs.reduce((sum, l) => sum + (l.temperature_c || 0), 0) / logs.length
  const avgHumidity = logs.reduce((sum, l) => sum + (l.humidity_percent || 0), 0) / logs.length
  const avgCO2 = logs.reduce((sum, l) => sum + (l.co2_ppm || 0), 0) / logs.length
  const maxCO2 = Math.max(...logs.map(l => l.co2_ppm || 0))
  const minCO2 = Math.min(...logs.map(l => l.co2_ppm || 0))
  const motionCount = logs.filter(l => l.motion_detected).length

  // Upsert daily summary
  const { error: upsertError } = await supabase
    .from('daily_summaries')
    .upsert({
      room_name: 'ruangan_01',
      date: dateStr,
      avg_temperature_c: avgTemp,
      avg_humidity_percent: avgHumidity,
      avg_co2_ppm: avgCO2,
      max_co2_ppm: maxCO2,
      min_co2_ppm: minCO2,
      motion_count: motionCount,
    }, {
      onConflict: 'room_name,date'
    })

  if (upsertError) {
    return new Response(JSON.stringify({ error: upsertError.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  return new Response(JSON.stringify({ 
    success: true, 
    date: dateStr,
    records: logs.length 
  }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

Schedule this function to run daily at midnight using pg_cron:
```sql
-- Schedule daily aggregation at midnight
select cron.schedule(
  'aggregate-daily-summary',
  '0 0 * * *', -- every day at midnight
  $$
  select net.http_post(
    url := 'https://xxxxx.supabase.co/functions/v1/aggregate-daily',
    headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb
  );
  $$
);
```

---

## 🎯 Phase 2: ESP32 Migration (3-4 hours)

### Step 1: Install Supabase Library
Add to `platformio.ini`:
```ini
lib_deps =
  mobizt/FirebaseClient@^1.4.0
  ESP32 Supabase Client
```

Or use HTTP client directly (simpler):
```cpp
#include <HTTPClient.h>
#include <ArduinoJson.h>
```

### Step 2: Create Supabase Helper
File: `esp32_iot/include/supabase.h`

```cpp
#ifndef SUPABASE_H
#define SUPABASE_H

#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <WiFi.h>

class SupabaseClient {
private:
  String supabaseUrl;
  String supabaseKey;
  
public:
  SupabaseClient(String url, String key) : supabaseUrl(url), supabaseKey(key) {}
  
  // Update room status
  bool updateRoomStatus(float temp, float humidity, int co2, bool motion, bool lamp, bool fan) {
    HTTPClient http;
    String url = supabaseUrl + "/rest/v1/room_status?id=eq.1";
    
    http.begin(url);
    http.addHeader("apikey", supabaseKey);
    http.addHeader("Authorization", "Bearer " + supabaseKey);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Prefer", "return=minimal");
    
    StaticJsonDocument<512> doc;
    doc["temperature_c"] = temp;
    doc["humidity_percent"] = humidity;
    doc["co2_ppm"] = co2;
    doc["motion_detected"] = motion;
    doc["lamp_status"] = lamp;
    doc["fan_status"] = fan;
    doc["updated_at"] = "now()";
    
    String payload;
    serializeJson(doc, payload);
    
    int httpCode = http.PATCH(payload);
    http.end();
    
    return httpCode == 204;
  }
  
  // Insert sensor log
  bool insertSensorLog(float temp, float humidity, int co2, bool motion, bool lamp, bool fan) {
    HTTPClient http;
    String url = supabaseUrl + "/rest/v1/sensor_logs";
    
    http.begin(url);
    http.addHeader("apikey", supabaseKey);
    http.addHeader("Authorization", "Bearer " + supabaseKey);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Prefer", "return=minimal");
    
    StaticJsonDocument<512> doc;
    doc["room_name"] = "ruangan_01";
    doc["temperature_c"] = temp;
    doc["humidity_percent"] = humidity;
    doc["co2_ppm"] = co2;
    doc["motion_detected"] = motion;
    doc["lamp_status"] = lamp;
    doc["fan_status"] = fan;
    
    String payload;
    serializeJson(doc, payload);
    
    int httpCode = http.POST(payload);
    http.end();
    
    return httpCode == 201;
  }
  
  // Insert activity log
  bool insertActivityLog(String eventType, String description) {
    HTTPClient http;
    String url = supabaseUrl + "/rest/v1/activity_logs";
    
    http.begin(url);
    http.addHeader("apikey", supabaseKey);
    http.addHeader("Authorization", "Bearer " + supabaseKey);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Prefer", "return=minimal");
    
    StaticJsonDocument<512> doc;
    doc["room_name"] = "ruangan_01";
    doc["event_type"] = eventType;
    doc["description"] = description;
    
    String payload;
    serializeJson(doc, payload);
    
    int httpCode = http.POST(payload);
    http.end();
    
    return httpCode == 201;
  }
};

#endif
```

### Step 3: Update Main ESP32 Code
Replace Firebase calls with Supabase:

```cpp
// In setup()
SupabaseClient supabase(SUPABASE_URL, SUPABASE_KEY);

// In loop() - every 5 seconds
if (millis() - lastUpdate > 5000) {
  lastUpdate = millis();
  
  supabase.updateRoomStatus(temperature, humidity, co2, motion, lampOn, fanOn);
  supabase.insertSensorLog(temperature, humidity, co2, motion, lampOn, fanOn);
}

// On state changes
if (motionDetected != lastMotionState) {
  lastMotionState = motionDetected;
  supabase.insertActivityLog(
    motionDetected ? "motion_detected" : "motion_cleared",
    motionDetected ? "Motion detected in room" : "Motion cleared"
  );
}

if (lampOn != lastLampState) {
  lastLampState = lampOn;
  supabase.insertActivityLog(
    lampOn ? "lamp_on" : "lamp_off",
    lampOn ? "Lamp turned on" : "Lamp turned off"
  );
}
```

---

## 🎯 Phase 3: Flutter Migration (4-5 hours)

### Step 1: Add Supabase Dependency
```yaml
dependencies:
  supabase_flutter: ^2.0.0
```

### Step 2: Initialize Supabase
In `main.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://xxxxx.supabase.co',
    anonKey: 'eyJhbGc...',
  );
  
  runApp(MyApp());
}
```

### Step 3: Replace Firebase Services

**Old: RealtimeService**
```dart
// Firebase
final ref = FirebaseDatabase.instance.ref('room_status');
ref.onValue.listen((event) {
  final data = event.snapshot.value;
});
```

**New: SupabaseService**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _client = Supabase.instance.client;
  
  // Get room status (realtime)
  Stream<RoomStatus> getRoomStatusStream() {
    return _client
        .from('room_status')
        .stream(primaryKey: ['id'])
        .eq('room_name', 'ruangan_01')
        .map((data) {
          if (data.isEmpty) return RoomStatus.empty();
          return RoomStatus.fromJson(data.first);
        });
  }
  
  // Get sensor logs (historical)
  Future<List<SensorLog>> getSensorLogs({int limit = 100}) async {
    final data = await _client
        .from('sensor_logs')
        .select()
        .eq('room_name', 'ruangan_01')
        .order('recorded_at', ascending: false)
        .limit(limit);
    
    return data.map((json) => SensorLog.fromJson(json)).toList();
  }
  
  // Get daily summaries
  Future<List<DailySummary>> getDailySummaries({int days = 30}) async {
    final data = await _client
        .from('daily_summaries')
        .select()
        .eq('room_name', 'ruangan_01')
        .order('date', ascending: false)
        .limit(days);
    
    return data.map((json) => DailySummary.fromJson(json)).toList();
  }
  
  // Get activity logs
  Future<List<ActivityLog>> getActivityLogs({int limit = 50}) async {
    final data = await _client
        .from('activity_logs')
        .select()
        .eq('room_name', 'ruangan_01')
        .order('created_at', ascending: false)
        .limit(limit);
    
    return data.map((json) => ActivityLog.fromJson(json)).toList();
  }
}
```

### Step 4: Update Models
Create new models for Supabase:

```dart
// models/room_status.dart
class RoomStatus {
  final int? id;
  final String roomName;
  final double? temperatureC;
  final double? humidityPercent;
  final int? co2Ppm;
  final bool motionDetected;
  final bool lampStatus;
  final bool fanStatus;
  final DateTime updatedAt;
  
  RoomStatus({
    this.id,
    required this.roomName,
    this.temperatureC,
    this.humidityPercent,
    this.co2Ppm,
    required this.motionDetected,
    required this.lampStatus,
    required this.fanStatus,
    required this.updatedAt,
  });
  
  factory RoomStatus.fromJson(Map<String, dynamic> json) {
    return RoomStatus(
      id: json['id'] as int?,
      roomName: json['room_name'] as String,
      temperatureC: (json['temperature_c'] as num?)?.toDouble(),
      humidityPercent: (json['humidity_percent'] as num?)?.toDouble(),
      co2Ppm: json['co2_ppm'] as int?,
      motionDetected: json['motion_detected'] as bool? ?? false,
      lampStatus: json['lamp_status'] as bool? ?? false,
      fanStatus: json['fan_status'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  factory RoomStatus.empty() => RoomStatus(
    roomName: 'ruangan_01',
    motionDetected: false,
    lampStatus: false,
    fanStatus: false,
    updatedAt: DateTime.now(),
  );
}
```

### Step 5: Update Pages
Replace all Firebase streams with Supabase streams in your pages.

---

## 🎯 Phase 4: Testing (2 hours)

### Test Checklist:
- [ ] ESP32 can connect to Supabase
- [ ] ESP32 updates room_status table
- [ ] ESP32 inserts sensor_logs
- [ ] ESP32 inserts activity_logs on state changes
- [ ] Flutter receives realtime updates
- [ ] Flutter displays historical data
- [ ] Daily aggregation function works
- [ ] All pages show correct data

---

## 🎯 Phase 5: Deployment (1 hour)

### ESP32:
1. Update `secrets.h` with Supabase credentials
2. Upload to ESP32
3. Monitor serial output for errors

### Flutter:
1. Update Supabase URL and key in `main.dart`
2. Build and test on device/emulator
3. Deploy to Play Store (if needed)

---

## 🔥 Common Issues & Solutions

### Issue 1: ESP32 SSL Certificate Error
**Solution:** Use `WiFiClientSecure` with certificate or disable verification (not recommended for production)

### Issue 2: Supabase RLS Blocking Requests
**Solution:** Check RLS policies, ensure anon key has proper permissions

### Issue 3: Flutter Realtime Not Working
**Solution:** Ensure `alter publication supabase_realtime add all;` was run

### Issue 4: HTTP 401 Unauthorized
**Solution:** Verify API key is correct (use anon key for Flutter, service_role for Edge Functions)

---

## 📊 Cost Comparison

| Feature | Firebase (Blaze) | Supabase (Free) |
|---------|------------------|-----------------|
| Database | $0.18/GB | 500MB free |
| Realtime | Included | Included |
| Bandwidth | $0.12/GB | 2GB free |
| Edge Functions | $0.30/1M invocations | 500K free |
| Storage | $0.026/GB | 1GB free |
| **Monthly Cost** | **~$5-10** | **$0** |

---

## 📚 Resources

- Supabase Docs: https://supabase.com/docs
- Flutter Guide: https://supabase.com/docs/guides/getting-started/quickstarts/flutter
- REST API: https://supabase.com/docs/guides/api
- Realtime: https://supabase.com/docs/guides/realtime

---

## ✅ Success Criteria

- [ ] All Firebase references removed
- [ ] ESP32 successfully writes to Supabase
- [ ] Flutter displays realtime data
- [ ] Historical data queries work
- [ ] Daily aggregation runs automatically
- [ ] No errors in ESP32 serial monitor
- [ ] No errors in Flutter debug console

**Good luck! You got this! 💪**
