import 'package:flutter/material.dart';

import '../../shared/widgets/account_settings_panel.dart';

class EngineerSettingsScreen extends StatelessWidget {
  const EngineerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountSettingsPanel(
      roleLabel: 'Engineer',
      userName: 'fahad.momin',
      userEmail: 'fahad.momin@live.com',
    );
  }
}
