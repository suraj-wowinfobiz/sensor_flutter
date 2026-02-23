import 'package:flutter/material.dart';
import '../../core/responsive/responsive_extensions.dart';

class EngineerNotificationItem {
  final String title;
  final String message;
  final DateTime time;

  const EngineerNotificationItem({
    required this.title,
    required this.message,
    required this.time,
  });
}

class EngineerNavBar extends StatelessWidget {
  final VoidCallback onMenuToggle;
  final bool isMenuOpen;
  final bool showMenuButton;
  final VoidCallback onUserMenuSettingsTap;
  final VoidCallback onLogoutTap;
  final List<EngineerNotificationItem> notifications;
  final bool hasNotifications;

  const EngineerNavBar({
    super.key,
    required this.onMenuToggle,
    required this.isMenuOpen,
    this.showMenuButton = true,
    required this.onUserMenuSettingsTap,
    required this.onLogoutTap,
    this.notifications = const [],
    this.hasNotifications = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final scheme = theme.colorScheme;
    final isCompact = context.narrowerThan(900);
    final isMobile = context.narrowerThan(700);

    final barColor = scheme.primary;
    final barTextColor = scheme.onPrimary;
    final chromeFill = scheme.onPrimary.withValues(alpha: 0.16);
    final chromeBorder = scheme.onPrimary.withValues(alpha: 0.24);

    return Container(
      height: isCompact ? 58 : 66,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14),
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isLight ? 0.15 : 0.3),
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
                width: isCompact ? 36 : 42,
                height: isCompact ? 36 : 42,
                decoration: BoxDecoration(
                  color: chromeFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: chromeBorder),
                ),
                child: Icon(
                  isMenuOpen ? Icons.close : Icons.menu,
                  color: barTextColor,
                  size: isCompact ? 20 : 24,
                ),
              ),
            ),
            SizedBox(width: isCompact ? 8 : 12),
          ],
          Container(
            width: isCompact ? 32 : 40,
            height: isCompact ? 32 : 40,
            decoration: BoxDecoration(
              color: chromeFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.speed,
              color: barTextColor,
              size: isCompact ? 17 : 20,
            ),
          ),
          SizedBox(width: isCompact ? 8 : 12),
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
                    fontSize: isCompact ? 14 : 18,
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
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<int>(
            tooltip: 'Notifications',
            offset: const Offset(0, 40),
            constraints: const BoxConstraints(minWidth: 300, maxWidth: 360),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            itemBuilder: (context) {
              if (notifications.isEmpty) {
                return [
                  const PopupMenuItem<int>(
                    enabled: false,
                    height: 72,
                    child: Center(
                      child: Text(
                        'No notifications',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ];
              }

              return notifications.take(6).map((item) {
                return PopupMenuItem<int>(
                  enabled: false,
                  height: 64,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Icon(Icons.circle, size: 9),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              item.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
            child: Stack(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: barTextColor,
                  size: isCompact ? 20 : 23,
                ),
                if (hasNotifications)
                  Positioned(
                    right: 1,
                    top: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: scheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: isCompact ? 6 : 10),
          PopupMenuButton<String>(
            tooltip: 'User Menu',
            onSelected: (_) {},
            itemBuilder: (context) => const [],
            child: Row(
              children: [
                if (!isCompact)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'suraj.tiwari',
                        style: TextStyle(
                          color: barTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Engineer',
                        style: TextStyle(
                          color: barTextColor.withValues(alpha: 0.84),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                SizedBox(width: isCompact ? 6 : 10),
                Container(
                  width: isMobile ? 34 : 40,
                  height: isMobile ? 34 : 40,
                  decoration: BoxDecoration(
                    color: chromeFill,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'F',
                    style: TextStyle(
                      color: barTextColor,
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
