import 'package:flutter/material.dart';
import 'pages/home/home_page.dart';
import 'pages/statistics/statistics_page.dart';
import 'pages/carbon/carbon_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/radar/radar_page.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

class App extends StatefulWidget {
  final SettingsService settingsService;
  final NotificationService notificationService;

  const App({super.key, required this.settingsService, required this.notificationService});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentIndex = 0;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.settingsService.themeMode;
  }

  void _toggleTheme() async {
    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await widget.settingsService.setThemeMode(next);
    setState(() => _themeMode = next);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const StatisticsPage(),
      const CarbonPage(),
      SettingsPage(
        service: widget.settingsService,
        notifService: widget.notificationService,
        onToggleTheme: _toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    ];

    return MaterialApp(
      title: 'Smart Room',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      routes: {
        '/radar': (context) => const RadarPage(),
      },
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Statistics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.eco_outlined),
              activeIcon: Icon(Icons.eco),
              label: 'Carbon',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
