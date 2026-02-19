import 'package:flutter/material.dart';

enum _SettingsTab { profile, notifications, access, security, thresholds }

class EngineerAccountSettingsPanel extends StatefulWidget {
  final String roleLabel;
  final String userName;
  final String userEmail;

  const EngineerAccountSettingsPanel({
    super.key,
    required this.roleLabel,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<EngineerAccountSettingsPanel> createState() =>
      _EngineerAccountSettingsPanelState();
}

class _EngineerAccountSettingsPanelState
    extends State<EngineerAccountSettingsPanel> {
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
  double _warningThreshold = 2.8;
  double _criticalThreshold = 4.0;
  double _emergencyThreshold = 5.2;
  String _warningSound = 'Soft Chime';
  String _criticalSound = 'Siren';
  String _emergencySound = 'Emergency Bell';

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
            return InkWell(
              borderRadius: BorderRadius.circular(12),
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
                    Text(
                      'Full Organization Access',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'You currently have unrestricted access to sites, zones, and sensors.',
                ),
                const SizedBox(height: 14),
                const Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                        width: 220,
                        child: _AccessStatCard(label: 'All Sites', value: '1')),
                    SizedBox(
                        width: 220,
                        child: _AccessStatCard(label: 'All Zones', value: '1')),
                    SizedBox(
                        width: 220,
                        child: _AccessStatCard(
                            label: 'All Sensors', value: '214')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab(BuildContext context) {
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
        ],
      ),
    );
  }

  Widget _buildThresholdsTab(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final subColor =
        isLight ? const Color(0xFF4f6b82) : const Color(0xFF9db7d2);
    return _sectionContainer(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Threshold Configuration',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Configure multiple threshold levels with dedicated colors and sounds.',
            style: TextStyle(color: subColor),
          ),
          const SizedBox(height: 14),
          _thresholdTile(
            context,
            title: 'Warning',
            color: const Color(0xFFD39A00),
            value: _warningThreshold,
            onValueChanged: (v) => setState(() => _warningThreshold = v),
            sound: _warningSound,
            onSoundChanged: (v) =>
                setState(() => _warningSound = v ?? _warningSound),
          ),
          _thresholdTile(
            context,
            title: 'Critical',
            color: const Color(0xFFE54C4C),
            value: _criticalThreshold,
            onValueChanged: (v) => setState(() => _criticalThreshold = v),
            sound: _criticalSound,
            onSoundChanged: (v) =>
                setState(() => _criticalSound = v ?? _criticalSound),
          ),
          _thresholdTile(
            context,
            title: 'Emergency',
            color: const Color(0xFF7A4FD6),
            value: _emergencyThreshold,
            onValueChanged: (v) => setState(() => _emergencyThreshold = v),
            sound: _emergencySound,
            onSoundChanged: (v) =>
                setState(() => _emergencySound = v ?? _emergencySound),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFEAF2F6),
              border: Border.all(color: const Color(0xFFD0DEE6)),
            ),
            child: Text(
              'Applied order: Warning ${_warningThreshold.toStringAsFixed(1)}° -> Critical ${_criticalThreshold.toStringAsFixed(1)}° -> Emergency ${_emergencyThreshold.toStringAsFixed(1)}°',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF3E5765),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thresholdTile(
    BuildContext context, {
    required String title,
    required Color color,
    required double value,
    required ValueChanged<double> onValueChanged,
    required String sound,
    required ValueChanged<String?> onSoundChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '$title Threshold',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const Spacer(),
              Text(
                '${value.toStringAsFixed(1)}°',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 8,
            divisions: 80,
            onChanged: onValueChanged,
            activeColor: color,
          ),
          DropdownButtonFormField<String>(
            initialValue: sound,
            decoration: InputDecoration(
              labelText: 'Alert Sound',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'Soft Chime', child: Text('Soft Chime')),
              DropdownMenuItem(value: 'Alarm Beep', child: Text('Alarm Beep')),
              DropdownMenuItem(value: 'Siren', child: Text('Siren')),
              DropdownMenuItem(
                  value: 'Emergency Bell', child: Text('Emergency Bell')),
            ],
            onChanged: onSoundChanged,
          ),
        ],
      ),
    );
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
