import 'package:flutter_test/flutter_test.dart';
import 'package:industrial_tilt_admin/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('app starts', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Dashboard'), findsWidgets);
  });
}
