import 'package:flutter/material.dart';

import '../../shared/widgets/account_settings_panel.dart';

class UserAdminSettingsScreen extends StatelessWidget {
  const UserAdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountSettingsPanel(
      roleLabel: 'User Admin',
      userName: 'fahad.momin',
      userEmail: 'fahad.momin@live.com',
    );
  }
}
