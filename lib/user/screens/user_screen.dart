import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../providers/user_database_provider.dart';
import '../widgets/nav_bar.dart';
import '../widgets/side_menu.dart';
import 'alerts_screen.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'devices_screen.dart';
import 'user_login_screen.dart';
import 'sidebar_settings_screen.dart';
import 'sensors_screen.dart';
import 'settings_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen>
    with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  bool _dragActive = false;
  String _currentView = 'dashboard';
  bool _showBottomNav = true;
  final List<String> _openedViews = ['dashboard'];
  late AnimationController _menuController;
  late Animation<double> _menuAnimation;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeInOut,
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
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserLoginScreen()),
      (route) => false,
    );
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragActive = _isMenuOpen || details.globalPosition.dx <= 28;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_dragActive) return;
    final delta = details.primaryDelta ?? 0;
    if (!_isMenuOpen && delta > 0) {
      setState(() => _isMenuOpen = true);
    }
    final value = (_menuController.value + (delta / 320)).clamp(0.0, 1.0);
    _menuController.value = value;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_dragActive) return;
    _dragActive = false;
    final velocity = details.primaryVelocity ?? 0;
    final shouldOpen = velocity > 250 || _menuController.value > 0.35;
    setState(() => _isMenuOpen = shouldOpen);
    if (shouldOpen) {
      _menuController.forward();
    } else {
      _menuController.reverse();
    }
  }

  void _setCurrentView(String view) {
    final normalized = _normalizeView(view);
    if (_currentView == normalized) return;
    setState(() => _currentView = normalized);
  }

  bool _onScroll(UserScrollNotification notification) {
    if (MediaQuery.of(context).size.width >= 1100) return false;

    if (notification.direction == ScrollDirection.reverse) {
      if (_showBottomNav) {
        setState(() {
          _showBottomNav = false;
        });
      }
    } else if (notification.direction == ScrollDirection.forward) {
      if (!_showBottomNav) {
        setState(() {
          _showBottomNav = true;
        });
      }
    }
    return false;
  }

  List<UserNotificationItem> _notifications() {
    final db = context.read<UserDatabaseProvider>();
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
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final notifications = _notifications();
    final hasNotifications = notifications.isNotEmpty;
    final navBar = UserNavBar(
      onMenuToggle: toggleMenu,
      isMenuOpen: _isMenuOpen,
      showMenuButton: false,
      onTopSettingsTap: () => _setCurrentView('topbar_settings'),
      onLogoutTap: _logout,
      notifications: notifications,
      hasNotifications: hasNotifications,
    );

    final scaffold = Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            if (isDesktop) navBar,
            Expanded(
              child: NotificationListener<UserScrollNotification>(
                onNotification: _onScroll,
                child: isDesktop
                    ? Row(
                        children: [
                          UserSideMenu(
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
      bottomNavigationBar: isDesktop || !_showBottomNav
          ? null
          : _buildBottomNav(
              currentView: _currentView,
              onViewChanged: _setCurrentView,
            ),
    );

    if (isDesktop) return scaffold;

    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _onHorizontalDragStart,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: scaffold,
        ),
        if (_isMenuOpen)
          GestureDetector(
            onTap: closeMenu,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color:
                  Colors.black.withValues(alpha: 0.24 * _menuAnimation.value),
              child: const SizedBox.expand(),
            ),
          ),
        UserSideMenu(
          animation: _menuAnimation,
          isOpen: _isMenuOpen,
          currentView: _currentView,
          onViewChanged: (view) {
            _setCurrentView(view);
            closeMenu();
          },
          onClose: closeMenu,
          onLogout: _logout,
        ),
      ],
    );
  }

  Widget _buildBottomNav({
    required String currentView,
    required ValueChanged<String> onViewChanged,
  }) {
    const views = ['dashboard', 'alerts', 'analytics', 'topbar_settings'];
    final effectiveView =
        currentView == 'menu_settings' ? 'topbar_settings' : currentView;
    final index = views.indexOf(effectiveView);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: index < 0 ? 0 : index,
      onTap: (i) => onViewChanged(views[i]),
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(
            icon: Icon(Icons.notifications), label: 'Alerts'),
        BottomNavigationBarItem(
            icon: Icon(Icons.analytics), label: 'Analytics'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }

  String _normalizeView(String view) {
    switch (view) {
      case 'config':
        return 'topbar_settings';
      case 'settings':
        return 'topbar_settings';
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
      case 'devices':
        return const UserDevicesScreen();
      case 'sensors':
        return const UserSensorsScreen();
      case 'topbar_settings':
        return const UserSettingsScreen();
      case 'menu_settings':
        return const UserSidebarSettingsScreen();
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
