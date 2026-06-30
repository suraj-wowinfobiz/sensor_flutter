import 'package:flutter/material.dart';

import '../../common/pages/platform_shell_page.dart';
import '../../common/platform/api/api_client.dart';
import '../../main_page.dart';
import 'app_role.dart';
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

      if (token != null && token.isNotEmpty) {
        await ApiClient.setAuthToken(token);
        try {
          await ApiClient.get('/api/v1/auth/me');
        } catch (_) {
          await AppSession.clearSession();
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const MainPage(),
            ),
          );
          return;
        }
      }

      Widget? targetPage;
      switch (role) {
        case 'user':
          targetPage = const PlatformShellPage(role: AppLoginRole.user);
          break;
        case 'user_admin':
          targetPage = const PlatformShellPage(role: AppLoginRole.userAdmin);
          break;
        case 'engineer':
          targetPage = const PlatformShellPage(role: AppLoginRole.engineer);
          break;
        case 'vendor':
          targetPage = const PlatformShellPage(role: AppLoginRole.vendor);
          break;
        case 'analytics':
          targetPage = const PlatformShellPage(role: AppLoginRole.analytics);
          break;
        case 'analytics_role':
          targetPage =
              const PlatformShellPage(role: AppLoginRole.analyticsRole);
          break;
        case 'admin':
        case 'super_admin':
          targetPage = const PlatformShellPage(role: AppLoginRole.admin);
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
          builder: (_) => const MainPage(),
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
