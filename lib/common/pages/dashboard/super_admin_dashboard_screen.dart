import 'package:flutter/material.dart';

import '../../platform/screens/dashboard_screen.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardScreen(
      pageTitle: 'Super Admin Dashboard',
      pageSubtitle: 'Platform-wide monitoring and configuration.',
    );
  }
}
