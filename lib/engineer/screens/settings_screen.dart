import 'package:flutter/material.dart';

import '../widgets/engineer_account_settings_panel.dart';

class EngineerSettingsScreen extends StatelessWidget {
  const EngineerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EngineerAccountSettingsPanel(
      roleLabel: 'Engineer',
      userName: 'suraj.tiwari',
      userEmail: 'suraj.tiwari@live.com',
    );
  }
}
