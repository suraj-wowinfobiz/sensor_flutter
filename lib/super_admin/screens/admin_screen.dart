import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/app_session.dart';
import '../core/responsive/responsive_extensions.dart';
import '../providers/super_admin_riverpod_provider.dart';
import '../widgets/nav_bar.dart';
import '../widgets/side_menu.dart';
import 'alerts_screen.dart';
import 'analytics_screen.dart';
import 'audit_screen.dart';
import 'config_screen.dart';
import 'dashboard_screen.dart';
import 'devices_screen.dart';
import 'organizations_screen.dart';
import 'reports_screen.dart';
import 'sensors_screen.dart';
import 'users_screen.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  String _currentView = 'dashboard';
  bool _showTopNav = true;
  bool _showBottomNav = true;
  late AnimationController _menuController;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _menuController.forward();
      } else {
        _menuController.reverse();
      }
    });
  }

  void closeMenu() {
    if (_isMenuOpen) {
      setState(() {
        _isMenuOpen = false;
        _menuController.reverse();
      });
    }
  }

  void _logout() {
    AppSession.logoutToLanding(context);
  }

  void _setCurrentView(String view) {
    final normalized = _normalizeView(view);
    if (_currentView == normalized) return;
    setState(() => _currentView = normalized);
  }

  bool _onScroll(UserScrollNotification notification) {
    if (context.isDesktopLayout) return false;
    if (notification.direction == ScrollDirection.reverse) {
      if (_showTopNav || _showBottomNav) {
        setState(() {
          _showTopNav = false;
          _showBottomNav = false;
        });
      }
    } else if (notification.direction == ScrollDirection.forward) {
      if (!_showTopNav || !_showBottomNav) {
        setState(() {
          _showTopNav = true;
          _showBottomNav = true;
        });
      }
    }
    return false;
  }

  List<AdminNotificationItem> _notifications() {
    final db = ref.read(superAdminBackendChangeNotifierProvider);
    final items = db.alerts.where((a) => !a.isResolved).toList()
      ..sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
    return items
        .take(8)
        .map(
          (a) => AdminNotificationItem(
            title: a.alertLevel.toUpperCase(),
            message: a.message,
            time: a.triggeredAt,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktopLayout;
    final notifications = _notifications();
    final hasNotifications = notifications.isNotEmpty;
    final navBar = NavBar(
      onMenuToggle: toggleMenu,
      isMenuOpen: _isMenuOpen,
      showMenuButton: false,
      onSettingsTap: () => _setCurrentView('config'),
      onLogoutTap: _logout,
      notifications: notifications,
      hasNotifications: hasNotifications,
    );

    final scaffold = Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutQuart,
              switchOutCurve: Curves.easeInQuart,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0, -0.08),
                  end: Offset.zero,
                ).animate(animation);
                return SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  ),
                );
              },
              child: (isDesktop || _showTopNav)
                  ? navBar
                  : const SizedBox.shrink(key: ValueKey('hidden-admin-nav')),
            ),
            Expanded(
              child: NotificationListener<UserScrollNotification>(
                onNotification: _onScroll,
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SideMenu(
                            animation:
                                const AlwaysStoppedAnimation<double>(1.0),
                            isOpen: true,
                            currentView: _currentView,
                            onViewChanged: _setCurrentView,
                            onClose: () {},
                            onLogout: _logout,
                            showCloseButton: false,
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: _buildContent(_currentView),
                            ),
                          ),
                        ],
                      )
                    : Align(
                        alignment: Alignment.topLeft,
                        child: _buildContent(_currentView),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutQuart,
              switchOutCurve: Curves.easeInQuart,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(animation);
                return SizeTransition(
                  sizeFactor: animation,
                  axis: Axis.vertical,
                  axisAlignment: -1,
                  child: FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  ),
                );
              },
              child: _showBottomNav
                  ? KeyedSubtree(
                      key: const ValueKey('admin-bottom-nav-visible'),
                      child: _buildBottomNav(
                        currentView: _currentView,
                        onViewChanged: _setCurrentView,
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('admin-bottom-nav-hidden'),
                    ),
            ),
    );

    return scaffold;
  }

  Widget _buildBottomNav({
    required String currentView,
    required ValueChanged<String> onViewChanged,
  }) {
    const views = [
      'dashboard',
      'devices',
      'sensors',
      'alerts',
      'analytics',
      'config',
    ];
    final index = views.indexOf(currentView);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final selectedColor = Theme.of(context).colorScheme.primary;
    final unselectedColor =
        isLight ? const Color(0xFF6D7E89) : const Color(0xFF9CB0C0);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.18),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            backgroundColor:
                isLight ? const Color(0xFFF7FAFC) : const Color(0xFF1E3446),
            selectedItemColor: selectedColor,
            unselectedItemColor: unselectedColor,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            currentIndex: index < 0 ? 0 : index,
            onTap: (i) => onViewChanged(views[i]),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.devices_other_outlined),
                activeIcon: Icon(Icons.devices_other),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sensors_outlined),
                activeIcon: Icon(Icons.sensors),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.warning_amber_outlined),
                activeIcon: Icon(Icons.warning_amber_rounded),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined),
                activeIcon: Icon(Icons.analytics),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: '',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _normalizeView(String view) {
    switch (view) {
      case 'organization':
        return 'organizations';
      default:
        return view;
    }
  }

  Widget _buildView(String view) {
    switch (view) {
      case 'dashboard':
        return const DashboardScreen();
      case 'users':
        return const UsersScreen();
      case 'organizations':
        return const OrganizationsScreen();
      case 'devices':
        return const DevicesScreen();
      case 'sensors':
        return const SensorsScreen();
      case 'alerts':
        return const AlertsScreen();
      case 'analytics':
        return const AnalyticsScreen();
      case 'reports':
        return const ReportsScreen();
      case 'audit':
        return const AuditScreen();
      case 'config':
        return const ConfigScreen();
      default:
        return const DashboardScreen();
    }
  }

  Widget _buildContent(String view) {
    final normalized = _normalizeView(view);
    return KeyedSubtree(
      key: PageStorageKey<String>('admin_$normalized'),
      child: _buildView(normalized),
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }
}
