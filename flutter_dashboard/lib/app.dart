import 'package:flutter/material.dart';

import 'pages/home/home_page.dart';
import 'pages/statistics/statistics_page.dart';
import 'pages/carbon/carbon_page.dart';
import 'pages/settings/settings_page.dart';
import 'services/settings_service.dart';

class App extends StatefulWidget {
  final SettingsService settingsService;

  const App({super.key, required this.settingsService});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const StatisticsPage(),
      const CarbonPage(),
      SettingsPage(service: widget.settingsService),
    ];

    return Scaffold(
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
    );
  }
}
