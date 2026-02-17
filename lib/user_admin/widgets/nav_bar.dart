import 'package:flutter/material.dart';

class UserAdminNavBar extends StatelessWidget {
  final VoidCallback onMenuToggle;
  final bool isMenuOpen;
  final bool showMenuButton;
  final VoidCallback onSettingsTap;

  const UserAdminNavBar({
    super.key,
    required this.onMenuToggle,
    required this.isMenuOpen,
    this.showMenuButton = true,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 900;

    final barColor = isLight
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFF0f2a42);
    const barTextColor = Color(0xFFEAF3FF);

    return Container(
      height: 74,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onMenuToggle,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: Icon(
                  isMenuOpen ? Icons.close : Icons.menu,
                  color: barTextColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.speed, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MONITORING SYSTEM',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: barTextColor,
                    fontSize: isCompact ? 17 : 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!isCompact)
                  Text(
                    'INDUSTRIAL SENSOR MONITORING PORTAL',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: barTextColor.withValues(alpha: 0.82),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
              ],
            ),
          ),
          if (!isCompact) ...[
            IconButton(
              tooltip: 'Notifications',
              onPressed: () {},
              icon: Stack(
                children: [
                  Icon(Icons.notifications_none, color: barTextColor),
                  Positioned(
                    right: 1,
                    top: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE54C4C),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: onSettingsTap,
              icon: Icon(Icons.settings_outlined, color: barTextColor),
            ),
            const SizedBox(width: 10),
          ],
          if (!isCompact)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'fahad.momin',
                  style: TextStyle(
                    color: barTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'User Admin',
                  style: TextStyle(
                    color: barTextColor.withValues(alpha: 0.84),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              'F',
              style: TextStyle(
                color: barTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
