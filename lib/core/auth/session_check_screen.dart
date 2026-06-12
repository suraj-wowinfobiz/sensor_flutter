import 'package:flutter/material.dart';
import '../../analytics/analytics_page.dart';
import '../../engineer/api/api_client.dart' as engineer_api_client;
import '../../engineer/engineer_page.dart';
import '../../super_admin/api/api_client.dart' as super_admin_api_client;
import '../../super_admin/screens/admin_screen.dart';
import '../../user/api/api_client.dart' as user_api_client;
import '../../user/screens/user_login_screen.dart';
import '../../user/user_page.dart';
import '../../user_admin/api/api_client.dart' as user_admin_api_client;
import '../../user_admin/user_admin_page.dart';
import '../../vendor/api/api_client.dart' as vendor_api_client;
import '../../vendor/vendor_page.dart';
import 'app_session.dart';

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

      // Restore API tokens based on role
      if (token != null && token.isNotEmpty) {
        switch (role) {
          case 'user':
            await user_api_client.ApiClient.setAuthToken(token);
            await super_admin_api_client.ApiClient.setAuthToken(token);
            break;
          case 'user_admin':
            await user_admin_api_client.ApiClient.setAuthToken(token);
            break;
          case 'engineer':
            await engineer_api_client.ApiClient.setAuthToken(token);
            break;
          case 'vendor':
            await vendor_api_client.ApiClient.setAuthToken(token);
            await super_admin_api_client.ApiClient.setAuthToken(token);
            break;
          case 'analytics':
            await super_admin_api_client.ApiClient.setAuthToken(token);
            break;
          case 'super_admin':
            await super_admin_api_client.ApiClient.setAuthToken(token);
            break;
        }
      }

      Widget? targetPage;
      switch (role) {
        case 'user':
          targetPage = const UserPage();
          break;
        case 'user_admin':
          targetPage = const UserAdminPage();
          break;
        case 'engineer':
          targetPage = const EngineerPage();
          break;
        case 'vendor':
          targetPage = const VendorPage();
          break;
        case 'analytics':
          targetPage = const AnalyticsPage();
          break;
        case 'super_admin':
          targetPage = const AdminScreen();
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
          builder: (_) => const UserLoginScreen(),
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
