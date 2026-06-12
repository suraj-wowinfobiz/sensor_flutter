import 'package:flutter/material.dart';

import '../../core/auth/global_login_screen.dart';

class UserAdminLoginScreen extends StatelessWidget {
  const UserAdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlobalLoginScreen(
      initialRole: AppLoginRole.userAdmin,
      allowRoleSelection: false,
    );
  }
}
