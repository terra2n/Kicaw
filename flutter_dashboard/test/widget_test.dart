import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dashboard_eco2/app.dart';
import 'package:dashboard_eco2/services/settings_service.dart';
import 'package:dashboard_eco2/services/notification_service.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    final notif = NotificationService();

    await tester.pumpWidget(App(settingsService: settings, notificationService: notif));
    expect(find.byType(App), findsOneWidget);

    // Unmount App to trigger dispose() on all page states
    await tester.pumpWidget(Container());
  });
}
