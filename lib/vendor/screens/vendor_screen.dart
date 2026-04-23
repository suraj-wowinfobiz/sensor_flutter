import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;

import '../../core/auth/app_session.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
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
                    : const SizedBox.shrink(key: ValueKey('hidden-vendor-nav')),
              ),
              Expanded(
                child: NotificationListener<UserScrollNotification>(
                  onNotification: _onScroll,
                  child: isDesktop
                      ? Row(
                          children: [
                            _VendorSideMenu(
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final menuWidth =
        context.narrowerThan(420) ? context.screenWidth * 0.88 : 312.0;
    final panelColor = Color.alphaBlend(
      scheme.surface.withValues(alpha: isLight ? 0.94 : 0.98),
      theme.scaffoldBackgroundColor,
    );
    final softSurface = Color.alphaBlend(
      scheme.primary.withValues(alpha: isLight ? 0.08 : 0.16),
      theme.cardColor,
    );

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
            color: panelColor,
            border: Border(
              right: BorderSide(color: theme.dividerColor, width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    theme.shadowColor.withValues(alpha: isLight ? 0.1 : 0.22),
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
                    bottom: BorderSide(color: theme.dividerColor, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Vendor Panel',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
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
                            color: softSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.dividerColor),
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
                    _buildMenuItem(
                      context,
                      'Dashboard',
                      Icons.dashboard,
                      'dashboard',
                    ),
                    _buildMenuItem(
                      context,
                      'Users',
                      Icons.people_outline,
                      'users',
                    ),
                    _buildMenuItem(
                      context,
                      'Analytics',
                      Icons.analytics_outlined,
                      'analytics',
                    ),
                    _buildMenuItem(
                      context,
                      'Map',
                      Icons.map_outlined,
                      'map',
                    ),
                    _buildMenuItem(
                      context,
                      'Organizations',
                      Icons.business_outlined,
                      'organizations',
                    ),
                    _buildMenuItem(
                      context,
                      'Settings',
                      Icons.settings_applications,
                      'settings',
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.dividerColor, width: 1),
                  ),
                ),
                child: GestureDetector(
                  onTap: onLogout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: softSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          size: 16,
                          color: scheme.onSurface.withValues(alpha: 0.74),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: scheme.onSurface,
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

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    String view,
  ) {
    final scheme = Theme.of(context).colorScheme;
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
                  ? scheme.onPrimary
                  : scheme.onSurface.withValues(alpha: 0.72),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  decoration: TextDecoration.none,
                  color: isActive ? scheme.onPrimary : scheme.onSurface,
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
