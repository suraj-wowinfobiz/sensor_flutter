import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;

import '../../core/auth/app_session.dart';
import '../../core/theme/ops_theme.dart';
import '../../super_admin/core/responsive/responsive_extensions.dart';
import '../../super_admin/core/theme/custom_theme_tokens.dart';
import '../../super_admin/providers/super_admin_backend_provider.dart';
import '../../super_admin/screens/analytics_screen.dart';
import '../../super_admin/screens/organizations_screen.dart';
import '../../super_admin/screens/users_screen.dart';
import '../../user/widgets/nav_bar.dart';
import '../providers/vendor_riverpod_provider.dart';
import 'dashboard_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

class VendorScreen extends ConsumerStatefulWidget {
  const VendorScreen({super.key});

  @override
  ConsumerState<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends ConsumerState<VendorScreen>
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

  void _logout() {
    AppSession.logoutToLanding(context);
  }

  void closeMenu() {
    if (_isMenuOpen) {
      setState(() {
        _isMenuOpen = false;
        _menuController.reverse();
      });
    }
  }

  void _setCurrentView(String view) {
    final normalized = _normalizeView(view);
    if (_currentView == normalized) return;
    if (normalized == 'users') {
      _loadUsersPageData();
    }
    if (normalized == 'organizations') {
      _loadOrganizationsPageData();
    }
    if (normalized == 'analytics') {
      final db = ref.read(vendorDatabaseChangeNotifierProvider);
      db.loadDevices();
      db.loadSensors();
      db.loadSensorTypes();
    }
    setState(() => _currentView = normalized);
    if (!context.isDesktopLayout) closeMenu();
  }

  Future<void> _loadUsersPageData() async {
    final db = ref.read(vendorDatabaseChangeNotifierProvider);
    try {
      await db.loadOrganizations();
      await db.loadSites();
      for (final site in db.sites) {
        await db.loadZones(site.id);
      }
      await db.loadUsers();
    } catch (_) {
      // Keep view navigation responsive even if API calls fail.
    }
  }

  Future<void> _loadOrganizationsPageData() async {
    final db = ref.read(vendorDatabaseChangeNotifierProvider);
    try {
      await db.loadOrganizations();
      await db.loadSites();
      for (final site in db.sites) {
        await db.loadZones(site.id);
      }
    } catch (_) {
      // Keep view navigation responsive even if API calls fail.
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

  List<UserNotificationItem> _notifications() {
    final db = ref.read(vendorDatabaseChangeNotifierProvider);
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
      notifications: notifications,
      hasNotifications: hasNotifications,
      profileName: 'vendor.operator',
      profileRole: 'Vendor',
      profileInitial: 'V',
    );

    final tokens = Theme.of(context).extension<CustomThemeTokens>()!;
    return Scaffold(
      backgroundColor: OpsColors.background,
      body: SafeArea(
        child: NotificationListener<UserScrollNotification>(
          onNotification: _onScroll,
          child: isDesktop
              ? Row(
                  children: [
                    _VendorSideMenu(
                      animation: const AlwaysStoppedAnimation<double>(1.0),
                      isOpen: true,
                      currentView: _currentView,
                      onViewChanged: _setCurrentView,
                      onClose: closeMenu,
                      onLogout: _logout,
                      showCloseButton: false,
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              tokens.softPanel.withValues(alpha: 0.34),
                              Theme.of(context).scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            navBar,
                            Expanded(child: _buildContent(_currentView)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            tokens.softPanel.withValues(alpha: 0.34),
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _showTopNav
                                ? UserNavBar(
                                    key: const ValueKey('mobile-vendor-nav'),
                                    onMenuToggle: toggleMenu,
                                    isMenuOpen: _isMenuOpen,
                                    showMenuButton: true,
                                    onTopSettingsTap: () =>
                                        _setCurrentView('settings'),
                                    onLogoutTap: _logout,
                                    notifications: notifications,
                                    hasNotifications: hasNotifications,
                                    profileName: 'vendor.operator',
                                    profileRole: 'Vendor',
                                    profileInitial: 'V',
                                  )
                                : const SizedBox.shrink(),
                          ),
                          Expanded(child: _buildContent(_currentView)),
                        ],
                      ),
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
                    _VendorSideMenu(
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
                      key: const ValueKey('vendor-bottom-nav-visible'),
                      child: _buildBottomNav(
                        currentView: _currentView,
                        onViewChanged: _setCurrentView,
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('vendor-bottom-nav-hidden'),
                    ),
            ),
    );
  }

  Widget _buildBottomNav({
    required String currentView,
    required ValueChanged<String> onViewChanged,
  }) {
    const views = [
      'dashboard',
      'users',
      'analytics',
      'map',
      'organizations',
      'settings'
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
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined),
                activeIcon: Icon(Icons.analytics),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.business_outlined),
                activeIcon: Icon(Icons.business),
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
      case 'settings':
        return 'settings';
      default:
        return view;
    }
  }

  Widget _buildView(String view) {
    switch (view) {
      case 'dashboard':
        return const VendorDashboardScreen();
      case 'users':
        final vendorDb = ref.read(vendorDatabaseChangeNotifierProvider);
        return p.ChangeNotifierProvider<SuperAdminBackendProvider>.value(
          value: vendorDb,
          child: const UsersScreen(
            createDefaultRole: 'Vendor_engineer',
            selectableRoles: ['Vendor_engineer'],
          ),
        );
      case 'analytics':
        return const AnalyticsScreen();
      case 'map':
        return const VendorMapScreen();
      case 'organizations':
        return const OrganizationsScreen();
      case 'settings':
        return const VendorSettingsScreen();
      default:
        return const VendorDashboardScreen();
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
              key: PageStorageKey<String>('vendor_$openedView'),
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

class _VendorSideMenu extends StatelessWidget {
  static const double desktopWidth = 284;
  static const double desktopHeaderHeight = 78;

  final Animation<double> animation;
  final bool isOpen;
  final String currentView;
  final ValueChanged<String> onViewChanged;
  final VoidCallback onClose;
  final VoidCallback onLogout;
  final bool showCloseButton;

  const _VendorSideMenu({
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
                        Icons.storefront_outlined,
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
                            'Vendor Console',
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
                      _buildMenuItem(context, 'Users',
                          Icons.people_outline_rounded, 'users'),
                      _buildMenuItem(context, 'Analytics',
                          Icons.analytics_outlined, 'analytics'),
                      _buildMenuItem(context, 'Map', Icons.map_outlined, 'map'),
                      _buildMenuItem(context, 'Organizations',
                          Icons.business_outlined, 'organizations'),
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
    String view,
  ) {
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
          ],
        ),
      ),
    );
  }
}
