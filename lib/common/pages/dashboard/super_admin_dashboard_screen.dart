import 'package:flutter/material.dart';

import '../../../core/auth/app_role.dart';
import 'role_dashboard_content.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleDashboardContent(role: AppLoginRole.admin);
  }
}
