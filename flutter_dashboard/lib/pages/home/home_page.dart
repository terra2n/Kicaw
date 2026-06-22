import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';
import '../../services/supabase_service.dart';
import '../../models/supabase/room_status.dart' as supa;
import '../../models/supabase/daily_summary.dart';
import '../../models/supabase/activity_log.dart';
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
  final SupabaseService _supa = SupabaseService();

  // Bug #10 fix: Future diinisialisasi sekali di initState, bukan tiap build()
  late Future<List<DailySummary>> _weeklyFuture;

  @override
  void initState() {
    super.initState();
    _weeklyFuture = _supa.getDailySummaries(days: 7);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Smart Room'),
            StreamBuilder<supa.RoomStatus?>(
              stream: _supa.streamRoomStatus(),
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
                final status = snap.data;
                final connected = status != null;

                Color dotColor;
                String text;
                if (!connected) {
                  dotColor = Colors.grey;
                  text = 'Connecting…';
                } else {
                  final age = DateTime.now().difference(status.updatedAt);
                  final online = age.inSeconds < 15;
                  if (online) {
                    dotColor = const Color(0xFF22C55E);
                    text = 'ESP32 Online';
                  } else {
                    dotColor = Colors.redAccent;
                    text = 'ESP32 Offline';
                  }
                }

                return Row(
                  children: [
                    Container(width: 6, height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
                    const SizedBox(width: 4),
                    Text(
                      text,
                      style: TextStyle(fontSize: 12,
                        color: connected ? const Color(0xFF6B7280) : Colors.grey,
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
        onRefresh: () async {
          // Bug #10 fix: Refresh juga memperbarui future weekly chart
          setState(() {
            _weeklyFuture = _supa.getDailySummaries(days: 7);
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ROOM STATUS
              const FadeSlide(index: 0, child: SectionHeader(title: 'ROOM STATUS')),
              FadeSlide(index: 1, child: StreamBuilder<supa.RoomStatus?>(
                stream: _supa.streamRoomStatus(),
                builder: (context, snap) {
                  if (snap.hasError) return const ErrorBanner(message: 'Failed to get room status', onRetry: null);
                  if (!snap.hasData) return const ShimmerBlock(height: 160);
                  if (snap.data == null) return const EmptyState(icon: Icons.wifi_off, title: 'No data from ESP32');
                  return StatusHeroCard(status: snap.data!);
                },
              )),

              const SizedBox(height: 24),

              // ENERGY AUDIT
              const FadeSlide(index: 2, child: SectionHeader(title: 'ENERGY AUDIT — TODAY')),
              FadeSlide(index: 3, child: StreamBuilder<supa.RoomStatus?>(
                stream: _supa.streamRoomStatus(),
                builder: (context, snap) {
                  if (snap.hasError) return const ErrorBanner(message: 'Energy data unavailable');
                  final s = snap.data;
                  if (s == null) return const ShimmerBlock(height: 100);

                  // Estimate energy from lamp status and motion
                  // This will be more accurate once ESP32 pushes calculated values
                  final minutesOff = s.lampStatus ? 0 : 5; // Placeholder
                  final whSaved = s.co2Ppm != null ? (s.co2Ppm! / 1000.0) * 0.003 : 0.0;
                  final co2Mg = whSaved * 0.85; // 850g CO2/kWh

                  return EnergyGrid(
                    whSaved: whSaved,
                    co2Mg: co2Mg,
                    minutesOff: minutesOff,
                    lampPowerW: 3,
                  );
                },
              )),

              const SizedBox(height: 24),

              // LAST 7 DAYS
              const FadeSlide(index: 4, child: SectionHeader(title: 'LAST 7 DAYS')),
              FadeSlide(index: 5, child: FutureBuilder<List<DailySummary>>(
                future: _weeklyFuture,  // Bug #10 fix: Pakai cached future, bukan buat baru tiap build
                builder: (context, snap) {
                  if (snap.hasError) return const ErrorBanner(message: 'Chart data unavailable');
                  if (!snap.hasData) return const ShimmerBlock(height: 140);
                  if (snap.data!.isEmpty) return const EmptyState(icon: Icons.bar_chart, title: 'No chart data yet');

                  // Convert daily summaries to whSaved values for chart
                  final values = snap.data!.reversed.map((d) {
                    return (d.avgCo2Ppm ?? 0) * 0.003 * 0.85; // Rough CO2 to Wh conversion
                  }).toList();

                  return WeeklyChart(values: values);
                },
              )),

              const SizedBox(height: 24),

              // RECENT ACTIVITY
              const FadeSlide(index: 6, child: SectionHeader(title: 'RECENT ACTIVITY')),
              FadeSlide(index: 7, child: StreamBuilder<List<ActivityLog>>(
                stream: _supa.streamActivityLogs(limit: 10),
                builder: (context, snap) {
                  if (snap.hasError) return const ErrorBanner(message: 'Activity log unavailable');
                  if (!snap.hasData) return const ShimmerBlock(height: 100);
                  if (snap.data!.isEmpty) return const EmptyState(icon: Icons.history, title: 'No activity yet');

                  // Convert ActivityLog to ActivityItem
                  final items = snap.data!.map((log) {
                    return ActivityItem(
                      event: log.description ?? log.eventType,
                      type: _getActivityType(log.eventType),
                      whSaved: 0, // Will be calculated later
                      co2Mg: 0,
                      timestamp: log.createdAt,
                    );
                  }).toList();

                  return RecentActivity(items: items);
                },
              )),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _getActivityType(String eventType) {
    switch (eventType) {
      case 'lamp_on':
        return 'on';
      case 'lamp_off':
        return 'off';
      case 'motion_detected':
        return 'motion';
      case 'motion_cleared':
        return 'clear';
      case 'co2_alert':
        return 'alert';
      default:
        return 'other';
    }
  }
}
