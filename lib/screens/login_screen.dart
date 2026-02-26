import 'package:flutter/material.dart';

import '../widgets/login_preferences_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final titleColor = isLight ? const Color(0xFF1A2B3C) : const Color(0xFFD7E8F6);
    final subColor = isLight ? const Color(0xFF5F7285) : const Color(0xFF9DB7D2);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Align(
                  alignment: Alignment.topRight,
                  child: LoginPreferencesButton(),
                ),
                Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your role to continue',
                  style: TextStyle(
                    fontSize: 18,
                    color: subColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
                _RoleButton(
                  title: 'User',
                  subtitle: 'View sensor data and alerts',
                  icon: Icons.person_outline,
                  onTap: () => Navigator.pushNamed(context, '/login/user'),
                ),
                const SizedBox(height: 16),
                _RoleButton(
                  title: 'User Admin',
                  subtitle: 'Manage users and organizations',
                  icon: Icons.admin_panel_settings_outlined,
                  onTap: () => Navigator.pushNamed(context, '/login/user-admin'),
                ),
                const SizedBox(height: 16),
                _RoleButton(
                  title: 'Engineer',
                  subtitle: 'Configure devices and sensors',
                  icon: Icons.engineering_outlined,
                  onTap: () => Navigator.pushNamed(context, '/login/engineer'),
                ),
                const SizedBox(height: 16),
                _RoleButton(
                  title: 'Super Admin',
                  subtitle: 'Full system access',
                  icon: Icons.security_outlined,
                  onTap: () => Navigator.pushNamed(context, '/login/super-admin'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = Theme.of(context).dividerColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isLight ? const Color(0xFF5F7285) : const Color(0xFF9DB7D2),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isLight ? const Color(0xFF5F7285) : const Color(0xFF9DB7D2),
            ),
          ],
        ),
      ),
    );
  }
}
