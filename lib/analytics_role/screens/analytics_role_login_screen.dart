import 'package:flutter/material.dart';

import '../../core/auth/global_login_screen.dart';

class AnalyticsRoleLoginScreen extends StatelessWidget {
  const AnalyticsRoleLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlobalLoginScreen(
      initialRole: AppLoginRole.analyticsRole,
      allowRoleSelection: false,
    );
  }
}
