import 'package:flutter/material.dart';

import '../../../core/auth/app_role.dart';
import 'analytics_dashboard_screen.dart';
import 'analytics_role_dashboard_screen.dart';
import 'engineer_dashboard_screen.dart';
import 'super_admin_dashboard_screen.dart';
import 'user_admin_dashboard_screen.dart';
import 'user_dashboard_screen.dart';
import 'vendor_dashboard_screen.dart';

class RoleDashboardScreen extends StatelessWidget {
  const RoleDashboardScreen({
    super.key,
    required this.role,
  });

  final AppLoginRole role;

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case AppLoginRole.admin:
        return const SuperAdminDashboardScreen();
      case AppLoginRole.user:
        return const UserDashboardScreen();
      case AppLoginRole.userAdmin:
        return const UserAdminDashboardScreen();
      case AppLoginRole.engineer:
        return const EngineerDashboardScreen();
      case AppLoginRole.vendor:
        return const VendorDashboardScreen();
      case AppLoginRole.analytics:
        return const AnalyticsDashboardScreen();
      case AppLoginRole.analyticsRole:
        return const AnalyticsRoleDashboardScreen();
    }
  }
}
