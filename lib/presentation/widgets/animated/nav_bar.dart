import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

class AnimatedNavBar extends StatelessWidget {
  final ValueChanged<String> onViewChanged;
  final String currentView;

  const AnimatedNavBar({
    super.key,
    required this.onViewChanged,
    required this.currentView,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Container(
      height: 70,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF132739) : Colors.white)
            .withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: isDark ? const Color(0xFF28445d) : const Color(0xFFd5e3f1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _openMenu(context, isDark),
            icon: const Icon(Icons.menu),
          ),
          const Icon(Icons.memory, color: Color(0xFF1f7bcf)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Industrial Tilt Admin',
              style: TextStyle(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Future<void> _openMenu(BuildContext context, bool isDark) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Menu',
      barrierColor: Colors.black.withValues(alpha: 0.25),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        return SafeArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 272,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF132739) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF28445d)
                        : const Color(0xFFd5e3f1),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _menuItem(dialogContext, 'Dashboard', Icons.dashboard,
                        'dashboard'),
                    _menuItem(dialogContext, 'Users', Icons.people, 'users'),
                    _menuItem(dialogContext, 'Organizations', Icons.business,
                        'organizations'),
                    _menuItem(
                        dialogContext, 'Sensors', Icons.sensors, 'sensors'),
                    _menuItem(
                        dialogContext, 'Alerts', Icons.notifications, 'alerts'),
                    _menuItem(dialogContext, 'Configuration', Icons.settings,
                        'config'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final offset = Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return SlideTransition(position: offset, child: child);
      },
    );
  }

  Widget _menuItem(
    BuildContext context,
    String label,
    IconData icon,
    String key,
  ) {
    final isActive = currentView == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: InkWell(
        onTap: () {
          onViewChanged(key);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? Colors.white
                    : (isDark
                        ? const Color(0xFF9eb7ce)
                        : const Color(0xFF4f6983)),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                  letterSpacing: 0.1,
                  color: isActive
                      ? Colors.white
                      : (isDark
                          ? const Color(0xFFc7d8ea)
                          : const Color(0xFF2f4a65)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
