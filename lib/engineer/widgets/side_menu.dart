import 'package:flutter/material.dart';

class EngineerSideMenu extends StatelessWidget {
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
    final menuWidth = MediaQuery.of(context).size.width < 420
        ? MediaQuery.of(context).size.width * 0.88
        : 312.0;

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
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white.withValues(alpha: 0.9)
                : const Color(0xFF1a3148).withValues(alpha: 0.95),
            border: Border(
              right:
                  BorderSide(color: Theme.of(context).dividerColor, width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: Theme.of(context).dividerColor, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.memory,
                        color: Theme.of(context).colorScheme.primary, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Engineer Panel',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFF1e3a5a)
                                  : const Color(0xFFc0d6f0),
                        ),
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
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? const Color(0xFFf0f5fd)
                                    : const Color(0xFF203a54),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Theme.of(context).dividerColor),
                          ),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    _buildMenuSection(context, 'Main', [
                      _buildMenuItem(
                          context, 'Dashboard', Icons.dashboard, 'dashboard'),
                      _buildMenuItem(
                          context, 'Devices', Icons.devices, 'devices'),
                      _buildMenuItem(
                          context, 'Sensors', Icons.sensors, 'sensors'),
                      _buildMenuItem(
                          context, 'Alerts', Icons.notifications, 'alerts'),
                      _buildMenuItem(
                          context, 'Analytics', Icons.analytics, 'analytics'),
                      _buildMenuItem(context, 'Settings',
                          Icons.settings_applications, 'settings'),
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
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFFf0f5fd)
                          : const Color(0xFF203a54),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          size: 16,
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFF4a6b8a)
                                  : const Color(0xFF8aaac9),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 12.5,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? const Color(0xFF1e3a5a)
                                    : const Color(0xFFc0d6f0),
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
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF4a6b8a)
                  : const Color(0xFF8aaac9),
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
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? Colors.white
                  : Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF4a6b8a)
                      : const Color(0xFF8aaac9),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  decoration: TextDecoration.none,
                  color: isActive
                      ? Colors.white
                      : Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFF1e3a5a)
                          : const Color(0xFFc0d6f0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
