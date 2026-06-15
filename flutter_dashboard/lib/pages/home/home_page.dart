import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/section_header.dart';
import '../../services/realtime_service.dart';
import '../../services/firestore_service.dart';
import '../../models/room_status.dart';
import 'widgets/status_hero_card.dart';
import 'widgets/energy_grid.dart';
import 'widgets/weekly_chart.dart';
import 'widgets/recent_activity.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RealtimeService _rt = RealtimeService();
  final FirestoreService _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Smart Room'),
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.dotGreen,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'ESP32 Online',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const SectionHeader(title: 'ROOM STATUS'),
              StreamBuilder<RoomStatus>(
                stream: _rt.statusStream,
                builder: (context, snap) {
                  final status = snap.data ?? RoomStatus.empty;
                  return StatusHeroCard(status: status);
                },
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'ENERGY AUDIT — TODAY'),
              StreamBuilder<RoomStatus>(
                stream: _rt.statusStream,
                builder: (context, snap) {
                  final s = snap.data ?? RoomStatus.empty;
                  return EnergyGrid(
                    whSaved: s.savedEnergyWh,
                    co2Mg: s.preventedCo2Mg,
                    minutesOff: (s.savedEnergyWh / 10 * 60).toInt(),
                    lampPowerW: 10,
                  );
                },
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'LAST 7 DAYS'),
              StreamBuilder<List<double>>(
                stream: _fs.getDailyLogs(7).map((logs) {
                  return logs.reversed.map((l) => l.whSaved).toList();
                }),
                builder: (context, snap) {
                  final vals = snap.data ?? [0.02, 0.015, 0.03, 0.01, 0.025, 0.018, 0.022];
                  return WeeklyChart(values: vals);
                },
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'RECENT ACTIVITY'),
              StreamBuilder<List<ActivityItem>>(
                stream: _fs.getRecentActivity(5).map((logs) {
                  return logs.map((l) => ActivityItem(
                    event: l.event,
                    type: l.type,
                    whSaved: l.whSaved,
                    co2Mg: l.co2Mg,
                    timestamp: l.timestamp,
                  )).toList();
                }),
                builder: (context, snap) {
                  final items = snap.data ??
                    [
                      ActivityItem(event: 'Light on · person detected', type: 'on', whSaved: 0, co2Mg: 0, timestamp: DateTime(2026, 6, 15, 10, 30)),
                      ActivityItem(event: 'Light off · saved 0.008 Wh', type: 'off', whSaved: 0.008, co2Mg: 6.8, timestamp: DateTime(2026, 6, 15, 10, 25)),
                    ];
                  return RecentActivity(items: items);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
