import 'package:flutter/material.dart';
import '../../core/theme/ops_theme.dart';
import '../core/responsive/responsive_extensions.dart';

class SideMenu extends StatelessWidget {
  final Animation<double> animation;
  final bool isOpen;
  final String currentView;
  final ValueChanged<String> onViewChanged;
  final VoidCallback onClose;
  final VoidCallback onLogout;
  final bool showCloseButton;

  const SideMenu({
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
        context.narrowerThan(420) ? context.screenWidth * 0.88 : 240.0;

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
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: OpsColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: OpsColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.analytics_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'L&T',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: OpsColors.text,
                              height: 1,
                            ),
                          ),
                          Text(
                            'SENSOR ANALYTICS',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: OpsColors.muted,
                              letterSpacing: .3,
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
                            borderRadius: BorderRadius.circular(8),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    _buildMenuSection(context, 'Main Menu', [
                      _buildMenuItem(
                          context, 'Dashboard', Icons.dashboard, 'dashboard'),
                      _buildMenuItem(
                          context, 'Devices', Icons.devices, 'devices'),
                      _buildMenuItem(
                          context, 'Sensors', Icons.sensors, 'sensors'),
                      _buildMenuItem(
                          context, 'Alerts', Icons.notifications, 'alerts'),
                      _buildMenuItem(context, 'Users', Icons.people, 'users'),
                      _buildMenuItem(context, 'Organization', Icons.business,
                          'organizations'),
                      _buildMenuItem(context, 'Settings',
                          Icons.settings_applications, 'config'),
                    ]),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: Theme.of(context).dividerColor, width: 1),
                  ),
                ),
                child: GestureDetector(
                  onTap: onLogout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: OpsColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: OpsColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          size: 16,
                          color: OpsColors.muted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: OpsColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(
      BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
              color: OpsColors.outline,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildMenuItem(
      BuildContext context, String title, IconData icon, String view) {
    final isActive = currentView == view;

    return GestureDetector(
      onTap: () => onViewChanged(view),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? OpsColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : OpsColors.muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.none,
                  color: isActive ? Colors.white : OpsColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
