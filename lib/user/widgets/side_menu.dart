import 'package:flutter/material.dart';

import '../../core/theme/ops_theme.dart';
import '../../super_admin/core/responsive/responsive_extensions.dart';

class UserSideMenu extends StatelessWidget {
  final Animation<double> animation;
  final bool isOpen;
  final String currentView;
  final ValueChanged<String> onViewChanged;
  final VoidCallback onClose;
  final VoidCallback onLogout;
  final bool showCloseButton;

  const UserSideMenu({
    super.key,
    required this.animation,
    required this.isOpen,
    required this.currentView,
    required this.onViewChanged,
    required this.onClose,
    required this.onLogout,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final menuWidth =
        context.narrowerThan(420) ? context.screenWidth * .88 : 264.0;

    return IgnorePointer(
      ignoring: !isOpen,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(-menuWidth * (1 - animation.value), 0),
            child: child,
          );
        },
        child: Container(
          width: menuWidth,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: OpsColors.surfaceLow,
            border: Border(right: BorderSide(color: OpsColors.border)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 16, 24),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: OpsColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'L&T',
                            style: TextStyle(
                              fontSize: 22,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              color: OpsColors.text,
                            ),
                          ),
                          Text(
                            'SENSOR ANALYTICS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: OpsColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showCloseButton)
                      IconButton(
                        tooltip: 'Close menu',
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const _MenuSectionTitle('Main Menu'),
                    _MenuItem(
                      label: 'Dashboard',
                      icon: Icons.dashboard_rounded,
                      view: 'dashboard',
                      currentView: currentView,
                      onViewChanged: onViewChanged,
                    ),
                    _MenuItem(
                      label: 'Sites',
                      icon: Icons.location_on_outlined,
                      view: 'sites',
                      currentView: currentView,
                      onViewChanged: onViewChanged,
                      enabled: false,
                    ),
                    _MenuItem(
                      label: 'Sensors',
                      icon: Icons.sensors_outlined,
                      view: 'sensors',
                      currentView: currentView,
                      onViewChanged: onViewChanged,
                      enabled: false,
                    ),
                    _MenuItem(
                      label: 'Alerts',
                      icon: Icons.notifications_active_rounded,
                      view: 'alerts',
                      currentView: currentView,
                      onViewChanged: onViewChanged,
                      badgeValue: '12',
                    ),
                    _MenuItem(
                      label: 'Analytics',
                      icon: Icons.leaderboard_rounded,
                      view: 'analytics',
                      currentView: currentView,
                      onViewChanged: onViewChanged,
                    ),
                    _MenuItem(
                      label: 'Reports',
                      icon: Icons.description_outlined,
                      view: 'reports',
                      currentView: currentView,
                      onViewChanged: onViewChanged,
                      enabled: false,
                    ),
                    _MenuItem(
                      label: 'Documents',
                      icon: Icons.folder_outlined,
                      view: 'documents',
                      currentView: currentView,
                      onViewChanged: onViewChanged,
                      enabled: false,
                    ),
                    _MenuItem(
                      label: 'Integrations',
                      icon: Icons.extension_outlined,
                      view: 'integrations',
                      currentView: currentView,
                      onViewChanged: onViewChanged,
                      enabled: false,
                    ),
                    _MenuItem(
                      label: 'Settings',
                      icon: Icons.settings_rounded,
                      view: 'settings',
                      currentView: currentView,
                      onViewChanged: onViewChanged,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: InkWell(
                  onTap: showCloseButton ? onClose : null,
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chevron_left_rounded,
                          size: 22,
                          color: OpsColors.muted,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Collapse',
                          style: TextStyle(
                            color: OpsColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: OpsColors.surfaceHigh,
                  border: Border(top: BorderSide(color: OpsColors.border)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: OpsColors.primaryContainer,
                      child: Text(
                        'JS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'JS',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: OpsColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'SITE OPERATOR - L&T',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: OpsColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Logout',
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_rounded, size: 19),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuSectionTitle extends StatelessWidget {
  final String label;

  const _MenuSectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: OpsColors.outline,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final String view;
  final String currentView;
  final ValueChanged<String> onViewChanged;
  final String? badgeValue;
  final bool enabled;

  const _MenuItem({
    required this.label,
    required this.icon,
    required this.view,
    required this.currentView,
    required this.onViewChanged,
    this.badgeValue,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && currentView == view;
    final foreground = active
        ? Colors.white
        : enabled
            ? OpsColors.muted
            : OpsColors.muted.withValues(alpha: .92);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: enabled ? () => onViewChanged(view) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: active ? OpsColors.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: foreground,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
              ),
              if (badgeValue != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: active ? Colors.white : OpsColors.danger,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeValue!,
                    style: TextStyle(
                      color: active ? OpsColors.danger : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
