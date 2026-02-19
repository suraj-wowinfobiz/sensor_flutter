import 'package:flutter/material.dart';

import '../widgets/user_admin_account_settings_panel.dart';

class UserAdminSettingsScreen extends StatelessWidget {
  const UserAdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserAdminAccountSettingsPanel(
      roleLabel: 'User Admin',
      userName: 'suraj.tiwari',
      userEmail: 'suraj.tiwari@live.com',
    );
  }
}
