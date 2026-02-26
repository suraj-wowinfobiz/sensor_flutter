import 'package:flutter/material.dart';

import '../../user/widgets/user_account_settings_panel.dart';

class AnalyticsRoleSettingsScreen extends StatelessWidget {
  const AnalyticsRoleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserAccountSettingsPanel(
      roleLabel: 'Analytics',
      userName: 'analytics.operator',
      userEmail: 'analytics.operator@live.com',
    );
  }
}
