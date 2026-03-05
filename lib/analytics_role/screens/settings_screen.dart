import 'package:flutter/material.dart';

import '../../super_admin/widgets/admin_account_settings_panel.dart';

class AnalyticsRoleSettingsScreen extends StatelessWidget {
  const AnalyticsRoleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminAccountSettingsPanel(
      roleLabel: 'Analytics',
      userName: 'analytics.operator',
      userEmail: 'analytics.operator@live.com',
    );
  }
}
