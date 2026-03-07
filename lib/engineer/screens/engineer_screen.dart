import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../super_admin/core/responsive/responsive_extensions.dart';
import '../providers/engineer_riverpod_provider.dart';
import '../widgets/nav_bar.dart';
import '../widgets/side_menu.dart';
import 'alerts_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'dashboard_screen.dart';
import 'devices_screen.dart';
import 'engineer_login_screen.dart';
import 'sensors_screen.dart';

class EngineerScreen extends ConsumerStatefulWidget {
  const EngineerScreen({super.key});

  @override
  ConsumerState<EngineerScreen> createState() => _EngineerScreenState();
}

class _EngineerScreenState extends ConsumerState<EngineerScreen>
    with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  String _currentView = 'dashboard';
  bool _showTopNav = true;
  bool _showBottomNav = true;
  final List<String> _openedViews = ['dashboard'];
  late AnimationController _menuController;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final db = ref.read(engineerDatabaseChangeNotifierProvider);
      try {
        await db.loadOrganizations();
        await db.loadSites();
        await Future.wait([
          db.loadDevices(),
          db.loadSensors(),
        ]);
      } catch (_) {
        // Keep UI usable even if one API endpoint fails.
      }
    });
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
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EngineerLoginScreen()),
      (route) => false,
    );
  }

  void _setCurrentView(String view) {
    final normalized = _normalizeView(view);
    if (_currentView == normalized) return;
    if (normalized == 'devices') {
      final db = ref.read(engineerDatabaseChangeNotifierProvider);
      db.loadOrganizations();
      db.loadSites();
      db.loadDevices();
    } else if (normalized == 'sensors') {
      final db = ref.read(engineerDatabaseChangeNotifierProvider);
      db.loadDevices();
      db.loadSensors();
    } else if (normalized == 'alerts') {
      ref.read(engineerDatabaseChangeNotifierProvider).loadAlerts();
    }
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

  List<EngineerNotificationItem> _notifications() {
    final db = ref.read(engineerDatabaseChangeNotifierProvider);
    final items = db.alerts.where((a) => !a.isResolved).toList()
      ..sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
    return items
        .take(8)
        .map(
          (a) => EngineerNotificationItem(
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
    final navBar = EngineerNavBar(
      onMenuToggle: toggleMenu,
      isMenuOpen: _isMenuOpen,
      showMenuButton: false,
      onUserMenuSettingsTap: () => _setCurrentView('settings'),
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
                  : const SizedBox.shrink(key: ValueKey('hidden-engineer-nav')),
            ),
            Expanded(
              child: NotificationListener<UserScrollNotification>(
                onNotification: _onScroll,
                child: isDesktop
                    ? Row(
                        children: [
                          EngineerSideMenu(
                            animation:
                                const AlwaysStoppedAnimation<double>(1.0),
                            isOpen: true,
                            currentView: _currentView,
                            onViewChanged: _setCurrentView,
                            onClose: () {},
                            onLogout: _logout,
                            showCloseButton: false,
                          ),
                          Expanded(child: _buildContent(_currentView)),
                        ],
                      )
                    : _buildContent(_currentView),
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
                      key: const ValueKey('engineer-bottom-nav-visible'),
                      child: _buildBottomNav(
                        currentView: _currentView,
                        onViewChanged: _setCurrentView,
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('engineer-bottom-nav-hidden'),
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
      'settings',
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
      case 'config':
        return 'settings';
      default:
        return view;
    }
  }

  Widget _buildView(String view) {
    switch (view) {
      case 'dashboard':
        return const EngineerDashboardScreen();
      case 'devices':
        return const EngineerDevicesScreen();
      case 'sensors':
        return const EngineerSensorsScreen();
      case 'alerts':
        return const EngineerAlertsScreen();
      case 'analytics':
        return const EngineerAnalyticsScreen();
      case 'settings':
        return const EngineerSettingsScreen();
      default:
        return const EngineerDashboardScreen();
    }
  }

  Widget _buildContent(String view) {
    final normalized = _normalizeView(view);
    if (!_openedViews.contains(normalized)) {
      _openedViews.add(normalized);
    }
    return IndexedStack(
      index: _openedViews.indexOf(normalized),
      children: _openedViews
          .map(
            (openedView) => KeyedSubtree(
              key: PageStorageKey<String>('engineer_$openedView'),
              child: _buildView(openedView),
            ),
          )
          .toList(),
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }
}
