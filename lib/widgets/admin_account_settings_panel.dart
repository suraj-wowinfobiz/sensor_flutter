import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/custom_theme_tokens.dart';
import '../providers/theme_provider.dart';
import '../shared/models/threshold_rule.dart';
import '../providers/database_provider.dart';
import '../screens/login_screen.dart';

enum _SettingsTab {
  profile,
  preferences,
  notifications,
  access,
  security,
  thresholds
}

class AdminAccountSettingsPanel extends StatefulWidget {
  final String roleLabel;
  final String userName;
  final String userEmail;

  const AdminAccountSettingsPanel({
    super.key,
    required this.roleLabel,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<AdminAccountSettingsPanel> createState() =>
      _AdminAccountSettingsPanelState();
}

class _AdminAccountSettingsPanelState extends State<AdminAccountSettingsPanel> {
  final TextEditingController _presetNameController =
      TextEditingController(text: 'My Preset');
  _SettingsTab _activeTab = _SettingsTab.profile;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _whatsAppNotifications = false;
  bool _pushNotifications = true;
  bool _criticalAlerts = true;
  bool _warningAlerts = true;
  bool _infoAlerts = false;
  bool _deviceUpdates = true;
  bool _systemNotifications = true;
  bool _dailyDigest = false;

  @override
  void dispose() {
    _presetNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardColor = Theme.of(context).cardColor;
    final titleColor =
        isLight ? const Color(0xFF102c42) : const Color(0xFFe8f1fc);
    final subColor =
        isLight ? const Color(0xFF4f6b82) : const Color(0xFF9db7d2);
    final headlineSize = width < 640 ? 34.0 : 44.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Profile',
              style: TextStyle(
                fontSize: headlineSize,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Manage your account settings and preferences',
              style: TextStyle(fontSize: 15, color: subColor),
            ),
            const SizedBox(height: 18),
            _buildTabBar(context),
            const SizedBox(height: 18),
            if (_activeTab == _SettingsTab.profile) _buildProfileTab(context),
            if (_activeTab == _SettingsTab.preferences)
              _buildPreferencesTab(context),
            if (_activeTab == _SettingsTab.notifications)
              _buildNotificationsTab(context),
            if (_activeTab == _SettingsTab.access) _buildAccessTab(context),
            if (_activeTab == _SettingsTab.security) _buildSecurityTab(context),
            if (_activeTab == _SettingsTab.thresholds)
              _buildThresholdsTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final tabs = [
      (_SettingsTab.profile, Icons.person_outline, 'Profile'),
      (_SettingsTab.preferences, Icons.palette_outlined, 'Preferences'),
      (_SettingsTab.notifications, Icons.notifications_none, 'Notifications'),
      (_SettingsTab.access, Icons.verified_user_outlined, 'Access'),
      (_SettingsTab.security, Icons.lock_outline, 'Security'),
      (_SettingsTab.thresholds, Icons.tune, 'Thresholds'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFFdbe5ea)
            : const Color(0xFF223d57),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((item) {
            final isActive = _activeTab == item.$1;
            return GestureDetector(
              onTap: () => setState(() => _activeTab = item.$1),
              child: Container(
                width: 180,
                margin: const EdgeInsets.all(3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).cardColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isActive
                      ? Border.all(color: Theme.of(context).dividerColor)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$2, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      item.$3,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 900;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final subColor =
        isLight ? const Color(0xFF4f6b82) : const Color(0xFF9db7d2);

    return _sectionContainer(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Information',
            style: TextStyle(fontSize: 34 * 0.6, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your personal information and avatar',
            style: TextStyle(color: subColor, fontSize: 15),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.userName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                width: isCompact ? double.infinity : 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          widget.userName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B78D1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            widget.roleLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.userEmail,
                      style: TextStyle(color: subColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Profile'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildInputGrid(context),
        ],
      ),
    );
  }

  Widget _buildAppearancePreferences(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final themeProvider = context.watch<ThemeProvider>();
    final subColor =
        isLight ? const Color(0xFF4f6b82) : const Color(0xFF9db7d2);
    final lightRatio = ThemeProvider.contrastRatio(
      themeProvider.textLight,
      themeProvider.backgroundLight,
    );
    final darkRatio = ThemeProvider.contrastRatio(
      themeProvider.textDark,
      themeProvider.backgroundDark,
    );
    final contrastOk = lightRatio >= 4.5 && darkRatio >= 4.5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: isLight ? const Color(0xFFF6FAFC) : const Color(0xFF203A54),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFE6EFF5)
                      : const Color(0xFF2B4A67),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appearance Preferences',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      themeProvider.isDarkMode
                          ? 'Dark mode enabled'
                          : 'Light mode enabled',
                      style: TextStyle(color: subColor),
                    ),
                  ],
                ),
              ),
              Switch(
                value: themeProvider.isDarkMode,
                onChanged: themeProvider.toggleTheme,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Theme Mode',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ThemeMode>(
                    value: themeProvider.themeMode,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(
                          value: ThemeMode.dark, child: Text('Dark')),
                      DropdownMenuItem(
                          value: ThemeMode.system, child: Text('System')),
                    ],
                    onChanged: (mode) {
                      if (mode != null) {
                        themeProvider.setThemeMode(mode);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Text Size (${themeProvider.textScale.toStringAsFixed(2)}x)',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Slider(
            value: themeProvider.textScale,
            min: 0.85,
            max: 1.4,
            divisions: 11,
            label: themeProvider.textScale.toStringAsFixed(2),
            onChanged: (v) => themeProvider.setTextScale(v),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Auto-fix Contrast',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Switch(
                value: themeProvider.autoContrastFix,
                onChanged: themeProvider.setAutoContrastFix,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Contrast (Light ${lightRatio.toStringAsFixed(2)}:1, Dark ${darkRatio.toStringAsFixed(2)}:1) ${contrastOk ? 'PASS' : 'LOW'}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: contrastOk
                  ? Theme.of(context)
                      .extension<CustomThemeTokens>()!
                      .statusNormal
                  : Theme.of(context)
                      .extension<CustomThemeTokens>()!
                      .statusWarning,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Theme Colors',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _presetButton(
                context,
                label: 'Default',
                selected: themeProvider.isUsingPreset(ThemePreset.defaultBlue),
                onTap: () => themeProvider.applyPreset(ThemePreset.defaultBlue),
              ),
              _presetButton(
                context,
                label: 'Ocean',
                selected: themeProvider.isUsingPreset(ThemePreset.ocean),
                onTap: () => themeProvider.applyPreset(ThemePreset.ocean),
              ),
              _presetButton(
                context,
                label: 'Forest',
                selected: themeProvider.isUsingPreset(ThemePreset.forest),
                onTap: () => themeProvider.applyPreset(ThemePreset.forest),
              ),
              _presetButton(
                context,
                label: 'Sunset',
                selected: themeProvider.isUsingPreset(ThemePreset.sunset),
                onTap: () => themeProvider.applyPreset(ThemePreset.sunset),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Advanced Colors',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _colorLine(
            context,
            label: 'Primary',
            light: themeProvider.primaryLight,
            dark: themeProvider.primaryDark,
            onSetLight: (c) => _updateThemeColors(
              themeProvider,
              primaryLight: c,
            ),
            onSetDark: (c) => _updateThemeColors(
              themeProvider,
              primaryDark: c,
            ),
          ),
          _colorLine(
            context,
            label: 'Background',
            light: themeProvider.backgroundLight,
            dark: themeProvider.backgroundDark,
            onSetLight: (c) => _updateThemeColors(
              themeProvider,
              backgroundLight: c,
            ),
            onSetDark: (c) => _updateThemeColors(
              themeProvider,
              backgroundDark: c,
            ),
          ),
          _colorLine(
            context,
            label: 'Surface',
            light: themeProvider.surfaceLight,
            dark: themeProvider.surfaceDark,
            onSetLight: (c) => _updateThemeColors(
              themeProvider,
              surfaceLight: c,
            ),
            onSetDark: (c) => _updateThemeColors(
              themeProvider,
              surfaceDark: c,
            ),
          ),
          _colorLine(
            context,
            label: 'Text',
            light: themeProvider.textLight,
            dark: themeProvider.textDark,
            onSetLight: (c) => _updateThemeColors(
              themeProvider,
              textLight: c,
            ),
            onSetDark: (c) => _updateThemeColors(
              themeProvider,
              textDark: c,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _colorDot(themeProvider.primaryLight),
              const SizedBox(width: 6),
              _colorDot(themeProvider.backgroundLight),
              const SizedBox(width: 6),
              _colorDot(themeProvider.textLight),
              const Spacer(),
              TextButton.icon(
                onPressed: themeProvider.resetCustomizations,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          const SizedBox(height: 12),
          const Text(
            'Preset Management',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _presetNameController,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Preset name',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  await themeProvider
                      .saveCurrentAsCustomPreset(_presetNameController.text);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preset saved')),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showExportDialog(context, themeProvider),
                icon: const Icon(Icons.ios_share, size: 16),
                label: const Text('Export JSON'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showImportDialog(context, themeProvider),
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Import JSON'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (themeProvider.customPresetNames.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: themeProvider.customPresetNames
                  .map(
                    (name) => InputChip(
                      label: Text(name),
                      onPressed: () => themeProvider.applyCustomPreset(name),
                      onDeleted: () => themeProvider.deleteCustomPreset(name),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _showExportDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) async {
    final jsonText =
        themeProvider.exportCurrentConfigJson(name: _presetNameController.text);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Theme JSON'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: SelectableText(jsonText),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: jsonText));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Theme JSON'),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: controller,
            minLines: 10,
            maxLines: 16,
            decoration: const InputDecoration(
              hintText: 'Paste exported theme JSON here',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await themeProvider.importConfigJson(controller.text);
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Theme imported' : 'Invalid theme JSON'),
                ),
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _updateThemeColors(
    ThemeProvider themeProvider, {
    Color? primaryLight,
    Color? primaryDark,
    Color? surfaceLight,
    Color? surfaceDark,
    Color? backgroundLight,
    Color? backgroundDark,
    Color? textLight,
    Color? textDark,
  }) {
    return themeProvider.setThemeColors(
      primaryLight: primaryLight ?? themeProvider.primaryLight,
      primaryDark: primaryDark ?? themeProvider.primaryDark,
      surfaceLight: surfaceLight ?? themeProvider.surfaceLight,
      surfaceDark: surfaceDark ?? themeProvider.surfaceDark,
      backgroundLight: backgroundLight ?? themeProvider.backgroundLight,
      backgroundDark: backgroundDark ?? themeProvider.backgroundDark,
      textLight: textLight ?? themeProvider.textLight,
      textDark: textDark ?? themeProvider.textDark,
    );
  }

  Widget _colorLine(
    BuildContext context, {
    required String label,
    required Color light,
    required Color dark,
    required ValueChanged<Color> onSetLight,
    required ValueChanged<Color> onSetDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 330;
          final buttons = Row(
            children: [
              Expanded(
                child: _editColorButton(
                  context,
                  caption: 'Light',
                  color: light,
                  onPick: onSetLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _editColorButton(
                  context,
                  caption: 'Dark',
                  color: dark,
                  onPick: onSetDark,
                ),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                buttons,
              ],
            );
          }
          return Row(
            children: [
              SizedBox(
                width: 84,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(child: buttons),
            ],
          );
        },
      ),
    );
  }

  Widget _editColorButton(
    BuildContext context, {
    required String caption,
    required Color color,
    required ValueChanged<Color> onPick,
  }) {
    return OutlinedButton(
      onPressed: () async {
        final selected = await _pickColorDialog(
          context,
          title: '$caption Color',
          initial: color,
        );
        if (selected != null) onPick(selected);
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Theme.of(context).dividerColor),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _colorDot(color),
          const SizedBox(width: 6),
          Text(caption),
        ],
      ),
    );
  }

  Future<Color?> _pickColorDialog(
    BuildContext context, {
    required String title,
    required Color initial,
  }) async {
    final argb = initial.value;
    var r = (argb >> 16) & 0xFF;
    var g = (argb >> 8) & 0xFF;
    var b = argb & 0xFF;

    return showDialog<Color>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final current = Color.fromARGB(255, r, g, b);
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 48,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: current,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.22),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _rgbSlider(
                      context,
                      label: 'R',
                      value: r,
                      onChanged: (v) => setDialogState(() => r = v),
                    ),
                    _rgbSlider(
                      context,
                      label: 'G',
                      value: g,
                      onChanged: (v) => setDialogState(() => g = v),
                    ),
                    _rgbSlider(
                      context,
                      label: 'B',
                      value: b,
                      onChanged: (v) => setDialogState(() => b = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(current),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _rgbSlider(
    BuildContext context, {
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 22,
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            label: '$value',
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }

  Widget _presetButton(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: selected ? scheme.primary : Theme.of(context).dividerColor,
          width: selected ? 1.4 : 1,
        ),
        backgroundColor: selected
            ? scheme.primary.withValues(alpha: 0.16)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            Icon(Icons.check_circle, size: 14, color: scheme.primary),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: selected ? scheme.primary : null,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorDot(Color color) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.18)),
      ),
    );
  }

  Widget _buildPreferencesTab(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final subColor =
        isLight ? const Color(0xFF4f6b82) : const Color(0xFF9db7d2);
    return _sectionContainer(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferences',
            style: TextStyle(fontSize: 34 * 0.6, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Customize app appearance and behavior',
            style: TextStyle(color: subColor, fontSize: 15),
          ),
          const SizedBox(height: 14),
          _buildAppearancePreferences(context),
        ],
      ),
    );
  }

  Widget _buildProfileLogoutFooter(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isLight ? const Color(0xFFF8EDED) : const Color(0xFF3A2327),
        border:
            Border.all(color: const Color(0xFFE54C4C).withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Session',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFFE54C4C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Logout from your account on this device.',
            style: TextStyle(
              color:
                  isLight ? const Color(0xFF37434C) : const Color(0xFFC5D5E3),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE54C4C),
              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputGrid(BuildContext context) {
    const fields = [
      ('Full Name', 'suraj.tiwari'),
      ('Email', 'suraj.tiwari@live.com'),
      ('Phone Number', '+1 (555) 000-0000'),
      ('Job Title', 'Senior Engineer'),
      ('Department', 'Engineering'),
      ('Timezone', 'UTC'),
    ];
    final isWide = MediaQuery.of(context).size.width > 900;
    return Column(
      children: [
        for (int i = 0; i < fields.length; i += isWide ? 2 : 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: _readOnlyField(
                    context,
                    label: fields[i].$1,
                    value: fields[i].$2,
                  ),
                ),
                if (isWide) const SizedBox(width: 12),
                if (isWide && i + 1 < fields.length)
                  Expanded(
                    child: _readOnlyField(
                      context,
                      label: fields[i + 1].$1,
                      value: fields[i + 1].$2,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _readOnlyField(BuildContext context,
      {required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFF6FAFC)
                : const Color(0xFF203a54),
          ),
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildNotificationsTab(BuildContext context) {
    return _sectionContainer(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Preferences',
            style: TextStyle(fontSize: 34 * 0.6, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage how you receive alerts and updates',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF4f6b82)
                  : const Color(0xFF9db7d2),
            ),
          ),
          const SizedBox(height: 14),
          _toggleTile(context,
              title: 'Email Notifications',
              subtitle: 'Receive alerts via email',
              value: _emailNotifications,
              onChanged: (v) => setState(() => _emailNotifications = v)),
          _toggleTile(context,
              title: 'SMS Notifications',
              subtitle: 'Receive alerts via text message',
              value: _smsNotifications,
              onChanged: (v) => setState(() => _smsNotifications = v)),
          _toggleTile(context,
              title: 'WhatsApp Notifications',
              subtitle: 'Receive alerts via WhatsApp',
              value: _whatsAppNotifications,
              onChanged: (v) => setState(() => _whatsAppNotifications = v)),
          _toggleTile(context,
              title: 'Push Notifications',
              subtitle: 'Receive in-app push notifications',
              value: _pushNotifications,
              onChanged: (v) => setState(() => _pushNotifications = v)),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _toggleTile(context,
              title: 'Critical Alerts',
              subtitle: 'High priority alerts requiring immediate attention',
              value: _criticalAlerts,
              onChanged: (v) => setState(() => _criticalAlerts = v)),
          _toggleTile(context,
              title: 'Warning Alerts',
              subtitle: 'Medium priority alerts for potential issues',
              value: _warningAlerts,
              onChanged: (v) => setState(() => _warningAlerts = v)),
          _toggleTile(context,
              title: 'Info Alerts',
              subtitle: 'Low priority informational updates',
              value: _infoAlerts,
              onChanged: (v) => setState(() => _infoAlerts = v)),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _toggleTile(context,
              title: 'Device Updates',
              subtitle: 'Get notified about device status changes',
              value: _deviceUpdates,
              onChanged: (v) => setState(() => _deviceUpdates = v)),
          _toggleTile(context,
              title: 'System Notifications',
              subtitle: 'Receive system maintenance and update notifications',
              value: _systemNotifications,
              onChanged: (v) => setState(() => _systemNotifications = v)),
          _toggleTile(context,
              title: 'Daily Digest',
              subtitle: 'Receive a daily summary of sensor activity',
              value: _dailyDigest,
              onChanged: (v) => setState(() => _dailyDigest = v)),
        ],
      ),
    );
  }

  Widget _toggleTile(BuildContext context,
      {required String title,
      required String subtitle,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF4f6b82)
                        : const Color(0xFF9db7d2),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildAccessTab(BuildContext context) {
    return _sectionContainer(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Access Control',
            style: TextStyle(fontSize: 34 * 0.6, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'View your access permissions across the organization hierarchy',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF4f6b82)
                  : const Color(0xFF9db7d2),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF27a36a).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF27a36a).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified, color: Color(0xFF27a36a)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Full Organization Access',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'You currently have unrestricted access to sites, zones, and sensors.',
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final statWidth = constraints.maxWidth < 460
                        ? constraints.maxWidth
                        : 220.0;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: statWidth,
                          child: const _AccessStatCard(
                              label: 'All Sites', value: '1'),
                        ),
                        SizedBox(
                          width: statWidth,
                          child: const _AccessStatCard(
                              label: 'All Zones', value: '1'),
                        ),
                        SizedBox(
                          width: statWidth,
                          child: const _AccessStatCard(
                              label: 'All Sensors', value: '214'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1100;
    return _sectionContainer(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Change Password',
            style: TextStyle(fontSize: 34 * 0.6, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const _LabeledPasswordField(label: 'Current Password'),
          const SizedBox(height: 10),
          const _LabeledPasswordField(label: 'New Password'),
          const SizedBox(height: 10),
          const _LabeledPasswordField(label: 'Confirm New Password'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.key),
              label: const Text('Update Password'),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Two-Factor Authentication',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _actionTile(context,
              title: 'Authentication App',
              subtitle:
                  'Use an authenticator app to generate verification codes'),
          _actionTile(context,
              title: 'SMS Authentication',
              subtitle: 'Receive verification codes via text message'),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFE54C4C).withValues(alpha: 0.08),
              border: Border.all(
                  color: const Color(0xFFE54C4C).withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Danger Zone',
                  style: TextStyle(
                    color: Color(0xFFE54C4C),
                    fontWeight: FontWeight.w800,
                    fontSize: 20 * 0.9,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Permanently delete your account and associated data.',
                ),
                const SizedBox(height: 10),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE54C4C),
                  ),
                  onPressed: () {},
                  child: const Text('Delete Account'),
                ),
              ],
            ),
          ),
          if (isMobile) ...[
            const SizedBox(height: 18),
            _buildMobileLogoutSection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileLogoutSection(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isLight ? const Color(0xFFF8EDED) : const Color(0xFF3A2327),
        border:
            Border.all(color: const Color(0xFFE54C4C).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFFE54C4C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign out from this device.',
            style: TextStyle(
              color:
                  isLight ? const Color(0xFF37434C) : const Color(0xFFC5D5E3),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, color: Color(0xFFE54C4C)),
              label: const Text(
                'Logout',
                style: TextStyle(color: Color(0xFFE54C4C)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdsTab(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final subColor =
        isLight ? const Color(0xFF4f6b82) : const Color(0xFF9db7d2);
    final db = context.watch<DatabaseProvider>();
    final thresholds = db.sortedThresholdRules;

    return _sectionContainer(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 520;
              if (!isNarrow) {
                return Row(
                  children: [
                    const Text(
                      'Threshold Configuration',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => _showThresholdDialog(context, db: db),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Threshold'),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Threshold Configuration',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showThresholdDialog(context, db: db),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Threshold'),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Add multiple thresholds with custom sound/color and choose where they appear.',
            style: TextStyle(color: subColor),
          ),
          const SizedBox(height: 14),
          if (thresholds.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFEAF2F6),
                border: Border.all(color: const Color(0xFFD0DEE6)),
              ),
              child: const Text('No thresholds configured. Add one to begin.'),
            )
          else
            ...thresholds.map(
              (rule) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: rule.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          '${rule.label} (${rule.value.toStringAsFixed(1)}°)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          rule.sound,
                          style: TextStyle(
                            color: subColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showThresholdDialog(context,
                              db: db, existing: rule),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit threshold',
                        ),
                        IconButton(
                          onPressed: () => db.deleteThresholdRule(rule.id),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: 'Delete threshold',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: rule.graphTargets
                          .map(
                            (target) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                color: rule.color.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: rule.color.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                target.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: rule.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showThresholdDialog(
    BuildContext context, {
    required DatabaseProvider db,
    ThresholdRule? existing,
  }) {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final valueController = TextEditingController(
      text: existing != null ? existing.value.toStringAsFixed(1) : '',
    );
    final soundController = TextEditingController(text: existing?.sound ?? '');
    final colorHexController = TextEditingController(
      text: existing != null ? _toHexColor(existing.color) : '#4C8BF5',
    );
    final selectedTargets = <ThresholdGraphTarget>{
      ...(existing?.graphTargets ?? const <ThresholdGraphTarget>{}),
    };
    if (selectedTargets.isEmpty) {
      selectedTargets.add(ThresholdGraphTarget.analyticsMain);
    }

    final presetColors = <String, Color>{
      'Amber': const Color(0xFFD39A00),
      'Red': const Color(0xFFE54C4C),
      'Purple': const Color(0xFF7A4FD6),
      'Blue': const Color(0xFF4C8BF5),
      'Green': const Color(0xFF17A56F),
      'Orange': const Color(0xFFF08A24),
      'Custom': _parseHexColor(colorHexController.text) ??
          (existing?.color ?? const Color(0xFF4C8BF5)),
    };

    String selectedColorName = existing == null
        ? 'Blue'
        : (presetColors.entries
            .firstWhere(
              (entry) => entry.value.value == existing.color.value,
              orElse: () => const MapEntry('Custom', Color(0xFF4C8BF5)),
            )
            .key);

    Color selectedColor = selectedColorName == 'Custom'
        ? (existing?.color ?? const Color(0xFF4C8BF5))
        : presetColors[selectedColorName]!;
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isLight = Theme.of(context).brightness == Brightness.light;
            InputDecoration themedInput({
              required String labelText,
              String? hintText,
            }) {
              return InputDecoration(
                labelText: labelText,
                hintText: hintText,
                labelStyle: TextStyle(
                  color: isLight
                      ? const Color(0xFF3D5C6E)
                      : const Color(0xFFB9CDDD),
                ),
                hintStyle: TextStyle(
                  color: isLight
                      ? const Color(0xFF7A96A8)
                      : const Color(0xFF89A2B6),
                ),
                filled: true,
                fillColor:
                    isLight ? const Color(0xFFF8FBFD) : const Color(0xFF2A465A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isLight
                        ? const Color(0xFFC7D9E4)
                        : const Color(0xFF4A6B80),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isLight
                        ? const Color(0xFF7FA8BF)
                        : const Color(0xFF6E96AE),
                  ),
                ),
              );
            }

            return AlertDialog(
              backgroundColor:
                  isLight ? const Color(0xFFF1F7FB) : const Color(0xFF243E52),
              title:
                  Text(existing == null ? 'Add Threshold' : 'Edit Threshold'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: labelController,
                        style: TextStyle(
                          color: isLight
                              ? const Color(0xFF1D3949)
                              : const Color(0xFFE7F3FF),
                        ),
                        decoration: themedInput(
                          labelText: 'Label',
                          hintText: 'Example: Warning',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: valueController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          color: isLight
                              ? const Color(0xFF1D3949)
                              : const Color(0xFFE7F3FF),
                        ),
                        decoration:
                            themedInput(labelText: 'Threshold Value (°)'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: soundController,
                        style: TextStyle(
                          color: isLight
                              ? const Color(0xFF1D3949)
                              : const Color(0xFFE7F3FF),
                        ),
                        decoration: themedInput(
                          labelText: 'Alert Sound',
                          hintText: 'Example: Siren',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedColorName,
                        dropdownColor: isLight
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFF2A465A),
                        style: TextStyle(
                          color: isLight
                              ? const Color(0xFF1D3949)
                              : const Color(0xFFE7F3FF),
                        ),
                        decoration: themedInput(labelText: 'Threshold Color'),
                        items: presetColors.keys
                            .map(
                              (name) => DropdownMenuItem<String>(
                                value: name,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: presetColors[name],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(name),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedColorName = value;
                            if (value != 'Custom') {
                              selectedColor = presetColors[value]!;
                              colorHexController.text =
                                  _toHexColor(selectedColor);
                            }
                          });
                        },
                      ),
                      if (selectedColorName == 'Custom') ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: colorHexController,
                          style: TextStyle(
                            color: isLight
                                ? const Color(0xFF1D3949)
                                : const Color(0xFFE7F3FF),
                          ),
                          decoration: themedInput(
                            labelText: 'Custom Hex Color',
                            hintText: '#RRGGBB',
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              final parsed = _parseHexColor(value);
                              if (parsed != null) selectedColor = parsed;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Show This Threshold On',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isLight
                              ? const Color(0xFF1F3948)
                              : const Color(0xFFDDEBFA),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...ThresholdGraphTarget.values.map(
                        (target) => CheckboxListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          activeColor: isLight
                              ? const Color(0xFF2E5E77)
                              : const Color(0xFF6E96AE),
                          checkColor: isLight
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFF10202C),
                          value: selectedTargets.contains(target),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            target.label,
                            style: TextStyle(
                              color: isLight
                                  ? const Color(0xFF2B4A5C)
                                  : const Color(0xFFBCD0E0),
                            ),
                          ),
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selectedTargets.add(target);
                              } else {
                                selectedTargets.remove(target);
                              }
                            });
                          },
                        ),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          errorText!,
                          style: const TextStyle(color: Color(0xFFB33A3A)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final label = labelController.text.trim();
                    final value = double.tryParse(valueController.text.trim());
                    final sound = soundController.text.trim();
                    final resolvedColor = selectedColorName == 'Custom'
                        ? _parseHexColor(colorHexController.text)
                        : selectedColor;

                    if (label.isEmpty) {
                      setDialogState(() => errorText = 'Label is required.');
                      return;
                    }
                    if (value == null) {
                      setDialogState(
                          () => errorText = 'Value must be numeric.');
                      return;
                    }
                    if (sound.isEmpty) {
                      setDialogState(() => errorText = 'Sound is required.');
                      return;
                    }
                    if (resolvedColor == null) {
                      setDialogState(() => errorText = 'Invalid color hex.');
                      return;
                    }
                    if (selectedTargets.isEmpty) {
                      setDialogState(
                        () => errorText = 'Choose at least one graph target.',
                      );
                      return;
                    }

                    db.saveThresholdRule(
                      ThresholdRule(
                        id: existing?.id ?? db.nextThresholdRuleId(),
                        label: label,
                        value: value,
                        sound: sound,
                        color: resolvedColor,
                        graphTargets: Set<ThresholdGraphTarget>.from(
                          selectedTargets,
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color? _parseHexColor(String input) {
    final cleaned = input.trim().replaceAll('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }

  String _toHexColor(Color color) {
    final rgb = color.value & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Widget _actionTile(BuildContext context,
      {required String title, required String subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF4f6b82)
                        : const Color(0xFF9db7d2),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(onPressed: () {}, child: const Text('Enable')),
        ],
      ),
    );
  }

  Widget _sectionContainer(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }
}

class _AccessStatCard extends StatelessWidget {
  final String label;
  final String value;

  const _AccessStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF27a36a).withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
                fontSize: 32 * 0.9, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

class _LabeledPasswordField extends StatelessWidget {
  final String label;

  const _LabeledPasswordField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFF6FAFC)
                : const Color(0xFF203a54),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
