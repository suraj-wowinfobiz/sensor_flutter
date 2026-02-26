import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/custom_theme_tokens.dart';

enum ThemePreset { defaultBlue, ocean, forest, sunset }

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  static const String _textScaleKey = 'textScale';
  static const String _primaryLightKey = 'primaryLight';
  static const String _primaryDarkKey = 'primaryDark';
  static const String _surfaceLightKey = 'surfaceLight';
  static const String _surfaceDarkKey = 'surfaceDark';
  static const String _bgLightKey = 'bgLight';
  static const String _bgDarkKey = 'bgDark';
  static const String _textLightKey = 'textLight';
  static const String _textDarkKey = 'textDark';
  static const String _customPresetsKey = 'customThemePresets';
  static const String _autoContrastFixKey = 'autoContrastFix';
  static const int _defaultPrimaryLight = 0xFF1f7bcf;
  static const int _defaultPrimaryDark = 0xFF3290df;
  static const int _defaultSurfaceLight = 0xFFFFFFFF;
  static const int _defaultSurfaceDark = 0xFF1d3852;
  static const int _defaultBgLight = 0xFFf4f9ff;
  static const int _defaultBgDark = 0xFF0e1b2a;
  static const int _defaultTextLight = 0xFF0a1a2a;
  static const int _defaultTextDark = 0xFFe8f1fc;

  ThemeMode _themeMode = ThemeMode.light;
  double _textScale = 0.92;
  Color _primaryLight = const Color(_defaultPrimaryLight);
  Color _primaryDark = const Color(_defaultPrimaryDark);
  Color _surfaceLight = const Color(_defaultSurfaceLight);
  Color _surfaceDark = const Color(_defaultSurfaceDark);
  Color _backgroundLight = const Color(_defaultBgLight);
  Color _backgroundDark = const Color(_defaultBgDark);
  Color _textLight = const Color(_defaultTextLight);
  Color _textDark = const Color(_defaultTextDark);
  ThemePreset? _selectedPreset;
  List<String> _customPresetNames = [];
  bool _autoContrastFix = true;

  ThemeProvider() {
    _loadTheme();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  double get textScale => _textScale;

  Color get primaryLight => _primaryLight;
  Color get primaryDark => _primaryDark;
  Color get surfaceLight => _surfaceLight;
  Color get surfaceDark => _surfaceDark;
  Color get backgroundLight => _backgroundLight;
  Color get backgroundDark => _backgroundDark;
  Color get textLight => _textLight;
  Color get textDark => _textDark;
  UnmodifiableListView<String> get customPresetNames =>
      UnmodifiableListView(_customPresetNames);
  bool get autoContrastFix => _autoContrastFix;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = _decodeThemeMode(
      prefs.getString(_themeModeKey) ?? ThemeMode.light.name,
    );
    _textScale = prefs.getDouble(_textScaleKey) ?? 0.92;
    _primaryLight =
        Color(prefs.getInt(_primaryLightKey) ?? _defaultPrimaryLight);
    _primaryDark = Color(prefs.getInt(_primaryDarkKey) ?? _defaultPrimaryDark);
    _surfaceLight =
        Color(prefs.getInt(_surfaceLightKey) ?? _defaultSurfaceLight);
    _surfaceDark = Color(prefs.getInt(_surfaceDarkKey) ?? _defaultSurfaceDark);
    _backgroundLight = Color(prefs.getInt(_bgLightKey) ?? _defaultBgLight);
    _backgroundDark = Color(prefs.getInt(_bgDarkKey) ?? _defaultBgDark);
    _textLight = Color(prefs.getInt(_textLightKey) ?? _defaultTextLight);
    _textDark = Color(prefs.getInt(_textDarkKey) ?? _defaultTextDark);
    _selectedPreset = _detectPresetFromColors();
    _customPresetNames = prefs.getStringList(_customPresetsKey) ?? [];
    _autoContrastFix = prefs.getBool(_autoContrastFixKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme([bool? isDark]) async {
    final nextMode = isDark == null
        ? (isDarkMode ? ThemeMode.light : ThemeMode.dark)
        : (isDark ? ThemeMode.dark : ThemeMode.light);
    await setThemeMode(nextMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeMode.name);
    notifyListeners();
  }

  Future<void> setTextScale(double scale) async {
    final clamped = scale.clamp(0.85, 1.4);
    if (_textScale == clamped) return;
    _textScale = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, _textScale);
    notifyListeners();
  }

  Future<void> setPrimaryColor(Color light, Color dark) async {
    _primaryLight = light;
    _primaryDark = dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_primaryLightKey, _primaryLight.value);
    await prefs.setInt(_primaryDarkKey, _primaryDark.value);
    notifyListeners();
  }

  Future<void> setSurfaceColor(Color light, Color dark) async {
    _surfaceLight = light;
    _surfaceDark = dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_surfaceLightKey, _surfaceLight.value);
    await prefs.setInt(_surfaceDarkKey, _surfaceDark.value);
    notifyListeners();
  }

  Future<void> setBackgroundColor(Color light, Color dark) async {
    _backgroundLight = light;
    _backgroundDark = dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bgLightKey, _backgroundLight.value);
    await prefs.setInt(_bgDarkKey, _backgroundDark.value);
    notifyListeners();
  }

  Future<void> setTextColor(Color light, Color dark) async {
    _textLight = light;
    _textDark = dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_textLightKey, _textLight.value);
    await prefs.setInt(_textDarkKey, _textDark.value);
    notifyListeners();
  }

  Future<void> setAutoContrastFix(bool value) async {
    if (_autoContrastFix == value) return;
    _autoContrastFix = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoContrastFixKey, _autoContrastFix);
    notifyListeners();
  }

  ThemeData buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final primary = isLight ? _primaryLight : _primaryDark;
    final secondary =
        isLight ? const Color(0xFFe68a2e) : const Color(0xFFd97e2a);
    final surface = isLight ? _surfaceLight : _surfaceDark;
    final background = isLight ? _backgroundLight : _backgroundDark;
    final onSurface = isLight ? _textLight : _textDark;
    final error = isLight ? const Color(0xFFd64545) : const Color(0xFFcc4a4a);

    final base = isLight ? ThemeData.light() : ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme:
          (isLight ? const ColorScheme.light() : const ColorScheme.dark())
              .copyWith(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onSurface: onSurface,
      ),
      cardColor: surface,
      dividerColor: isLight ? const Color(0xFFd9e6f5) : const Color(0xFF315a7a),
      extensions: [
        isLight ? CustomThemeTokens.light : CustomThemeTokens.dark,
      ],
    );
  }

  Future<void> setThemeColors({
    required Color primaryLight,
    required Color primaryDark,
    required Color surfaceLight,
    required Color surfaceDark,
    required Color backgroundLight,
    required Color backgroundDark,
    required Color textLight,
    required Color textDark,
  }) async {
    final effectiveTextLight = _autoContrastFix
        ? _ensureReadableText(
            preferred: textLight,
            background: backgroundLight,
            surface: surfaceLight,
          )
        : textLight;
    final effectiveTextDark = _autoContrastFix
        ? _ensureReadableText(
            preferred: textDark,
            background: backgroundDark,
            surface: surfaceDark,
          )
        : textDark;

    _primaryLight = primaryLight;
    _primaryDark = primaryDark;
    _surfaceLight = surfaceLight;
    _surfaceDark = surfaceDark;
    _backgroundLight = backgroundLight;
    _backgroundDark = backgroundDark;
    _textLight = effectiveTextLight;
    _textDark = effectiveTextDark;
    _selectedPreset = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_primaryLightKey, _primaryLight.value);
    await prefs.setInt(_primaryDarkKey, _primaryDark.value);
    await prefs.setInt(_surfaceLightKey, _surfaceLight.value);
    await prefs.setInt(_surfaceDarkKey, _surfaceDark.value);
    await prefs.setInt(_bgLightKey, _backgroundLight.value);
    await prefs.setInt(_bgDarkKey, _backgroundDark.value);
    await prefs.setInt(_textLightKey, _textLight.value);
    await prefs.setInt(_textDarkKey, _textDark.value);
    notifyListeners();
  }

  Future<void> applyPreset(ThemePreset preset) async {
    final colors = _presetColors(preset);
    await setThemeColors(
      primaryLight: colors.primaryLight,
      primaryDark: colors.primaryDark,
      surfaceLight: colors.surfaceLight,
      surfaceDark: colors.surfaceDark,
      backgroundLight: colors.backgroundLight,
      backgroundDark: colors.backgroundDark,
      textLight: colors.textLight,
      textDark: colors.textDark,
    );
    _selectedPreset = preset;
    notifyListeners();
  }

  bool isUsingPreset(ThemePreset preset) {
    if (_selectedPreset == preset) return true;
    final colors = _presetColors(preset);
    return _primaryLight.value == colors.primaryLight.value &&
        _primaryDark.value == colors.primaryDark.value &&
        _surfaceLight.value == colors.surfaceLight.value &&
        _surfaceDark.value == colors.surfaceDark.value &&
        _backgroundLight.value == colors.backgroundLight.value &&
        _backgroundDark.value == colors.backgroundDark.value &&
        _textLight.value == colors.textLight.value &&
        _textDark.value == colors.textDark.value;
  }

  ThemePreset? _detectPresetFromColors() {
    for (final preset in ThemePreset.values) {
      if (isUsingPreset(preset)) {
        return preset;
      }
    }
    return null;
  }

  _PresetColors _presetColors(ThemePreset preset) {
    switch (preset) {
      case ThemePreset.defaultBlue:
        return const _PresetColors(
          primaryLight: Color(_defaultPrimaryLight),
          primaryDark: Color(_defaultPrimaryDark),
          surfaceLight: Color(_defaultSurfaceLight),
          surfaceDark: Color(_defaultSurfaceDark),
          backgroundLight: Color(_defaultBgLight),
          backgroundDark: Color(_defaultBgDark),
          textLight: Color(_defaultTextLight),
          textDark: Color(_defaultTextDark),
        );
      case ThemePreset.ocean:
        return const _PresetColors(
          primaryLight: Color(0xFF0f729c),
          primaryDark: Color(0xFF3EA7D8),
          surfaceLight: Color(0xFFFAFDFF),
          surfaceDark: Color(0xFF1A364A),
          backgroundLight: Color(0xFFEFF8FD),
          backgroundDark: Color(0xFF0B1E2A),
          textLight: Color(0xFF0C2230),
          textDark: Color(0xFFE3F2FB),
        );
      case ThemePreset.forest:
        return const _PresetColors(
          primaryLight: Color(0xFF2F8A57),
          primaryDark: Color(0xFF53B67B),
          surfaceLight: Color(0xFFF9FCF9),
          surfaceDark: Color(0xFF243A2E),
          backgroundLight: Color(0xFFEEF7F0),
          backgroundDark: Color(0xFF16241D),
          textLight: Color(0xFF1A2D22),
          textDark: Color(0xFFE5F2EA),
        );
      case ThemePreset.sunset:
        return const _PresetColors(
          primaryLight: Color(0xFFCF5A1F),
          primaryDark: Color(0xFFEF8A4F),
          surfaceLight: Color(0xFFFFFBF8),
          surfaceDark: Color(0xFF3B2B26),
          backgroundLight: Color(0xFFFFF3EC),
          backgroundDark: Color(0xFF231814),
          textLight: Color(0xFF2F1C15),
          textDark: Color(0xFFFFEDE4),
        );
    }
  }

  Future<void> resetCustomizations() async {
    await applyPreset(ThemePreset.defaultBlue);
    await setTextScale(0.92);
    await setThemeMode(ThemeMode.light);
  }

  String exportCurrentConfigJson({String? name}) {
    final payload = <String, dynamic>{
      'version': 1,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      'themeMode': _themeMode.name,
      'textScale': _textScale,
      'autoContrastFix': _autoContrastFix,
      'primaryLight': _primaryLight.value,
      'primaryDark': _primaryDark.value,
      'surfaceLight': _surfaceLight.value,
      'surfaceDark': _surfaceDark.value,
      'backgroundLight': _backgroundLight.value,
      'backgroundDark': _backgroundDark.value,
      'textLight': _textLight.value,
      'textDark': _textDark.value,
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<bool> importConfigJson(String raw) async {
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false;

      final mode = _decodeThemeMode(
        (decoded['themeMode'] as String?) ?? ThemeMode.light.name,
      );
      final scale = (decoded['textScale'] as num?)?.toDouble() ?? 0.92;
      final autoFix = (decoded['autoContrastFix'] as bool?) ?? _autoContrastFix;

      final primaryLight = _parseColor(decoded['primaryLight'], _primaryLight);
      final primaryDark = _parseColor(decoded['primaryDark'], _primaryDark);
      final surfaceLight = _parseColor(decoded['surfaceLight'], _surfaceLight);
      final surfaceDark = _parseColor(decoded['surfaceDark'], _surfaceDark);
      final bgLight = _parseColor(decoded['backgroundLight'], _backgroundLight);
      final bgDark = _parseColor(decoded['backgroundDark'], _backgroundDark);
      final textLight = _parseColor(decoded['textLight'], _textLight);
      final textDark = _parseColor(decoded['textDark'], _textDark);

      await setThemeColors(
        primaryLight: primaryLight,
        primaryDark: primaryDark,
        surfaceLight: surfaceLight,
        surfaceDark: surfaceDark,
        backgroundLight: bgLight,
        backgroundDark: bgDark,
        textLight: textLight,
        textDark: textDark,
      );
      await setAutoContrastFix(autoFix);
      await setTextScale(scale);
      await setThemeMode(mode);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveCurrentAsCustomPreset(String name) async {
    final safe = name.trim().isEmpty ? 'Custom Preset' : name.trim();
    _customPresetNames = _customPresetNames.where((e) => e != safe).toList()
      ..insert(0, safe);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customPresetsKey, _customPresetNames);
    await prefs.setString(_presetStorageKey(safe), exportCurrentConfigJson());
    notifyListeners();
  }

  Future<bool> applyCustomPreset(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_presetStorageKey(name));
    if (raw == null) return false;
    return importConfigJson(raw);
  }

  Future<void> deleteCustomPreset(String name) async {
    _customPresetNames = _customPresetNames.where((e) => e != name).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customPresetsKey, _customPresetNames);
    await prefs.remove(_presetStorageKey(name));
    notifyListeners();
  }

  String _presetStorageKey(String name) => 'customThemePreset:$name';

  Color _parseColor(dynamic raw, Color fallback) {
    if (raw is int) return Color(raw);
    if (raw is String) {
      final text = raw.trim();
      if (text.startsWith('#')) {
        final hex = text.substring(1);
        final withAlpha = hex.length == 6 ? 'FF$hex' : hex;
        final value = int.tryParse(withAlpha, radix: 16);
        if (value != null) return Color(value);
      }
    }
    return fallback;
  }

  ThemeMode _decodeThemeMode(String raw) {
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  static double contrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final light = l1 > l2 ? l1 : l2;
    final dark = l1 > l2 ? l2 : l1;
    return (light + 0.05) / (dark + 0.05);
  }

  bool hasAccessibleContrast({
    required Color foreground,
    required Color background,
    double minRatio = 4.5,
  }) {
    return contrastRatio(foreground, background) >= minRatio;
  }

  Color _ensureReadableText({
    required Color preferred,
    required Color background,
    required Color surface,
  }) {
    final candidates = <Color>[
      preferred,
      const Color(0xFF000000),
      const Color(0xFFFFFFFF),
      const Color(_defaultTextLight),
      const Color(_defaultTextDark),
    ];

    Color best = preferred;
    double bestScore = -1;
    for (final c in candidates) {
      final scoreBg = contrastRatio(c, background);
      final scoreSurface = contrastRatio(c, surface);
      final score = scoreBg < scoreSurface ? scoreBg : scoreSurface;
      if (score > bestScore) {
        bestScore = score;
        best = c;
      }
    }
    return best;
  }
}

class _PresetColors {
  final Color primaryLight;
  final Color primaryDark;
  final Color surfaceLight;
  final Color surfaceDark;
  final Color backgroundLight;
  final Color backgroundDark;
  final Color textLight;
  final Color textDark;

  const _PresetColors({
    required this.primaryLight,
    required this.primaryDark,
    required this.surfaceLight,
    required this.surfaceDark,
    required this.backgroundLight,
    required this.backgroundDark,
    required this.textLight,
    required this.textDark,
  });
}
