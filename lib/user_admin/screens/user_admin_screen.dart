import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_admin_database_provider.dart';
import '../widgets/nav_bar.dart';
import '../widgets/side_menu.dart';
import 'alerts_screen.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'organizations_screen.dart';
import 'settings_screen.dart';
import 'users_screen.dart';

class UserAdminScreen extends StatefulWidget {
  const UserAdminScreen({super.key});

  @override
  State<UserAdminScreen> createState() => _UserAdminScreenState();
}

class _UserAdminScreenState extends State<UserAdminScreen>
    with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  bool _dragActive = false;
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

  @override
  Widget build(BuildContext context) {
    return Consumer<UserAdminDatabaseProvider>(
      builder: (context, db, child) {
        final isDesktop = MediaQuery.of(context).size.width >= 1100;

        if (isDesktop && _isMenuOpen) {
          _isMenuOpen = false;
          _menuController.value = 0;
        }

        final body = _buildMainContent(
          context: context,
          db: db,
          showMenuButton: !isDesktop,
        );

        if (isDesktop) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Row(
                children: [
                  UserAdminSideMenu(
                    animation: const AlwaysStoppedAnimation<double>(1.0),
                    isOpen: true,
                    currentView: db.currentView,
                    onViewChanged: db.setCurrentView,
                    onClose: () {},
                    showCloseButton: false,
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          );
        }

        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: SafeArea(child: body),
              ),
            ),
            if (_isMenuOpen)
              GestureDetector(
                onTap: closeMenu,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: Colors.black
                      .withValues(alpha: 0.28 * _menuAnimation.value),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 2 * _menuAnimation.value,
                      sigmaY: 2 * _menuAnimation.value,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            UserAdminSideMenu(
              animation: _menuAnimation,
              isOpen: _isMenuOpen,
              currentView: db.currentView,
              onViewChanged: (view) {
                db.setCurrentView(view);
                closeMenu();
              },
              onClose: closeMenu,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainContent({
    required BuildContext context,
    required UserAdminDatabaseProvider db,
    required bool showMenuButton,
  }) {
    final navBar = UserAdminNavBar(
      onMenuToggle: toggleMenu,
      isMenuOpen: _isMenuOpen,
      showMenuButton: showMenuButton,
    );

    if (db.currentView == 'dashboard') {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            navBar,
            const UserAdminDashboardScreen(embeddedScroll: true),
          ],
        ),
      );
    }

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(child: navBar),
        ];
      },
      body: _buildContent(db.currentView),
    );
  }

  Widget _buildContent(String view) {
    switch (view) {
      case 'dashboard':
        return const UserAdminDashboardScreen();
      case 'alerts':
        return const UserAdminAlertsScreen();
      case 'analytics':
        return const UserAdminAnalyticsScreen();
      case 'user':
      case 'users':
        return const UserAdminUsersScreen();
      case 'organization':
      case 'organizations':
        return const UserAdminOrganizationsScreen();
      case 'settings':
      case 'config':
        return const UserAdminSettingsScreen();
      default:
        return const UserAdminDashboardScreen();
    }
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }
}
