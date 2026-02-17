import 'package:flutter_test/flutter_test.dart';
import 'package:industrial_tilt_admin/main.dart';
import 'package:flutter/material.dart';
import 'package:industrial_tilt_admin/screens/login_screen.dart';

void main() {
  testWidgets('app shows login screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(DropdownButton<String>), findsOneWidget);
  });
}
