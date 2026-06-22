import 'package:flutter/material.dart';

import '../../../core/theme/ops_theme.dart';

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
  static const double desktopHeight = 78;

  final VoidCallback onMenuToggle;
  final bool isMenuOpen;
  final bool showMenuButton;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogoutTap;
  final List<AdminNotificationItem> notifications;
  final bool hasNotifications;
  final String currentView;
  final String profileName;
  final String profileRole;
  final String profileInitial;
  final String workspaceTitle;
  final IconData workspaceIcon;

  const NavBar({
    super.key,
    required this.onMenuToggle,
    required this.isMenuOpen,
    this.showMenuButton = true,
    required this.onSettingsTap,
    required this.onLogoutTap,
    this.notifications = const [],
    this.hasNotifications = false,
    this.currentView = 'dashboard',
    this.profileName = 'suraj.tiwari',
    this.profileRole = 'Super Admin',
    this.profileInitial = 'SA',
    this.workspaceTitle = 'Admin Console',
    this.workspaceIcon = Icons.admin_panel_settings_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showSearch = width >= 980;
    final showProfileText = width >= 720;
    final isDesktop = width >= 1024;
    final showWorkspaceSelector = isDesktop && width >= 1200;

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
          if (showWorkspaceSelector) ...[
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(workspaceIcon, size: 18, color: OpsColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    workspaceTitle,
                    style: TextStyle(
                      color: OpsColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
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
                  hintText: 'Search users, devices, sites...',
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
          PopupMenuButton<int>(
            tooltip: 'Notifications',
            constraints: const BoxConstraints(minWidth: 320, maxWidth: 380),
            itemBuilder: (context) {
              if (notifications.isEmpty) {
                return const [
                  PopupMenuItem<int>(
                    enabled: false,
                    child: OpsEmptyState(
                      title: 'No notifications',
                      message:
                          'There are no unresolved alerts in the platform.',
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
                    trailing: Text(
                      _timeLabel(item.time),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: OpsColors.muted,
                          ),
                    ),
                  ),
                );
              }).toList();
            },
            child: Stack(
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: OpsColors.text,
                  size: isDesktop ? 23 : 20,
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
              if (value == 'settings') onSettingsTap();
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

  String _timeLabel(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }
}
