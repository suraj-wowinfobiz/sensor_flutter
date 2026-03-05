import 'package:flutter/material.dart';

import 'analytics/analytics_page.dart';
import 'engineer/engineer_page.dart';
import 'super_admin/widgets/login_preferences_button.dart';
import 'super_admin/screens/admin_screen.dart';
import 'user/user_page.dart';
import 'user_admin/user_admin_page.dart';
import 'vendor/vendor_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _isApiEnabled = true;

  void _openRole({
    required String loginRoute,
    required Widget bypassPage,
  }) {
    if (_isApiEnabled) {
      Navigator.pushNamed(context, loginRoute);
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => bypassPage));
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final titleColor =
        isLight ? const Color(0xFF1A2B3C) : const Color(0xFFD7E8F6);
    final subColor =
        isLight ? const Color(0xFF5F7285) : const Color(0xFF9DB7D2);

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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isApiEnabled
                            ? 'API calls enabled'
                            : 'API calls disabled (bypass)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isApiEnabled,
                      onChanged: (value) =>
                          setState(() => _isApiEnabled = value),
                    ),
                  ],
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
                  onTap: () => _openRole(
                    loginRoute: '/login/user',
                    bypassPage: const UserPage(),
                  ),
                ),
                const SizedBox(height: 16),
                _RoleButton(
                  title: 'User Admin',
                  subtitle: 'Manage users and organizations',
                  icon: Icons.admin_panel_settings_outlined,
                  onTap: () => _openRole(
                    loginRoute: '/login/user-admin',
                    bypassPage: const UserAdminPage(),
                  ),
                ),
                const SizedBox(height: 16),
                _RoleButton(
                  title: 'Engineer',
                  subtitle: 'Configure devices and sensors',
                  icon: Icons.engineering_outlined,
                  onTap: () => _openRole(
                    loginRoute: '/login/engineer',
                    bypassPage: const EngineerPage(),
                  ),
                ),
                const SizedBox(height: 16),
                _RoleButton(
                  title: 'Vendor',
                  subtitle: 'Access vendor dashboard and settings',
                  icon: Icons.storefront_outlined,
                  onTap: () => _openRole(
                    loginRoute: '/login/vendor',
                    bypassPage: const VendorPage(),
                  ),
                ),
                const SizedBox(height: 16),
                _RoleButton(
                  title: 'Analytics',
                  subtitle: 'Access analytics dashboard and settings',
                  icon: Icons.insights_outlined,
                  onTap: () => _openRole(
                    loginRoute: '/login/analytics',
                    bypassPage: const AnalyticsPage(),
                  ),
                ),
                const SizedBox(height: 16),
                _RoleButton(
                  title: 'Super Admin',
                  subtitle: 'Full system access',
                  icon: Icons.security_outlined,
                  onTap: () => _openRole(
                    loginRoute: '/login/super-admin',
                    bypassPage: const AdminScreen(),
                  ),
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
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
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
                      color: isLight
                          ? const Color(0xFF5F7285)
                          : const Color(0xFF9DB7D2),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color:
                  isLight ? const Color(0xFF5F7285) : const Color(0xFF9DB7D2),
            ),
          ],
        ),
      ),
    );
  }
}
