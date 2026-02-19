import 'package:flutter/material.dart';

class UserSidebarSettingsScreen extends StatelessWidget {
  const UserSidebarSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white.withValues(alpha: 0.9)
              : const Color(0xFF1a3148).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_suggest_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Sidebar Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isLight
                        ? const Color(0xFF1e3a5a)
                        : const Color(0xFFc0d6f0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This is the sidebar settings page only.',
              style: TextStyle(
                fontSize: 15,
                color:
                    isLight ? const Color(0xFF4a6b8a) : const Color(0xFF8aaac9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'For profile/account settings, use the top navbar settings icon.',
              style: TextStyle(
                fontSize: 14,
                color:
                    isLight ? const Color(0xFF4a6b8a) : const Color(0xFF8aaac9),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Coming Soon',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
