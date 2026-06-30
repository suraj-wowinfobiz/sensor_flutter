import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/auth/app_session.dart';
import '../../../core/theme/ops_theme.dart';
import '../api/alerts_api.dart';
import '../core/responsive/responsive_extensions.dart';
import '../providers/super_admin_riverpod_provider.dart';
import '../widgets/nav_bar.dart';
import '../widgets/side_menu.dart';
import 'alerts_screen.dart';
import 'analytics_screen.dart';
import 'audit_screen.dart';
import 'config_screen.dart';
import 'devices_screen.dart';
import 'live_analytics_screen.dart';
import 'map_screen.dart';
import 'organizations_screen.dart';
import 'reports_screen.dart';
import 'sensors_screen.dart';
import 'users_screen.dart';
import '../../pages/dashboard/role_dashboard_screen.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({
    super.key,
    this.role = AppLoginRole.admin,
  });

  final AppLoginRole role;

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  String _currentView = 'dashboard';
  bool _showTopNav = true;
  bool _showBottomNav = true;
  final PageStorageBucket _pageStorageBucket = PageStorageBucket();
  late AnimationController _menuController;
  String _profileName = '';
  String _profileInitial = '';
  String _profileSubtitle = '';

  List<RoleNavigationItem> get _navigationItems => widget.role.navigationItems;
  Set<String> get _allowedViews =>
      _navigationItems.map((item) => item.view).toSet();

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _loadSessionProfile();
      await _warmViewData(_currentView);
    });
  }

  Future<void> _warmViewData(String view) async {
    final db = ref.read(superAdminBackendChangeNotifierProvider);
    final resolved = _normalizeView(view);
    final tasks = <Future<void>>[];

    switch (resolved) {
      case 'dashboard':
        switch (widget.role) {
          case AppLoginRole.admin:
            tasks.addAll([
              db.loadOrganizations(),
              db.loadDevices(),
              db.loadUsers(),
            ]);
            tasks.add(db.loadOrganizations().then((_) => db.loadSites()));
            break;
          case AppLoginRole.userAdmin:
            tasks.addAll([
              db.loadOrganizations(),
              db.loadUsers(),
            ]);
            tasks.add(db.loadOrganizations().then((_) => db.loadSites()));
            break;
          case AppLoginRole.user:
            tasks.addAll([
              db.loadSensors(),
              db.loadDevices(),
            ]);
            break;
          case AppLoginRole.engineer:
            tasks.addAll([
              db.loadDevices(),
              db.loadSensors(),
            ]);
            break;
          case AppLoginRole.vendor:
            tasks.addAll([
              db.loadOrganizations(),
              db.loadUsers(),
            ]);
            tasks.add(db.loadOrganizations().then((_) => db.loadSites()));
            break;
          case AppLoginRole.analytics:
          case AppLoginRole.analyticsRole:
            tasks.addAll([
              db.loadSensors(),
              db.loadDevices(),
              db.loadThresholdValues(),
            ]);
            break;
        }
        tasks.add(_refreshAlerts());
        break;
      case 'organizations':
      case 'map':
        tasks.addAll([
          db.loadOrganizations(),
        ]);
        tasks.add(db.loadOrganizations().then((_) => db.loadSites()));
        break;
      case 'users':
        tasks.addAll([
          db.loadOrganizations(),
          db.loadDevices(),
          db.loadSensors(),
          db.loadUsers(),
        ]);
        tasks.add(db.loadOrganizations().then((_) => db.loadSites()));
        break;
      case 'devices':
        tasks.addAll([
          db.loadOrganizations(),
          db.loadDevices(),
        ]);
        tasks.add(db.loadOrganizations().then((_) => db.loadSites()));
        break;
      case 'sensors':
        tasks.addAll([
          db.loadDevices(),
          db.loadSensors(),
          db.loadSensorTypes(),
        ]);
        break;
      case 'alerts':
        tasks.addAll([
          db.loadThresholdValues(),
          db.loadSensorTypes(),
          db.loadSensorParameters(),
          _refreshAlerts(),
        ]);
        break;
      case 'analytics':
      case 'liveAnalytics':
        tasks.addAll([
          db.loadSensors(),
          db.loadDevices(),
          db.loadThresholdValues(),
        ]);
        break;
      default:
        break;
    }

    try {
      await Future.wait(tasks);
    } catch (_) {
      // Keep the shell responsive even if one preload request fails.
    }
  }

  Future<void> _loadSessionProfile() async {
    final sessionData = await AppSession.getSessionData();
    final username = (sessionData['username'] ?? '').trim();
    final userId = (await AppSession.currentPrincipalId()).trim();
    final displayUserId = AppSession.toSixDigitUserId(userId);

    debugPrint('Loaded session userId: $displayUserId');
    debugPrint('Loaded session principalId: $userId');
    debugPrint('Loaded session username: $username');

    if (!mounted) return;

    if (username.isEmpty && displayUserId.isEmpty) {
      return;
    }

    final resolvedUsername =
        username.isNotEmpty ? username : widget.role.profileTitle;
    final displayName = displayUserId.isNotEmpty
        ? '$resolvedUsername ($displayUserId)'
        : resolvedUsername;
    final subtitle = widget.role.profileTitle;
    setState(() {
      _profileName = displayName;
      _profileSubtitle = subtitle;
      _profileInitial = _initialsFromName(displayName);
    });
  }

  String _initialsFromName(String value) {
    final parts = value
        .split(RegExp(r'[.\s_-]+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return widget.role.profileInitial;
    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
    final resolved =
        _allowedViews.contains(normalized) ? normalized : 'dashboard';
    if (_currentView == resolved) return;
    setState(() => _currentView = resolved);
    unawaited(_warmViewData(resolved));
    if (!context.isDesktopLayout) closeMenu();
  }

  Future<void> _refreshAlerts() async {
    try {
      final alerts = await AlertsApi.getAlerts();
      if (!mounted) return;
      ref.read(superAdminBackendChangeNotifierProvider).alerts = alerts;
      setState(() {});
    } catch (_) {
      // Alerts screen itself still owns full API error handling.
    }
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
      currentView: _currentView,
      notifications: notifications,
      hasNotifications: hasNotifications,
      workspaceTitle: widget.role.headerTitle,
      workspaceIcon: widget.role.icon,
      profileName:
          _profileName.isNotEmpty ? _profileName : widget.role.profileTitle,
      profileRole:
          _profileSubtitle.isNotEmpty ? _profileSubtitle : widget.role.profileTitle,
      profileInitial: _profileInitial.isNotEmpty
          ? _profileInitial
          : widget.role.profileInitial,
    );

    return Scaffold(
      backgroundColor: OpsColors.background,
      body: SafeArea(
        child: NotificationListener<UserScrollNotification>(
          onNotification: _onScroll,
          child: isDesktop
              ? Row(
                  children: [
                    SideMenu(
                      animation: const AlwaysStoppedAnimation<double>(1.0),
                      isOpen: true,
                      currentView: _currentView,
                      onViewChanged: _setCurrentView,
                      onClose: closeMenu,
                      onLogout: _logout,
                      role: widget.role,
                      items: _navigationItems,
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
                              ? NavBar(
                                  key: const ValueKey('mobile-admin-nav'),
                                  onMenuToggle: toggleMenu,
                                  isMenuOpen: _isMenuOpen,
                                  showMenuButton: true,
                                  onSettingsTap: () =>
                                      _setCurrentView('config'),
                                  onLogoutTap: _logout,
                                  currentView: _currentView,
                                  notifications: notifications,
                                  hasNotifications: hasNotifications,
                                  workspaceTitle: widget.role.headerTitle,
                                  workspaceIcon: widget.role.icon,
                                  profileName: _profileName.isNotEmpty
                                      ? _profileName
                                      : widget.role.profileTitle,
                                  profileRole: _profileSubtitle.isNotEmpty
                                      ? _profileSubtitle
                                      : widget.role.profileTitle,
                                  profileInitial: _profileInitial.isNotEmpty
                                      ? _profileInitial
                                      : widget.role.profileInitial,
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
                    SideMenu(
                      animation: _menuController,
                      isOpen: _isMenuOpen,
                      currentView: _currentView,
                      onViewChanged: _setCurrentView,
                      onClose: closeMenu,
                      onLogout: _logout,
                      role: widget.role,
                      items: _navigationItems,
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
  }

  Widget _buildBottomNav({
    required String currentView,
    required ValueChanged<String> onViewChanged,
  }) {
    final items = _navigationItems;
    final views = items.map((item) => item.view).toList();
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
          destinations: items
              .map(
                (item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.icon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String _normalizeView(String view) {
    switch (view) {
      case 'organization':
        return 'organizations';
      case 'settings':
        return 'config';
      default:
        return view;
    }
  }

  Widget _buildView(String view) {
    switch (view) {
      case 'dashboard':
        return RoleDashboardScreen(role: widget.role);
      case 'users':
        if (widget.role == AppLoginRole.userAdmin) {
          return const UsersScreen(
            createDefaultRole: 'user',
            selectableRoles: ['user'],
          );
        }
        return const UsersScreen(
          createDefaultRole: 'admin',
          selectableRoles: ['admin', 'vendor', 'vendor_engineer', 'user'],
        );
      case 'organizations':
        return const OrganizationsScreen();
      case 'map':
        return const MapScreen();
      case 'devices':
        return const DevicesScreen();
      case 'sensors':
        return const SensorsScreen();
      case 'alerts':
        return const AlertsScreen();
      case 'analytics':
        return const AnalyticsScreen();
      case 'liveAnalytics':
        return const LiveAnalyticsScreen();
      case 'reports':
        return const ReportsScreen();
      case 'audit':
        return const AuditScreen();
      case 'config':
        return ConfigScreen(role: widget.role);
      default:
        return RoleDashboardScreen(role: widget.role);
    }
  }

  Widget _buildContent(String view) {
    final normalized = _normalizeView(view);
    final resolved =
        _allowedViews.contains(normalized) ? normalized : 'dashboard';
    return PageStorage(
      bucket: _pageStorageBucket,
      child: KeyedSubtree(
        key: PageStorageKey<String>('admin_$resolved'),
        child: _buildView(resolved),
      ),
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }
}
