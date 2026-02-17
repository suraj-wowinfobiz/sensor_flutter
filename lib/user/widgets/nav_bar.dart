import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

class UserNavBar extends StatelessWidget {
  final VoidCallback onMenuToggle;
  final bool isMenuOpen;
  final bool showMenuButton;

  const UserNavBar({
    super.key,
    required this.onMenuToggle,
    required this.isMenuOpen,
    this.showMenuButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final width = MediaQuery.of(context).size.width;
    final veryCompact = width < 560;
    final isCompact = width < 760;
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      margin: const EdgeInsets.all(18),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 16,
        vertical: isCompact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withValues(alpha: 0.9)
            : const Color(0xFF1a3148).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showMenuButton)
            GestureDetector(
              onTap: onMenuToggle,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFf0f5fd)
                      : const Color(0xFF203a54),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Icon(
                  isMenuOpen ? Icons.close : Icons.menu,
                  color: isLight
                      ? const Color(0xFF0a1a2a)
                      : const Color(0xFFe8f1fc),
                ),
              ),
            ),
          if (showMenuButton) const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  const Color(0xFF5f9eff),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.memory, color: Colors.white, size: 18),
          ),
          if (!veryCompact) const SizedBox(width: 8),
          Expanded(
            child: veryCompact
                ? const SizedBox.shrink()
                : RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      text: 'TILT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isLight
                            ? const Color(0xFF0a1a2a)
                            : const Color(0xFFe8f1fc),
                      ),
                      children: [
                        TextSpan(
                          text: 'USER',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
          ),
          if (veryCompact)
            IconButton(
              tooltip: themeProvider.isDarkMode ? 'Dark mode' : 'Light mode',
              onPressed: () =>
                  themeProvider.toggleTheme(!themeProvider.isDarkMode),
              icon: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                size: 18,
              ),
            ),
          if (!veryCompact)
            Container(
              decoration: BoxDecoration(
                color:
                    isLight ? const Color(0xFFf0f5fd) : const Color(0xFF203a54),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  _buildThemeOption(
                    context,
                    icon: Icons.light_mode,
                    label: 'Light',
                    isActive: !themeProvider.isDarkMode,
                    onTap: () => themeProvider.toggleTheme(false),
                  ),
                  _buildThemeOption(
                    context,
                    icon: Icons.dark_mode,
                    label: 'Dark',
                    isActive: themeProvider.isDarkMode,
                    onTap: () => themeProvider.toggleTheme(true),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive
                  ? Colors.white
                  : (isLight
                      ? const Color(0xFF4a6b8a)
                      : const Color(0xFF8aaac9)),
            ),
            if (MediaQuery.of(context).size.width > 900) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : (isLight
                          ? const Color(0xFF4a6b8a)
                          : const Color(0xFF8aaac9)),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
