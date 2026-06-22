import 'package:flutter/material.dart';

import '../../common/pages/dashboard/admin_dashboard.dart';
import '../../common/pages/dashboard/analytics_dashboard.dart';
import '../../common/pages/dashboard/analytics_role_dashboard.dart';
import '../../common/pages/dashboard/engineer_dashboard.dart';
import '../../common/pages/dashboard/user_admin_dashboard.dart';
import '../../common/pages/dashboard/user_dashboard.dart';
import '../../common/pages/dashboard/vendor_dashboard.dart';
import '../../common/platform/api/api_client.dart';
import 'app_session.dart';
import 'global_login_screen.dart';

class SessionCheckScreen extends StatefulWidget {
  const SessionCheckScreen({super.key});

  @override
  State<SessionCheckScreen> createState() => _SessionCheckScreenState();
}

class _SessionCheckScreenState extends State<SessionCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final isValid = await AppSession.isSessionValid();

    if (!mounted) return;

    if (isValid) {
      final sessionData = await AppSession.getSessionData();
      final role = sessionData['role'];
      final token = sessionData['token'];

      if (token != null && token.isNotEmpty) {
        await ApiClient.setAuthToken(token);
      }

      Widget? targetPage;
      switch (role) {
        case 'user':
          targetPage = const UserDashboardPage();
          break;
        case 'user_admin':
          targetPage = const UserAdminDashboardPage();
          break;
        case 'engineer':
          targetPage = const EngineerDashboardPage();
          break;
        case 'vendor':
          targetPage = const VendorDashboardPage();
          break;
        case 'analytics':
          targetPage = const AnalyticsDashboardPage();
          break;
        case 'analytics_role':
          targetPage = const AnalyticsRoleDashboardPage();
          break;
        case 'admin':
        case 'super_admin':
          targetPage = const AdminDashboardPage();
          break;
      }

      if (targetPage != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => targetPage!),
        );
        return;
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const GlobalLoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
