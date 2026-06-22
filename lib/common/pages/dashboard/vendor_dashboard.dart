import 'package:flutter/material.dart';

import '../../../core/auth/app_role.dart';
import '../platform_shell_page.dart';

class VendorDashboardPage extends StatelessWidget {
  const VendorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlatformShellPage(role: AppLoginRole.vendor);
  }
}
