import 'package:flutter/material.dart';
import '../../core/theme/ops_theme.dart';
import '../core/responsive/responsive_extensions.dart';

class AdminNotificationItem {
  final String title;
  final String message;
  final DateTime time;

  const AdminNotificationItem({
    required this.title,
    required this.message,
    required this.time,
  });
}

class NavBar extends StatelessWidget {
  final VoidCallback onMenuToggle;
  final bool isMenuOpen;
  final bool showMenuButton;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogoutTap;
  final List<AdminNotificationItem> notifications;
  final bool hasNotifications;

  const NavBar({
    super.key,
    required this.onMenuToggle,
    required this.isMenuOpen,
    this.showMenuButton = true,
    required this.onSettingsTap,
    required this.onLogoutTap,
    this.notifications = const [],
    this.hasNotifications = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.narrowerThan(900);
    final isMobile = context.narrowerThan(700);

    return Container(
      height: isCompact ? 58 : 72,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 32),
      decoration: const BoxDecoration(
        color: OpsColors.surface,
        border: Border(bottom: BorderSide(color: OpsColors.border)),
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
                  color: OpsColors.surfaceLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: OpsColors.border),
                ),
                child: Icon(
                  isMenuOpen ? Icons.close : Icons.menu,
                  color: OpsColors.text,
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
              color: OpsColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.analytics_rounded,
              color: Colors.white,
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
                  'L&T',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: OpsColors.text,
                    fontSize: isCompact ? 18 : 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!isCompact)
                  const Text(
                    'SENSOR ANALYTICS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: OpsColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
                  Icons.notifications_none_rounded,
                  color: OpsColors.text,
                  size: isCompact ? 20 : 23,
                ),
                if (hasNotifications)
                  Positioned(
                    right: 1,
                    top: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: OpsColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: isCompact ? 6 : 10),
          PopupMenuButton<String>(
            tooltip: 'Profile menu',
            onSelected: (value) {
              if (value == 'settings') onSettingsTap();
              if (value == 'logout') onLogoutTap();
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                enabled: false,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('suraj.tiwari'),
                  subtitle: Text('Super Admin'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            child: Row(
              children: [
                if (!isCompact)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'suraj.tiwari',
                        style: TextStyle(
                          color: OpsColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Super Admin',
                        style: TextStyle(
                          color: OpsColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                SizedBox(width: isCompact ? 6 : 10),
                Container(
                  width: isMobile ? 34 : 40,
                  height: isMobile ? 34 : 40,
                  decoration: BoxDecoration(
                    color: OpsColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'F',
                    style: TextStyle(
                      color: Colors.white,
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
