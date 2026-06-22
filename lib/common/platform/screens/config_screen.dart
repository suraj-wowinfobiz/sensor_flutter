import 'package:flutter/material.dart';

import '../../../core/auth/app_role.dart';
import '../widgets/admin_account_settings_panel.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({
    super.key,
    this.role = AppLoginRole.admin,
  });

  final AppLoginRole role;

  @override
  Widget build(BuildContext context) {
    return AdminAccountSettingsPanel(
      roleLabel: role.label,
      userName: 'suraj.tiwari',
      userEmail: 'suraj.tiwari@live.com',
    );
  }
}
