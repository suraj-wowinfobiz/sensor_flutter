import 'package:flutter/material.dart';

import '../../core/auth/global_login_screen.dart';

class AnalyticsLoginScreen extends StatelessWidget {
  const AnalyticsLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlobalLoginScreen(
      initialRole: AppLoginRole.analytics,
      allowRoleSelection: false,
    );
  }
}
