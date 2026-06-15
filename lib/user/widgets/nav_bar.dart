import 'package:flutter/material.dart';

import '../../core/theme/ops_theme.dart';

class UserNotificationItem {
  final String title;
  final String message;
  final DateTime time;

  const UserNotificationItem({
    required this.title,
    required this.message,
    required this.time,
  });
}

class UserNavBar extends StatelessWidget {
  static const double desktopHeight = 78;

  final VoidCallback onMenuToggle;
  final bool isMenuOpen;
  final bool showMenuButton;
  final VoidCallback onTopSettingsTap;
  final VoidCallback onLogoutTap;
  final List<UserNotificationItem> notifications;
  final bool hasNotifications;
  final String currentView;
  final String profileName;
  final String profileRole;
  final String profileInitial;

  const UserNavBar({
    super.key,
    required this.onMenuToggle,
    required this.isMenuOpen,
    this.showMenuButton = true,
    required this.onTopSettingsTap,
    required this.onLogoutTap,
    this.currentView = 'dashboard',
    this.notifications = const [],
    this.hasNotifications = false,
    this.profileName = 'JS',
    this.profileRole = 'Site Operator - L&T',
    this.profileInitial = 'JS',
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showSearch = width >= 980;
    final showProfileText = width >= 720;
    final isDesktop = width >= 1024;
    final showProjectSelector = isDesktop && width >= 1200;

    return Container(
      height: isDesktop ? desktopHeight : 88,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 20),
      decoration: const BoxDecoration(
        color: OpsColors.surface,
        border: Border(bottom: BorderSide(color: OpsColors.border)),
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            IconButton(
              tooltip: isMenuOpen ? 'Close menu' : 'Open menu',
              onPressed: onMenuToggle,
              icon: Icon(isMenuOpen ? Icons.close : Icons.menu),
            ),
            const SizedBox(width: 12),
          ],
          if (showProjectSelector) ...[
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: const BorderSide(color: OpsColors.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_view_rounded,
                      size: 18, color: OpsColors.primary),
                  SizedBox(width: 12),
                  Text(
                    'Project Alpha',
                    style: TextStyle(
                      color: OpsColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: OpsColors.muted,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
          ],
          if (showSearch)
            SizedBox(
              width: width >= 1400 ? 420 : 320,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search anything...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 22),
                  fillColor: const Color(0xFFF6F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: OpsColors.primary.withValues(alpha: .30),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          const Spacer(),
          _NotificationsButton(
            notifications: notifications,
            hasNotifications: hasNotifications,
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Help',
            onPressed: () {},
            icon: const Icon(Icons.help_outline_rounded),
          ),
          const SizedBox(width: 20),
          Container(
            width: 1,
            height: isDesktop ? 42 : 40,
            color: OpsColors.border,
          ),
          const SizedBox(width: 20),
          PopupMenuButton<String>(
            tooltip: 'Profile',
            onSelected: (value) {
              if (value == 'settings') onTopSettingsTap();
              if (value == 'logout') onLogoutTap();
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'profile',
                enabled: false,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(profileName),
                  subtitle: Text(profileRole),
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
                if (showProfileText) ...[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        profileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        profileRole,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 11.5,
                              color: OpsColors.muted,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                ],
                CircleAvatar(
                  radius: 20,
                  backgroundColor: OpsColors.primaryContainer,
                  child: Text(
                    profileInitial,
                    style: const TextStyle(
                      color: Color(0xFFEEEFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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

class _NotificationsButton extends StatelessWidget {
  final List<UserNotificationItem> notifications;
  final bool hasNotifications;

  const _NotificationsButton({
    required this.notifications,
    required this.hasNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Notifications',
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 380),
      itemBuilder: (context) {
        if (notifications.isEmpty) {
          return const [
            PopupMenuItem<int>(
              enabled: false,
              child: OpsEmptyState(
                title: 'No notifications',
                message: 'There are no unresolved alerts in your workspace.',
                icon: Icons.notifications_none_rounded,
              ),
            ),
          ];
        }

        return notifications.take(6).map((item) {
          return PopupMenuItem<int>(
            enabled: false,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.circle, size: 9),
              title: Text(item.title),
              subtitle: Text(
                item.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined, color: OpsColors.text),
          if (hasNotifications)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: OpsColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
