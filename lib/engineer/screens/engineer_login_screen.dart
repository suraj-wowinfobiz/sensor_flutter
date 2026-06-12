import 'package:flutter/material.dart';

import '../../core/auth/global_login_screen.dart';

class EngineerLoginScreen extends StatelessWidget {
  const EngineerLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlobalLoginScreen(
      initialRole: AppLoginRole.engineer,
      allowRoleSelection: false,
    );
  }
}
