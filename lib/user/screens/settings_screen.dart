import 'package:flutter/material.dart';

import '../../shared/widgets/account_settings_panel.dart';

class UserSettingsScreen extends StatelessWidget {
  const UserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountSettingsPanel(
      roleLabel: 'User',
      userName: 'fahad.momin',
      userEmail: 'fahad.momin@live.com',
    );
  }
}
