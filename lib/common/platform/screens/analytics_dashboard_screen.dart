import 'package:flutter/material.dart';

import '../../../core/auth/app_role.dart';
import 'role_dashboard_content.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleDashboardContent(role: AppLoginRole.analytics);
  }
}
