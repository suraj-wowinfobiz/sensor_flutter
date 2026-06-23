import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/app_session.dart';
import '../../../core/theme/ops_theme.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProfileForm();
      }
    });
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
      final userId = (prefs.getString('user_admin_principal_id') ??
                  prefs.getString('admin_principal_id') ??
                  prefs.getString('super_admin_principal_id'))
              ?.trim() ??
          '';
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
    return OpsPage(
      title: 'Settings',
      subtitle:
          'Profile, notification, security, theme, and workspace preferences for the super admin console',
      actions: [
        ElevatedButton.icon(
          onPressed: _profileSaving
              ? null
              : () async {
                  final saved = await _saveProfileForm();
                  if (!context.mounted || !saved) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings saved')),
                  );
                },
          icon: const Icon(Icons.save_outlined, size: 18),
          label: _profileSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Changes'),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final vertical = constraints.maxWidth < 980;
          final profile = OpsPanel(
            title: 'Profile Details',
            subtitle: 'Account identity and current console access',
            child: _buildProfileSummary(context),
          );
          final preferences = OpsPanel(
            title: 'Preferences',
            subtitle:
                'Theme mode, dark mode, text size, and workspace appearance',
            child: _buildPreferencesContent(context),
          );
          final security = OpsPanel(
            title: 'Security & Sessions',
            subtitle: 'Password updates, account status, and logout controls',
            child: _buildSecurityContent(context),
          );
          final notifications = OpsPanel(
            title: 'Notifications',
            subtitle: 'Control whether admin notifications are enabled',
            child: _buildNotificationsContent(context),
          );

          if (vertical) {
            return Column(
              children: [
                profile,
                const SizedBox(height: 16),
                preferences,
                const SizedBox(height: 16),
                security,
                const SizedBox(height: 16),
                notifications,
              ],
            );
          }

          return Column(
            children: [
              _buildPanelPair(left: profile, right: preferences),
              const SizedBox(height: 16),
              _buildPanelPair(left: security, right: notifications),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPanelPair({
    required Widget left,
    required Widget right,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _buildProfileSummary(BuildContext context) {
    final resolvedName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : widget.userName;
    final resolvedEmail = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : widget.userEmail;
    final organization = _organizationIdController.text.trim().isEmpty
        ? '--'
        : _organizationIdController.text.trim();
    final maxUsers = _maxUsersAllowedController.text.trim().isEmpty
        ? '--'
        : _maxUsersAllowedController.text.trim();

    return Column(
      children: [
        _settingsInfoRow('Full Name', resolvedName),
        _settingsInfoRow('Email Address', resolvedEmail),
        _settingsInfoRow('Assigned Role', widget.roleLabel),
        _settingsInfoRow('Organization ID', organization),
        _settingsInfoRow('Max Users Allowed', maxUsers),
        _settingsInfoRow(
            'Account Status', _profileActive ? 'Active' : 'Inactive',
            border: false),
      ],
    );
  }

  Widget _buildPreferencesContent(BuildContext context) {
    return Column(
      children: [
        _buildAppearancePreferences(context),
      ],
    );
  }

  Widget _buildSecurityContent(BuildContext context) {
    return Column(
      children: [
        _settingsActionRow(
          context,
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          subtitle: 'Update sign-in credentials and access protection',
          onTap: () => _showChangePasswordDialog(context),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: _profileActive,
          onChanged: (value) => setState(() => _profileActive = value),
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Account Active',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle:
              const Text('Allow this account to access the admin console'),
        ),
        const SizedBox(height: 8),
        _buildProfileLogoutFooter(context),
      ],
    );
  }

  Widget _buildNotificationsContent(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          value: _notificationsEnabled,
          onChanged: (value) => setState(() => _notificationsEnabled = value),
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Admin Notifications',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: const Text(
            'Receive operational alerts and important system updates',
          ),
        ),
      ],
    );
  }

  Widget _settingsInfoRow(
    String label,
    String value, {
    bool border = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: border
            ? const Border(bottom: BorderSide(color: OpsColors.border))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: OpsColors.outline,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .4,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsActionRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: OpsColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    isLight ? const Color(0xFFE6EFF5) : const Color(0xFF2B4A67),
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
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
        const Divider(height: 24, color: OpsColors.border),
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
