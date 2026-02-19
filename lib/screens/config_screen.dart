import 'package:flutter/material.dart';

import '../widgets/admin_account_settings_panel.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminAccountSettingsPanel(
      roleLabel: 'Super Admin',
      userName: 'suraj.tiwari',
      userEmail: 'suraj.tiwari@live.com',
    );
  }
}
