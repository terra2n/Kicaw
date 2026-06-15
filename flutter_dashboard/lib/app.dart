import 'package:flutter/material.dart';

import 'pages/home/home_page.dart';
import 'pages/statistics/statistics_page.dart';
import 'pages/carbon/carbon_page.dart';
import 'pages/settings/settings_page.dart';
import 'services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class App extends StatefulWidget {
  final SettingsService? settingsService;

  const App({super.key, this.settingsService});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentIndex = 0;

  late final SettingsService _settings;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _settings = widget.settingsService ?? SettingsService(SharedPreferences.getInstance() as SharedPreferences);
    _pages = [
      HomePage(settingsService: _settings),
      const StatisticsPage(),
      const CarbonPage(),
      SettingsPage(settingsService: _settings),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
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
