import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';
import '../../services/realtime_service.dart';
import '../../services/firestore_service.dart';
import '../../models/room_status.dart';
import '../../widgets/fade_slide.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/empty_state.dart';
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
  final _refreshCtrl = StreamController<void>.broadcast();

  Future<void> _onRefresh() async {
    _refreshCtrl.add(null);
  }

  @override
  void dispose() {
    _refreshCtrl.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Smart Room'),
            StreamBuilder<RoomStatus>(
              stream: _rt.statusStream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Row(
                    children: [
                      Container(width: 6, height: 6,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent)),
                      const SizedBox(width: 4),
                      const Text('Connection error', style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w400)),
                    ],
                  );
                }
                final online = snap.data != null && snap.connectionState == ConnectionState.active;
                return Row(
                  children: [
                    Container(width: 6, height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        color: online ? const Color(0xFF22C55E) : Colors.grey)),
                    const SizedBox(width: 4),
                    Text(
                      online ? 'ESP32 Online' : 'Connecting\u2026',
                      style: TextStyle(fontSize: 12,
                        color: online ? const Color(0xFF6B7280) : Colors.grey,
                        fontWeight: FontWeight.w400),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const FadeSlide(index: 0, child: SectionHeader(title: 'ROOM STATUS')),
              FadeSlide(index: 1, child: StreamBuilder<RoomStatus>(
                stream: _rt.statusStream,
                builder: (context, snap) {
                  if (snap.hasError) return const ErrorBanner(message: 'Failed to get room status', onRetry: null);
                  if (!snap.hasData) return const ShimmerBlock(height: 160);
                  return StatusHeroCard(status: snap.data!);
                },
              )),
              const SizedBox(height: 24),
              const FadeSlide(index: 2, child: SectionHeader(title: 'ENERGY AUDIT — TODAY')),
              FadeSlide(index: 3, child: StreamBuilder<RoomStatus>(
                stream: _rt.statusStream,
                builder: (context, snap) {
                  if (snap.hasError) return const ErrorBanner(message: 'Energy data unavailable');
                  final s = snap.data ?? RoomStatus.empty;
                  return EnergyGrid(
                    whSaved: s.savedEnergyWh,
                    co2Mg: s.preventedCo2Mg,
                    minutesOff: (s.savedEnergyWh / 3 * 60).toInt(),
                    lampPowerW: 3,
                  );
                },
              )),
              const SizedBox(height: 24),
              const FadeSlide(index: 4, child: SectionHeader(title: 'LAST 7 DAYS')),
              FadeSlide(index: 5, child: StreamBuilder<List<double>>(
                stream: _fs.getDailyLogs(7).map((logs) {
                  return logs.reversed.map((l) => l.whSaved).toList();
                }),
                builder: (context, snap) {
                  if (snap.hasError) return const ErrorBanner(message: 'Chart data unavailable');
                  if (!snap.hasData) return const ShimmerBlock(height: 140);
                  if (snap.data!.isEmpty) return const EmptyState(icon: Icons.bar_chart, title: 'No chart data yet');
                  return WeeklyChart(values: snap.data!);
                },
              )),
              const SizedBox(height: 24),
              const FadeSlide(index: 6, child: SectionHeader(title: 'RECENT ACTIVITY')),
              FadeSlide(index: 7, child: StreamBuilder<List<ActivityItem>>(
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
                  if (snap.hasError) return const ErrorBanner(message: 'Activity log unavailable');
                  if (!snap.hasData) return const ShimmerBlock(height: 100);
                  if (snap.data!.isEmpty) return const EmptyState(icon: Icons.history, title: 'No activity yet');
                  return RecentActivity(items: snap.data!);
                },
              )),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
