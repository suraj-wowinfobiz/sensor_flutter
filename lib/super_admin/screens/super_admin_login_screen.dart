import 'package:flutter/material.dart';

import '../../core/auth/global_login_screen.dart';

class SuperAdminLoginScreen extends StatelessWidget {
  const SuperAdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlobalLoginScreen(
      initialRole: AppLoginRole.superAdmin,
      allowRoleSelection: false,
    );
  }
}
