import 'package:flutter/material.dart';

import '../../super_admin/widgets/admin_account_settings_panel.dart';

class UserSettingsScreen extends StatelessWidget {
  const UserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminAccountSettingsPanel(
      roleLabel: 'User',
      userName: 'suraj.tiwari',
      userEmail: 'suraj.tiwari@live.com',
    );
  }
}
