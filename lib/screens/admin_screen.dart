import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/database_provider.dart';
import '../shared/widgets/notifications_popup.dart';
import '../widgets/nav_bar.dart';
import '../widgets/side_menu.dart';
import 'alerts_screen.dart';
import 'analytics_screen.dart';
import 'audit_screen.dart';
import 'config_screen.dart';
import 'dashboard_screen.dart';
import 'devices_screen.dart';
import 'login_screen.dart';
import 'organizations_screen.dart';
import 'reports_screen.dart';
import 'sensors_screen.dart';
import 'thresholds_screen.dart';
import 'users_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  bool _dragActive = false;
  String _currentView = 'dashboard';
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
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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

  List<AppNotificationItem> _notifications() {
    final db = context.read<DatabaseProvider>();
    final items = db.alerts.where((a) => !a.isResolved).toList()
      ..sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
    return items
        .take(8)
        .map(
          (a) => AppNotificationItem(
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
    final navBar = NavBar(
      onMenuToggle: toggleMenu,
      isMenuOpen: _isMenuOpen,
      showMenuButton: !isDesktop,
      onSettingsTap: () => _setCurrentView('config'),
      notifications: notifications,
      hasNotifications: hasNotifications,
    );

    final scaffold = Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            navBar,
            Expanded(
              child: isDesktop
                  ? Row(
                      children: [
                        SideMenu(
                          animation: const AlwaysStoppedAnimation<double>(1.0),
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
          ],
        ),
      ),
      bottomNavigationBar: isDesktop
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
        SideMenu(
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
    const views = ['dashboard', 'devices', 'sensors', 'alerts', 'config'];
    final index = views.indexOf(currentView);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: index < 0 ? 0 : index,
      onTap: (i) => onViewChanged(views[i]),
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Devices'),
        BottomNavigationBarItem(icon: Icon(Icons.sensors), label: 'Sensors'),
        BottomNavigationBarItem(
            icon: Icon(Icons.notifications), label: 'Alerts'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
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
      case 'thresholds':
        return const ThresholdsScreen();
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
    if (!_openedViews.contains(normalized)) {
      _openedViews.add(normalized);
    }
    return IndexedStack(
      index: _openedViews.indexOf(normalized),
      children: _openedViews
          .map(
            (openedView) => KeyedSubtree(
              key: PageStorageKey<String>('admin_$openedView'),
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
