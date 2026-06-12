import 'package:flutter/material.dart';

import '../../core/auth/global_login_screen.dart';

class UserLoginScreen extends StatelessWidget {
  const UserLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlobalLoginScreen(
      initialRole: AppLoginRole.user,
      allowRoleSelection: false,
    );
  }
}
