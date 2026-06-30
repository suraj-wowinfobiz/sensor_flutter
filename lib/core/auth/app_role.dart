import 'package:flutter/material.dart';

@immutable
class RoleNavigationItem {
  const RoleNavigationItem({
    required this.label,
    required this.icon,
    required this.view,
    this.badge,
  });

  final String label;
  final IconData icon;
  final String view;
  final String? badge;
}

enum AppLoginRole {
  user,
  userAdmin,
  engineer,
  vendor,
  analytics,
  analyticsRole,
  admin,
}

extension AppLoginRoleX on AppLoginRole {
  String get label {
    switch (this) {
      case AppLoginRole.user:
        return 'User';
      case AppLoginRole.userAdmin:
        return 'User Admin';
      case AppLoginRole.engineer:
        return 'Engineer';
      case AppLoginRole.vendor:
        return 'Vendor';
      case AppLoginRole.analytics:
        return 'Analytics';
      case AppLoginRole.analyticsRole:
        return 'Analytics Role';
      case AppLoginRole.admin:
        return 'Super Admin';
    }
  }

  String get description {
    switch (this) {
      case AppLoginRole.user:
        return 'Monitor sensors, devices, alerts, and live site activity.';
      case AppLoginRole.userAdmin:
        return 'Manage users, organizations, and operational access.';
      case AppLoginRole.engineer:
        return 'Configure devices, sensors, and engineering workflows.';
      case AppLoginRole.vendor:
        return 'Access vendor operations, customers, and support tools.';
      case AppLoginRole.analytics:
        return 'Review analytics dashboards and site performance trends.';
      case AppLoginRole.analyticsRole:
        return 'Review assigned analytics workspaces and performance signals.';
      case AppLoginRole.admin:
        return 'Control platform-wide configuration and administration.';
    }
  }

  String get emailHint {
    switch (this) {
      case AppLoginRole.user:
        return 'user@example.com';
      case AppLoginRole.userAdmin:
        return 'useradmin@example.com';
      case AppLoginRole.engineer:
        return 'engineer@example.com';
      case AppLoginRole.vendor:
        return 'vendor@example.com';
      case AppLoginRole.analytics:
        return 'analytics@example.com';
      case AppLoginRole.analyticsRole:
        return 'analytics-role@example.com';
      case AppLoginRole.admin:
        return 'admin@example.com';
    }
  }

  IconData get icon {
    switch (this) {
      case AppLoginRole.user:
        return Icons.person_outline;
      case AppLoginRole.userAdmin:
        return Icons.admin_panel_settings_outlined;
      case AppLoginRole.engineer:
        return Icons.engineering_outlined;
      case AppLoginRole.vendor:
        return Icons.storefront_outlined;
      case AppLoginRole.analytics:
        return Icons.insights_outlined;
      case AppLoginRole.analyticsRole:
        return Icons.query_stats_outlined;
      case AppLoginRole.admin:
        return Icons.security_outlined;
    }
  }

  String get principalKey {
    switch (this) {
      case AppLoginRole.user:
        return 'user_principal_id';
      case AppLoginRole.userAdmin:
        return 'user_admin_principal_id';
      case AppLoginRole.engineer:
        return 'engineer_principal_id';
      case AppLoginRole.vendor:
        return 'vendor_principal_id';
      case AppLoginRole.analytics:
        return 'analytics_principal_id';
      case AppLoginRole.analyticsRole:
        return 'analytics_role_principal_id';
      case AppLoginRole.admin:
        return 'admin_principal_id';
    }
  }

  String get loginRoleValue {
    switch (this) {
      case AppLoginRole.admin:
        return 'super_admin';
      case AppLoginRole.userAdmin:
        return 'admin';
      case AppLoginRole.engineer:
        return 'vendor_engineer';
      case AppLoginRole.analyticsRole:
        return 'analytics_role';
      case AppLoginRole.user:
        return 'user';
      case AppLoginRole.vendor:
        return 'vendor';
      case AppLoginRole.analytics:
        return 'analytics';
    }
  }

  String get sessionValue {
    switch (this) {
      case AppLoginRole.admin:
        return 'admin';
      default:
        return loginRoleValue;
    }
  }

  String get rememberValue => sessionValue;

  String get shellSubtitle {
    switch (this) {
      case AppLoginRole.admin:
        return 'Platform Console';
      default:
        return '$label Console';
    }
  }

  String get headerTitle {
    switch (this) {
      case AppLoginRole.admin:
        return 'Platform Console';
      default:
        return '$label Console';
    }
  }

  String get profileTitle {
    switch (this) {
      case AppLoginRole.admin:
        return 'Super Admin';
      default:
        return label;
    }
  }

  String get profileInitial {
    switch (this) {
      case AppLoginRole.user:
        return 'U';
      case AppLoginRole.userAdmin:
        return 'UA';
      case AppLoginRole.engineer:
        return 'EN';
      case AppLoginRole.vendor:
        return 'VE';
      case AppLoginRole.analytics:
        return 'AN';
      case AppLoginRole.analyticsRole:
        return 'AR';
      case AppLoginRole.admin:
        return 'PA';
    }
  }

  List<RoleNavigationItem> get navigationItems {
    switch (this) {
      case AppLoginRole.user:
        return const [
          RoleNavigationItem(
            label: 'Dashboard',
            icon: Icons.dashboard_rounded,
            view: 'dashboard',
          ),
          RoleNavigationItem(
            label: 'Sensors',
            icon: Icons.sensors_outlined,
            view: 'sensors',
          ),
          RoleNavigationItem(
            label: 'Alerts',
            icon: Icons.notifications_none_rounded,
            view: 'alerts',
            badge: 'Live',
          ),
          RoleNavigationItem(
            label: 'Analytics',
            icon: Icons.analytics_outlined,
            view: 'analytics',
          ),
          RoleNavigationItem(
            label: 'Settings',
            icon: Icons.settings_outlined,
            view: 'config',
          ),
        ];
      case AppLoginRole.userAdmin:
        return const [
          RoleNavigationItem(
            label: 'Dashboard',
            icon: Icons.dashboard_rounded,
            view: 'dashboard',
          ),
          RoleNavigationItem(
            label: 'Alerts',
            icon: Icons.notifications_none_rounded,
            view: 'alerts',
            badge: 'Live',
          ),
          RoleNavigationItem(
            label: 'Analytics',
            icon: Icons.analytics_outlined,
            view: 'analytics',
          ),
          RoleNavigationItem(
            label: 'Live Analytics',
            icon: Icons.monitor_heart_outlined,
            view: 'liveAnalytics',
            badge: 'Live',
          ),
          RoleNavigationItem(
            label: 'Users',
            icon: Icons.people_outline_rounded,
            view: 'users',
          ),
          RoleNavigationItem(
            label: 'Organizations',
            icon: Icons.business_outlined,
            view: 'organizations',
          ),
          RoleNavigationItem(
            label: 'Settings',
            icon: Icons.settings_outlined,
            view: 'config',
          ),
        ];
      case AppLoginRole.engineer:
        return const [
          RoleNavigationItem(
            label: 'Dashboard',
            icon: Icons.dashboard_rounded,
            view: 'dashboard',
          ),
          RoleNavigationItem(
            label: 'Devices',
            icon: Icons.devices_other_outlined,
            view: 'devices',
          ),
          RoleNavigationItem(
            label: 'Sensors',
            icon: Icons.sensors_outlined,
            view: 'sensors',
          ),
          RoleNavigationItem(
            label: 'Alerts',
            icon: Icons.notifications_none_rounded,
            view: 'alerts',
            badge: 'Live',
          ),
          RoleNavigationItem(
            label: 'Analytics',
            icon: Icons.analytics_outlined,
            view: 'analytics',
          ),
          RoleNavigationItem(
            label: 'Settings',
            icon: Icons.settings_outlined,
            view: 'config',
          ),
        ];
      case AppLoginRole.vendor:
        return const [
          RoleNavigationItem(
            label: 'Dashboard',
            icon: Icons.dashboard_rounded,
            view: 'dashboard',
          ),
          RoleNavigationItem(
            label: 'Users',
            icon: Icons.people_outline_rounded,
            view: 'users',
          ),
          RoleNavigationItem(
            label: 'Analytics',
            icon: Icons.analytics_outlined,
            view: 'analytics',
          ),
          RoleNavigationItem(
            label: 'Map',
            icon: Icons.map_outlined,
            view: 'map',
          ),
          RoleNavigationItem(
            label: 'Organizations',
            icon: Icons.business_outlined,
            view: 'organizations',
          ),
          RoleNavigationItem(
            label: 'Settings',
            icon: Icons.settings_outlined,
            view: 'config',
          ),
        ];
      case AppLoginRole.analytics:
      case AppLoginRole.analyticsRole:
        return const [
          RoleNavigationItem(
            label: 'Dashboard',
            icon: Icons.dashboard_rounded,
            view: 'dashboard',
          ),
          RoleNavigationItem(
            label: 'Alerts',
            icon: Icons.notifications_none_rounded,
            view: 'alerts',
            badge: 'Live',
          ),
          RoleNavigationItem(
            label: 'Analytics',
            icon: Icons.analytics_outlined,
            view: 'analytics',
          ),
          RoleNavigationItem(
            label: 'Live Analytics',
            icon: Icons.monitor_heart_outlined,
            view: 'liveAnalytics',
            badge: 'Live',
          ),
          RoleNavigationItem(
            label: 'Reports',
            icon: Icons.assessment_outlined,
            view: 'reports',
          ),
          RoleNavigationItem(
            label: 'Settings',
            icon: Icons.settings_outlined,
            view: 'config',
          ),
        ];
      case AppLoginRole.admin:
        return const [
          RoleNavigationItem(
            label: 'Dashboard',
            icon: Icons.dashboard_rounded,
            view: 'dashboard',
          ),
          RoleNavigationItem(
            label: 'Devices',
            icon: Icons.devices_other_outlined,
            view: 'devices',
          ),
          RoleNavigationItem(
            label: 'Sensors',
            icon: Icons.sensors_outlined,
            view: 'sensors',
          ),
          RoleNavigationItem(
            label: 'Alerts',
            icon: Icons.notifications_none_rounded,
            view: 'alerts',
            badge: 'Live',
          ),
          RoleNavigationItem(
            label: 'Users',
            icon: Icons.people_outline_rounded,
            view: 'users',
          ),
          RoleNavigationItem(
            label: 'Organizations',
            icon: Icons.business_outlined,
            view: 'organizations',
          ),
          RoleNavigationItem(
            label: 'Analytics',
            icon: Icons.analytics_outlined,
            view: 'analytics',
          ),
          RoleNavigationItem(
            label: 'Reports',
            icon: Icons.assessment_outlined,
            view: 'reports',
          ),
          RoleNavigationItem(
            label: 'Audit',
            icon: Icons.fact_check_outlined,
            view: 'audit',
          ),
          RoleNavigationItem(
            label: 'Settings',
            icon: Icons.settings_outlined,
            view: 'config',
          ),
        ];
    }
  }
}
