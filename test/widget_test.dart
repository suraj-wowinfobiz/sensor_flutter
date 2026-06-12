import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wowguardian/main.dart';
import 'package:wowguardian/core/auth/global_login_screen.dart';
import 'package:wowguardian/main_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app opens operational landing page without a session',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(MainPage), findsOneWidget);
    expect(find.text('Smart Sensors for Safer Construction Sites'),
        findsOneWidget);
  });

  testWidgets('landing login button opens login screen without layout errors',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Request Demo').first);
    await tester.pumpAndSettle();

    expect(find.byType(GlobalLoginScreen), findsOneWidget);
    expect(find.text('Log in to your account'), findsOneWidget);
  });

  testWidgets('user login stays responsive without overflow on tighter screens',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 780));
    await tester.pumpWidget(
      const MaterialApp(
        home: GlobalLoginScreen(
          initialRole: AppLoginRole.user,
          allowRoleSelection: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Project Alpha'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
