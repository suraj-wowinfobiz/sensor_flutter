import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/app_session.dart';
import '../../core/theme/ops_theme.dart';
import '../../super_admin/core/responsive/responsive_extensions.dart';
import '../providers/user_riverpod_provider.dart';
import '../widgets/nav_bar.dart';
import '../widgets/side_menu.dart';
import 'alerts_screen.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';

class UserScreen extends ConsumerStatefulWidget {
  const UserScreen({super.key});

  @override
  ConsumerState<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends ConsumerState<UserScreen>
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
      final db = ref.read(userDatabaseChangeNotifierProvider);
      try {
        await Future.wait([
          db.loadDevices(),
          db.loadSensors(),
          db.loadAlerts(),
        ]);
      } catch (_) {
        // Keep UI responsive even if one endpoint fails during bootstrap.
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
    AppSession.logoutToLanding(context);
  }

  void _setCurrentView(String view) {
    final normalized = _normalizeView(view);
    if (_currentView == normalized) return;
    if (normalized == 'alerts') {
      ref.read(userDatabaseChangeNotifierProvider).loadAlerts();
    }
    setState(() => _currentView = normalized);
    if (!context.isDesktopLayout) closeMenu();
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

  List<UserNotificationItem> _notifications() {
    final db = ref.read(userDatabaseChangeNotifierProvider);
    final items = db.alerts.where((a) => !a.isResolved).toList()
      ..sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
    return items
        .take(8)
        .map(
          (a) => UserNotificationItem(
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
    final navBar = UserNavBar(
      onMenuToggle: toggleMenu,
      isMenuOpen: _isMenuOpen,
      showMenuButton: false,
      onTopSettingsTap: () => _setCurrentView('settings'),
      onLogoutTap: _logout,
      currentView: _currentView,
      notifications: notifications,
      hasNotifications: hasNotifications,
    );

    return Scaffold(
      backgroundColor: OpsColors.background,
      body: SafeArea(
        child: NotificationListener<UserScrollNotification>(
          onNotification: _onScroll,
          child: isDesktop
              ? Row(
                  children: [
                    UserSideMenu(
                      animation: const AlwaysStoppedAnimation<double>(1.0),
                      isOpen: true,
                      currentView: _currentView,
                      onViewChanged: _setCurrentView,
                      onClose: closeMenu,
                      onLogout: _logout,
                      showCloseButton: false,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          navBar,
                          Expanded(child: _buildContent(_currentView)),
                        ],
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _showTopNav
                              ? UserNavBar(
                                  key: const ValueKey('mobile-user-nav'),
                                  onMenuToggle: toggleMenu,
                                  isMenuOpen: _isMenuOpen,
                                  showMenuButton: true,
                                  onTopSettingsTap: () =>
                                      _setCurrentView('settings'),
                                  onLogoutTap: _logout,
                                  currentView: _currentView,
                                  notifications: notifications,
                                  hasNotifications: hasNotifications,
                                )
                              : const SizedBox.shrink(),
                        ),
                        Expanded(child: _buildContent(_currentView)),
                      ],
                    ),
                    if (_isMenuOpen)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: closeMenu,
                          child: Container(
                            color: Colors.black.withValues(alpha: .24),
                          ),
                        ),
                      ),
                    UserSideMenu(
                      animation: _menuController,
                      isOpen: _isMenuOpen,
                      currentView: _currentView,
                      onViewChanged: _setCurrentView,
                      onClose: closeMenu,
                      onLogout: _logout,
                    ),
                  ],
                ),
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
                      key: const ValueKey('user-bottom-nav-visible'),
                      child: _buildBottomNav(
                        currentView: _currentView,
                        onViewChanged: _setCurrentView,
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('user-bottom-nav-hidden'),
                    ),
            ),
    );
  }

  Widget _buildBottomNav({
    required String currentView,
    required ValueChanged<String> onViewChanged,
  }) {
    const views = ['dashboard', 'alerts', 'analytics', 'settings'];
    final index = views.indexOf(currentView);
    return Container(
      decoration: const BoxDecoration(
        color: OpsColors.surface,
        border: Border(top: BorderSide(color: OpsColors.border)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: NavigationBar(
          height: 64,
          selectedIndex: index < 0 ? 0 : index,
          backgroundColor: OpsColors.surface,
          indicatorColor: OpsColors.primary.withValues(alpha: .10),
          onDestinationSelected: (i) => onViewChanged(views[i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.warning_amber_outlined),
              selectedIcon: Icon(Icons.warning_amber_rounded),
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeView(String view) {
    switch (view) {
      case 'config':
        return 'settings';
      case 'settings':
        return 'settings';
      default:
        return view;
    }
  }

  Widget _buildView(String view) {
    switch (view) {
      case 'dashboard':
        return const UserDashboardScreen();
      case 'alerts':
        return const UserAlertsScreen();
      case 'analytics':
        return const UserAnalyticsScreen();
      case 'settings':
        return const UserSettingsScreen();
      default:
        return const UserDashboardScreen();
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
              key: PageStorageKey<String>('user_$openedView'),
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
