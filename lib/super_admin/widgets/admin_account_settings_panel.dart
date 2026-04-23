import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/app_session.dart';
import '../api/users_api.dart';
import '../providers/theme_provider.dart';

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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _organizationIdController =
      TextEditingController();
  final TextEditingController _maxUsersAllowedController =
      TextEditingController();
  bool _notificationsEnabled = true;
  String? _profileUserId;
  bool _profileActive = true;
  bool _profileLoading = false;
  bool _profileSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName;
    _emailController.text = widget.userEmail;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _organizationIdController.dispose();
    _maxUsersAllowedController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileForm() async {
    setState(() => _profileLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('super_admin_principal_id')?.trim() ?? '';
      if (userId.isEmpty) {
        throw Exception('User id not found. Please login again.');
      }
      final data = await UsersApi.getUserById(userId);
      if (!mounted) return;
      _profileUserId = userId;
      _nameController.text = (data['name'] ?? widget.userName).toString();
      _emailController.text = (data['email'] ?? widget.userEmail).toString();
      _organizationIdController.text =
          (data['organizationId'] ?? data['organization_id'] ?? '').toString();
      _maxUsersAllowedController.text =
          (data['maxUsersAllowed'] ?? data['max_users_allowed'] ?? '0')
              .toString();
      _profileActive = (data['active'] ?? true) == true;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  Future<bool> _saveProfileForm() async {
    if (_profileUserId == null || _profileUserId!.isEmpty) return false;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final organizationId = _organizationIdController.text.trim();
    final maxUsersAllowed =
        int.tryParse(_maxUsersAllowedController.text.trim());
    if (name.isEmpty ||
        email.isEmpty ||
        organizationId.isEmpty ||
        maxUsersAllowed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fill name and email'),
        ),
      );
      return false;
    }
    if (currentPassword.isNotEmpty ||
        newPassword.isNotEmpty ||
        confirmPassword.isNotEmpty) {
      if (currentPassword.isEmpty ||
          newPassword.isEmpty ||
          confirmPassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fill all password fields')),
        );
        return false;
      }
      if (newPassword != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('New password and confirm password must match')),
        );
        return false;
      }
    }
    final resolvedPassword =
        newPassword.isNotEmpty ? newPassword : currentPassword;

    setState(() => _profileSaving = true);
    try {
      await UsersApi.updateUserProfile(
        userId: _profileUserId!,
        name: name,
        email: email,
        password: resolvedPassword.isEmpty ? null : resolvedPassword,
        organizationId: organizationId,
        maxUsersAllowed: maxUsersAllowed,
        active: _profileActive,
      );
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      await _loadProfileForm();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
      return false;
    } finally {
      if (mounted) setState(() => _profileSaving = false);
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _editableField(
                dialogContext,
                label: 'currentPassword',
                controller: _currentPasswordController,
                obscureText: true,
              ),
              const SizedBox(height: 10),
              _editableField(
                dialogContext,
                label: 'newPassword',
                controller: _newPasswordController,
                obscureText: true,
              ),
              const SizedBox(height: 10),
              _editableField(
                dialogContext,
                label: 'confirmNewPassword',
                controller: _confirmPasswordController,
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _profileSaving
                ? null
                : () async {
                    final ok = await _saveProfileForm();
                    if (ok && dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
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
              'Settings',
              style: TextStyle(
                fontSize: headlineSize,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Manage preferences and notifications',
              style: TextStyle(fontSize: 15, color: subColor),
            ),
            const SizedBox(height: 16),
            _buildPreferencesTab(context),
            const SizedBox(height: 16),
            _buildNotificationsTab(context),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildProfileTab(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final titleColor =
        isLight ? const Color(0xFF1B313D) : const Color(0xFFE2EDF8);
    final valueColor =
        isLight ? const Color(0xFF365364) : const Color(0xFFBBD0E0);
    final resolvedName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : widget.userName;
    final resolvedEmail = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : widget.userEmail;

    return _sectionContainer(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Logged In Account',
            style: TextStyle(
              fontSize: 34 * 0.6,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Name: $resolvedName',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: valueColor),
          ),
          const SizedBox(height: 6),
          Text(
            'Login: $resolvedEmail',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: valueColor),
          ),
          const SizedBox(height: 6),
          Text(
            'Role: ${widget.roleLabel}',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: valueColor),
          ),
          Visibility(
            visible: false,
            maintainState: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                const Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 34 * 0.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInputGrid(context),
                const SizedBox(height: 14),
                const Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 34 * 0.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showChangePasswordDialog(context),
                    icon: const Icon(Icons.key),
                    label: const Text('Change Password'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _profileSaving
                        ? null
                        : () async {
                            await _saveProfileForm();
                          },
                    child: _profileSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update Profile'),
                  ),
                ),
                const SizedBox(height: 18),
                _buildProfileLogoutFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearancePreferences(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final themeProvider = context.watch<ThemeProvider>();
    final subColor =
        isLight ? const Color(0xFF4f6b82) : const Color(0xFF9db7d2);

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
          const Text(
            'Dark Mode',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('On'),
                  value: true,
                  groupValue: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.setThemeMode(ThemeMode.dark),
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Off'),
                  value: false,
                  groupValue: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.setThemeMode(ThemeMode.light),
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _showAdvancedThemeDialog(context, themeProvider),
              icon: const Icon(Icons.tune),
              label: const Text('Advanced'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAdvancedThemeDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advanced Theme Settings'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _colorLine(
                  context,
                  label: 'Primary',
                  light: themeProvider.primaryLight,
                  dark: themeProvider.primaryDark,
                  onSetLight: (c) =>
                      _updateThemeColors(themeProvider, primaryLight: c),
                  onSetDark: (c) =>
                      _updateThemeColors(themeProvider, primaryDark: c),
                ),
                _colorLine(
                  context,
                  label: 'Background',
                  light: themeProvider.backgroundLight,
                  dark: themeProvider.backgroundDark,
                  onSetLight: (c) =>
                      _updateThemeColors(themeProvider, backgroundLight: c),
                  onSetDark: (c) =>
                      _updateThemeColors(themeProvider, backgroundDark: c),
                ),
                _colorLine(
                  context,
                  label: 'Surface',
                  light: themeProvider.surfaceLight,
                  dark: themeProvider.surfaceDark,
                  onSetLight: (c) =>
                      _updateThemeColors(themeProvider, surfaceLight: c),
                  onSetDark: (c) =>
                      _updateThemeColors(themeProvider, surfaceDark: c),
                ),
                _colorLine(
                  context,
                  label: 'Text',
                  light: themeProvider.textLight,
                  dark: themeProvider.textDark,
                  onSetLight: (c) =>
                      _updateThemeColors(themeProvider, textLight: c),
                  onSetDark: (c) =>
                      _updateThemeColors(themeProvider, textDark: c),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: themeProvider.resetCustomizations,
            child: const Text('Reset'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
            'Theme mode, dark mode and text size',
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
              onPressed: () async {
                await AppSession.logoutToLanding(context);
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
    if (_profileLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final isWide = MediaQuery.of(context).size.width > 900;
    return Column(
      children: [
        for (int i = 0; i < _profileFields.length; i += isWide ? 2 : 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: _editableField(
                    context,
                    label: _profileFields[i].$1,
                    controller: _profileFields[i].$2,
                    obscureText: _profileFields[i].$1 == 'password',
                    keyboardType: _profileFields[i].$1 == 'maxUsersAllowed'
                        ? TextInputType.number
                        : TextInputType.text,
                  ),
                ),
                if (isWide) const SizedBox(width: 12),
                if (isWide && i + 1 < _profileFields.length)
                  Expanded(
                    child: _editableField(
                      context,
                      label: _profileFields[i + 1].$1,
                      controller: _profileFields[i + 1].$2,
                      obscureText: _profileFields[i + 1].$1 == 'password',
                      keyboardType:
                          _profileFields[i + 1].$1 == 'maxUsersAllowed'
                              ? TextInputType.number
                              : TextInputType.text,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  List<(String, TextEditingController)> get _profileFields => [
        ('name', _nameController),
        ('email', _emailController),
      ];

  Widget _editableField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFF6FAFC)
                : const Color(0xFF203a54),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
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
            'Notification',
            style: TextStyle(fontSize: 34 * 0.6, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          RadioListTile<bool>(
            title: const Text('On'),
            value: true,
            groupValue: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v ?? true),
          ),
          RadioListTile<bool>(
            title: const Text('Off'),
            value: false,
            groupValue: _notificationsEnabled,
            onChanged: (v) =>
                setState(() => _notificationsEnabled = v ?? false),
          ),
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
