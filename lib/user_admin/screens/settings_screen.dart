import 'package:flutter/material.dart';

import '../../super_admin/widgets/admin_account_settings_panel.dart';

class UserAdminSettingsScreen extends StatelessWidget {
  const UserAdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminAccountSettingsPanel(
      roleLabel: 'User Admin',
      userName: 'suraj.tiwari',
      userEmail: 'suraj.tiwari@live.com',
    );
  }
}
