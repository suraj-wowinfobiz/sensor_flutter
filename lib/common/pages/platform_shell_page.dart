import 'package:flutter/material.dart';

import '../../core/auth/app_role.dart';
import '../platform/screens/admin_screen.dart';

class PlatformShellPage extends StatelessWidget {
  const PlatformShellPage({
    super.key,
    required this.role,
  });

  final AppLoginRole role;

  @override
  Widget build(BuildContext context) {
    return AdminScreen(role: role);
  }
}
