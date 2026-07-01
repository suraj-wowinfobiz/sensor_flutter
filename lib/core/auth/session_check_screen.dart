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
    final sessionData = await AppSession.getSessionData();
    final role = sessionData['role']?.trim() ?? '';
    final token = sessionData['token']?.trim() ?? '';

    if (!mounted) return;

    if (token.isNotEmpty) {
      await ApiClient.setAuthToken(token);
      try {
        await ApiClient.get('/api/v1/auth/me').timeout(
          const Duration(seconds: 6),
        );
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

      final appRole = appLoginRoleFromStoredValue(role);
      final Widget? targetPage =
          appRole == null ? null : PlatformShellPage(role: appRole);

      if (targetPage != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => targetPage),
        );
        return;
      }

      await AppSession.clearSession();
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
