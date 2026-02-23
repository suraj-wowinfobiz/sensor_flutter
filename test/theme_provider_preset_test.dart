import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:industrial_tilt_admin/providers/theme_provider.dart';

Future<void> _drainAsync() async {
  await Future<void>.delayed(const Duration(milliseconds: 5));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider preset management', () {
    test('exports and imports JSON roundtrip', () async {
      SharedPreferences.setMockInitialValues({});

      final provider = ThemeProvider();
      await _drainAsync();

      await provider.setThemeMode(ThemeMode.dark);
      await provider.setTextScale(1.2);
      await provider.applyPreset(ThemePreset.forest);

      final jsonText = provider.exportCurrentConfigJson(name: 'Forest Custom');

      await provider.resetCustomizations();
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.textScale, closeTo(0.92, 0.001));

      final imported = await provider.importConfigJson(jsonText);
      expect(imported, isTrue);
      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.textScale, closeTo(1.2, 0.001));
    });

    test('saves, applies and deletes named custom presets', () async {
      SharedPreferences.setMockInitialValues({});

      final provider = ThemeProvider();
      await _drainAsync();

      await provider.applyPreset(ThemePreset.ocean);
      await provider.saveCurrentAsCustomPreset('Ocean One');
      expect(provider.customPresetNames, contains('Ocean One'));

      await provider.applyPreset(ThemePreset.sunset);
      final switchedColor = provider.primaryLight;

      final applied = await provider.applyCustomPreset('Ocean One');
      expect(applied, isTrue);
      expect(provider.primaryLight, isNot(equals(switchedColor)));

      await provider.deleteCustomPreset('Ocean One');
      expect(provider.customPresetNames, isNot(contains('Ocean One')));
    });

    test('auto-fix contrast keeps text readable against background', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();
      await _drainAsync();

      await provider.setAutoContrastFix(true);
      await provider.setThemeColors(
        primaryLight: const Color(0xFF1f7bcf),
        primaryDark: const Color(0xFF3290df),
        surfaceLight: const Color(0xFFFFFFFF),
        surfaceDark: const Color(0xFF1d3852),
        backgroundLight: const Color(0xFFFFFFFF),
        backgroundDark: const Color(0xFF000000),
        textLight: const Color(0xFFFFFFFF), // intentionally poor
        textDark: const Color(0xFF000000), // intentionally poor
      );

      expect(
        provider.hasAccessibleContrast(
          foreground: provider.textLight,
          background: provider.backgroundLight,
        ),
        isTrue,
      );
      expect(
        provider.hasAccessibleContrast(
          foreground: provider.textDark,
          background: provider.backgroundDark,
        ),
        isTrue,
      );
    });
  });
}
