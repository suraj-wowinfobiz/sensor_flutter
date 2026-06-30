import 'package:flutter/material.dart';
import '../../../core/auth/app_session.dart';

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
    return FutureBuilder<Map<String, String?>>(
      future: AppSession.getSessionData(),
      builder: (context, snapshot) {
        final session = snapshot.data ?? const <String, String?>{};
        final username = (session['username'] ?? '').trim();
        return AdminAccountSettingsPanel(
          roleLabel: role.label,
          userName: username,
          userEmail: username,
        );
      },
    );
  }
}
