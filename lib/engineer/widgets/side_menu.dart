import 'package:flutter/material.dart';

import '../../core/theme/ops_theme.dart';
import '../../super_admin/core/responsive/responsive_extensions.dart';

class EngineerSideMenu extends StatelessWidget {
  static const double desktopWidth = 284;
  static const double desktopHeaderHeight = 78;

  final Animation<double> animation;
  final bool isOpen;
  final String currentView;
  final ValueChanged<String> onViewChanged;
  final VoidCallback onClose;
  final VoidCallback onLogout;
  final bool showCloseButton;

  const EngineerSideMenu({
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
        context.narrowerThan(420) ? context.screenWidth * 0.88 : desktopWidth;

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
            border: Border(
              right: BorderSide(color: OpsColors.border),
            ),
          ),
          child: Column(
            children: [
              Container(
                height: desktopHeaderHeight,
                padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: OpsColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: OpsColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.engineering_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WowGardian',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.0,
                              fontWeight: FontWeight.w800,
                              color: OpsColors.text,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Engineer Console',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.0,
                              fontWeight: FontWeight.w600,
                              color: OpsColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showCloseButton) const SizedBox(width: 8),
                    if (showCloseButton)
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: OpsColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: OpsColors.border),
                          ),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  children: [
                    _buildMenuSection(context, [
                      _buildMenuItem(context, 'Dashboard',
                          Icons.dashboard_rounded, 'dashboard'),
                      _buildMenuItem(context, 'Devices',
                          Icons.devices_other_outlined, 'devices'),
                      _buildMenuItem(context, 'Sensors', Icons.sensors_outlined,
                          'sensors'),
                      _buildMenuItem(context, 'Alerts',
                          Icons.notifications_none_rounded, 'alerts',
                          badge: 'Live'),
                      _buildMenuItem(context, 'Analytics',
                          Icons.analytics_outlined, 'analytics'),
                      _buildMenuItem(context, 'Settings',
                          Icons.settings_outlined, 'settings'),
                    ]),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                child: GestureDetector(
                  onTap: onLogout,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0FE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: OpsColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: OpsColors.muted,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 13,
                            color: OpsColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (showCloseButton)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 18, 18),
                  child: GestureDetector(
                    onTap: onClose,
                    child: const Row(
                      children: [
                        Icon(
                          Icons.chevron_left_rounded,
                          size: 20,
                          color: OpsColors.muted,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Collapse',
                          style: TextStyle(
                            fontSize: 13,
                            color: OpsColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    String view, {
    String? badge,
  }) {
    final isActive = currentView == view;
    const inactiveIconColor = Color(0xFF53627A);
    const inactiveTextColor = Color(0xFF53627A);
    final iconColor = isActive ? Colors.white : inactiveIconColor;
    final textColor = isActive ? Colors.white : inactiveTextColor;

    return GestureDetector(
      onTap: () => onViewChanged(view),
      child: Container(
        height: 56,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? OpsColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 21,
              color: iconColor,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  decoration: TextDecoration.none,
                  color: textColor,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : OpsColors.danger,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isActive ? OpsColors.danger : Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
