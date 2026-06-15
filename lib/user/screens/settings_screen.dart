import 'package:flutter/material.dart';

import '../../core/theme/ops_theme.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  bool _emailAlerts = true;
  bool _liveRefresh = true;
  bool _weeklyReports = false;
  String _theme = 'Operational Light';

  @override
  Widget build(BuildContext context) {
    return OpsPage(
      title: 'Settings',
      subtitle:
          'Profile, notification, session, report delivery, and workspace preferences',
      actions: [
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Settings saved for $_theme')),
            );
          },
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('Save Changes'),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final vertical = constraints.maxWidth < 980;
          const profile = OpsPanel(
            title: 'Profile Details',
            subtitle: 'Account and workspace assignment',
            child: Column(
              children: [
                _InfoRow('Full Name', 'JS'),
                _InfoRow('Email Address', 'user.operator@live.com'),
                _InfoRow('Assigned Role', 'Site Operator'),
                _InfoRow('Current Workspace', 'Project Alpha'),
                _InfoRow('Organization', 'WowGardian Construction'),
              ],
            ),
          );
          final preferences = OpsPanel(
            title: 'Preferences',
            subtitle: 'Dashboard behavior, notifications, and report delivery',
            child: Column(
              children: [
                _SwitchRow(
                  label: 'Email Notifications',
                  subtitle: 'Receive alert escalations and weekly summaries',
                  value: _emailAlerts,
                  onChanged: (value) => setState(() => _emailAlerts = value),
                ),
                _SwitchRow(
                  label: 'Live Dashboard Refresh',
                  subtitle: 'Continuously refresh readings and KPI cards',
                  value: _liveRefresh,
                  onChanged: (value) => setState(() => _liveRefresh = value),
                ),
                _SwitchRow(
                  label: 'Weekly Reports',
                  subtitle: 'Generate weekly site performance reports',
                  value: _weeklyReports,
                  onChanged: (value) => setState(() => _weeklyReports = value),
                ),
              ],
            ),
          );
          const security = OpsPanel(
            title: 'Security & Sessions',
            subtitle: 'Password, active sessions, and account access',
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  subtitle: 'Update sign-in credentials and access protection',
                ),
                _ActionRow(
                  icon: Icons.devices_outlined,
                  title: 'Signed-in Devices',
                  subtitle: 'Review currently active account sessions',
                ),
              ],
            ),
          );
          final appearance = OpsPanel(
            title: 'Workspace Appearance',
            subtitle: 'Select the operational preset for dashboard surfaces',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ThemeChoice(
                  label: 'Operational Light',
                  active: _theme == 'Operational Light',
                  onTap: () => setState(() => _theme = 'Operational Light'),
                ),
                _ThemeChoice(
                  label: 'High Contrast',
                  active: _theme == 'High Contrast',
                  onTap: () => setState(() => _theme = 'High Contrast'),
                ),
                _ThemeChoice(
                  label: 'Compact Tables',
                  active: _theme == 'Compact Tables',
                  onTap: () => setState(() => _theme = 'Compact Tables'),
                ),
              ],
            ),
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
                appearance,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  children: [
                    profile,
                    SizedBox(height: 16),
                    security,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    preferences,
                    const SizedBox(height: 16),
                    appearance,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: OpsColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
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
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: OpsColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ThemeChoice({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => onTap(),
    );
  }
}
