import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_eco2/app.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: App()));
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
