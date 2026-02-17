import 'package:flutter/material.dart';

import '../shared/widgets/account_settings_panel.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountSettingsPanel(
      roleLabel: 'Super Admin',
      userName: 'fahad.momin',
      userEmail: 'fahad.momin@live.com',
    );
  }
}
