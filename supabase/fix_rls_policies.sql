-- ============================================
-- ADD INSERT POLICIES FOR SUPABASE TABLES
-- ============================================
-- Run this in Supabase SQL Editor
-- This allows ESP32 and Flutter to insert data

-- room_status: Allow insert
CREATE POLICY "Allow anon insert room_status" ON room_status
FOR INSERT TO anon
WITH CHECK (true);

-- sensor_logs: Allow insert
CREATE POLICY "Allow anon insert sensor_logs" ON sensor_logs
FOR INSERT TO anon
WITH CHECK (true);

-- daily_summaries: Allow insert
CREATE POLICY "Allow anon insert daily_summaries" ON daily_summaries
FOR INSERT TO anon
WITH CHECK (true);

-- activity_logs: Allow insert
CREATE POLICY "Allow anon insert activity_logs" ON activity_logs
FOR INSERT TO anon
WITH CHECK (true);

-- ============================================
-- ADD UPDATE POLICIES (for room_status)
-- ============================================
-- room_status: Allow update
CREATE POLICY "Allow anon update room_status" ON room_status
FOR UPDATE TO anon
USING (true)
WITH CHECK (true);

-- ============================================
-- VERIFY POLICIES
-- ============================================
-- Run this to check all policies:
-- SELECT tablename, policyname, cmd, roles
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;
