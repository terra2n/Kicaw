import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dashboard_eco2/app.dart';
import 'package:dashboard_eco2/services/settings_service.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);

    await tester.pumpWidget(App(settingsService: settings));
    expect(find.byType(App), findsOneWidget);
  });
}
