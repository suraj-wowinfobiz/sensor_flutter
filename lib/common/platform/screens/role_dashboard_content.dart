import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/theme/ops_theme.dart';
import '../providers/super_admin_riverpod_provider.dart';

class RoleDashboardContent extends ConsumerWidget {
  const RoleDashboardContent({
    super.key,
    required this.role,
  });

  final AppLoginRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final activeAlerts = db.alerts.where((alert) => !alert.isResolved).length;
    final activeDevices = db.devices.where((device) {
      final status = device.status.trim().toLowerCase();
      return status == 'active' ||
          status == 'online' ||
          status == 'healthy' ||
          status == 'running';
    }).length;

    return OpsPage(
      title: '${role.label} Dashboard',
      subtitle: _subtitleFor(role),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1080;
              final itemWidth = compact
                  ? constraints.maxWidth
                  : constraints.maxWidth / 3 - 12;
              final cards = _cardsForRole(
                role: role,
                activeAlerts: activeAlerts,
                activeDevices: activeDevices,
                organizations: db.organizations.length,
                sites: db.sites.length,
                users: db.users.length,
                sensors: db.sensors.length,
                devices: db.devices.length,
              );

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: cards
                    .map(
                      (card) => SizedBox(
                        width: itemWidth,
                        child: OpsKpiCard(
                          label: card.label,
                          value: card.value,
                          helper: card.helper,
                          icon: card.icon,
                          color: card.color,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 1080;
              final primaryPanel = OpsPanel(
                title: _primaryPanelTitle(role),
                subtitle: 'Role-specific priorities',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _highlightsFor(role)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _HighlightTile(
                            title: item.title,
                            body: item.body,
                            icon: item.icon,
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
              final secondaryPanel = OpsPanel(
                title: 'Operational Snapshot',
                subtitle: 'Live shared platform data',
                child: _SnapshotList(
                  items: [
                    _SnapshotItem('Active alerts', '$activeAlerts'),
                    _SnapshotItem(
                        'Organizations', '${db.organizations.length}'),
                    _SnapshotItem('Sites', '${db.sites.length}'),
                    _SnapshotItem('Zones', '${db.zones.length}'),
                    _SnapshotItem('Users', '${db.users.length}'),
                  ],
                ),
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    primaryPanel,
                    const SizedBox(height: 16),
                    secondaryPanel,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: primaryPanel,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: secondaryPanel,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          OpsPanel(
            title: 'Recommended Next Steps',
            subtitle: 'Start here after login',
            child: db.organizations.isEmpty &&
                    db.devices.isEmpty &&
                    db.sensors.isEmpty
                ? const OpsEmptyState(
                    title: 'No platform records loaded yet',
                    message:
                        'Once live data is available, this role dashboard will surface recent activity and role-specific work queues.',
                  )
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _actionsFor(role)
                        .map(
                          (action) => Container(
                            width: 280,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: OpsColors.surfaceLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: OpsColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  action.icon,
                                  color: OpsColors.primaryContainer,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  action.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: OpsColors.text,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  action.body,
                                  style: const TextStyle(
                                    color: OpsColors.muted,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

String _subtitleFor(AppLoginRole role) {
  switch (role) {
    case AppLoginRole.user:
      return 'Sensor-first monitoring for day-to-day site awareness.';
    case AppLoginRole.userAdmin:
      return 'Access, people, and organization management in one workspace.';
    case AppLoginRole.engineer:
      return 'Device health, sensor readiness, and engineering operations.';
    case AppLoginRole.vendor:
      return 'Customer operations, mapped sites, and vendor-facing visibility.';
    case AppLoginRole.analytics:
      return 'Signal quality, trends, and reporting performance.';
    case AppLoginRole.analyticsRole:
      return 'Assigned analytics views and performance signal review.';
    case AppLoginRole.admin:
      return 'Platform-wide monitoring and configuration.';
  }
}

String _primaryPanelTitle(AppLoginRole role) {
  switch (role) {
    case AppLoginRole.user:
      return 'Monitoring Focus';
    case AppLoginRole.userAdmin:
      return 'Management Focus';
    case AppLoginRole.engineer:
      return 'Engineering Focus';
    case AppLoginRole.vendor:
      return 'Vendor Focus';
    case AppLoginRole.analytics:
    case AppLoginRole.analyticsRole:
      return 'Analytics Focus';
    case AppLoginRole.admin:
      return 'Platform Focus';
  }
}

List<_RoleCard> _cardsForRole({
  required AppLoginRole role,
  required int activeAlerts,
  required int activeDevices,
  required int organizations,
  required int sites,
  required int users,
  required int sensors,
  required int devices,
}) {
  switch (role) {
    case AppLoginRole.user:
      return [
        _RoleCard(
            'Sensors Online',
            '$sensors',
            'Sensors visible in your workspace',
            Icons.sensors,
            OpsColors.primary),
        _RoleCard(
            'Active Alerts',
            '$activeAlerts',
            'Open conditions needing review',
            Icons.warning_amber_rounded,
            OpsColors.warning),
        _RoleCard('Live Sites', '$sites', 'Sites currently tracked',
            Icons.location_city_outlined, OpsColors.success),
      ];
    case AppLoginRole.userAdmin:
      return [
        _RoleCard(
            'Managed Users',
            '$users',
            'Accounts available in the platform',
            Icons.people_outline_rounded,
            OpsColors.primary),
        _RoleCard(
            'Organizations',
            '$organizations',
            'Organizations under management',
            Icons.business_outlined,
            OpsColors.success),
        _RoleCard('Open Alerts', '$activeAlerts', 'Operational issues to route',
            Icons.notifications_active_outlined, OpsColors.warning),
      ];
    case AppLoginRole.engineer:
      return [
        _RoleCard(
            'Devices Online',
            '$activeDevices',
            'Healthy devices reporting status',
            Icons.memory_outlined,
            OpsColors.primary),
        _RoleCard(
            'Sensors Configured',
            '$sensors',
            'Sensors attached to field devices',
            Icons.sensors_outlined,
            OpsColors.success),
        _RoleCard(
            'Engineering Alerts',
            '$activeAlerts',
            'Conditions impacting operations',
            Icons.build_circle_outlined,
            OpsColors.warning),
      ];
    case AppLoginRole.vendor:
      return [
        _RoleCard(
            'Customer Users',
            '$users',
            'Users visible to vendor operations',
            Icons.group_outlined,
            OpsColors.primary),
        _RoleCard(
            'Mapped Sites',
            '$sites',
            'Sites available in vendor coverage',
            Icons.map_outlined,
            OpsColors.success),
        _RoleCard(
            'Organizations',
            '$organizations',
            'Managed customer organizations',
            Icons.domain_outlined,
            OpsColors.warning),
      ];
    case AppLoginRole.analytics:
    case AppLoginRole.analyticsRole:
      return [
        _RoleCard(
            'Analytics Signals',
            '$sensors',
            'Sensors contributing to analysis',
            Icons.analytics_outlined,
            OpsColors.primary),
        _RoleCard(
            'Tracked Alerts',
            '$activeAlerts',
            'Alert load for investigation',
            Icons.query_stats_outlined,
            OpsColors.warning),
        _RoleCard(
            'Report Scope',
            '$devices',
            'Devices contributing to reporting',
            Icons.assessment_outlined,
            OpsColors.success),
      ];
    case AppLoginRole.admin:
      return [
        _RoleCard(
            'Organizations',
            '$organizations',
            'Platform-wide organization count',
            Icons.business_outlined,
            OpsColors.primary),
        _RoleCard('Users', '$users', 'Accounts on the platform',
            Icons.people_outline_rounded, OpsColors.success),
        _RoleCard('Devices', '$devices', 'Connected platform devices',
            Icons.devices_other_outlined, OpsColors.warning),
      ];
  }
}

List<_RoleTextItem> _highlightsFor(AppLoginRole role) {
  switch (role) {
    case AppLoginRole.user:
      return const [
        _RoleTextItem(
            'Watch active sensors',
            'Review the latest sensor fleet status and focus first on any anomaly-producing units.',
            Icons.sensors_outlined),
        _RoleTextItem(
            'Clear alert backlog',
            'Use alerts and analytics together to understand what changed at the site today.',
            Icons.warning_amber_outlined),
        _RoleTextItem(
            'Track site health',
            'Stay focused on operational awareness instead of administrative workflows.',
            Icons.monitor_heart_outlined),
      ];
    case AppLoginRole.userAdmin:
      return const [
        _RoleTextItem(
            'Review user access',
            'Check who has access, what role they hold, and whether their account scope still matches operations.',
            Icons.manage_accounts_outlined),
        _RoleTextItem(
            'Maintain organization structure',
            'Keep organization records current so downstream dashboards and assignments stay clean.',
            Icons.account_tree_outlined),
        _RoleTextItem(
            'Coordinate escalations',
            'Use alerts and analytics as inputs for admin decisions rather than direct field operations.',
            Icons.alt_route_outlined),
      ];
    case AppLoginRole.engineer:
      return const [
        _RoleTextItem(
            'Validate device readiness',
            'Focus on devices, linked sensors, and communication health before reviewing deeper analytics.',
            Icons.devices_other_outlined),
        _RoleTextItem(
            'Inspect sensor setup',
            'Use sensor lists to verify mappings, channel assignments, and readiness for live ingestion.',
            Icons.settings_input_component_outlined),
        _RoleTextItem(
            'Resolve engineering issues',
            'Treat alerts as engineering diagnostics tied to field hardware and configuration quality.',
            Icons.engineering_outlined),
      ];
    case AppLoginRole.vendor:
      return const [
        _RoleTextItem(
            'Monitor customer footprint',
            'Keep an eye on organizations and site presence to understand vendor operational coverage.',
            Icons.storefront_outlined),
        _RoleTextItem(
            'Use map visibility',
            'Mapped sites give a fast way to understand deployment spread and where support pressure may rise.',
            Icons.map_outlined),
        _RoleTextItem(
            'Coordinate vendor-facing accounts',
            'Track users and analytics signals that affect service quality for customer teams.',
            Icons.handshake_outlined),
      ];
    case AppLoginRole.analytics:
    case AppLoginRole.analyticsRole:
      return const [
        _RoleTextItem(
            'Review signal quality',
            'Focus on alert patterns, sensor contribution, and device coverage before producing conclusions.',
            Icons.insights_outlined),
        _RoleTextItem(
            'Correlate changes',
            'Use dashboard and reports together to find trend shifts across recent site activity.',
            Icons.timeline_outlined),
        _RoleTextItem(
            'Prepare decision support',
            'Your dashboard should help explain what is happening, why it matters, and where to drill next.',
            Icons.fact_check_outlined),
      ];
    case AppLoginRole.admin:
      return const [
        _RoleTextItem(
            'Coordinate the full platform',
            'See the whole operational picture across organizations, users, devices, and sensor health.',
            Icons.dashboard_customize_outlined),
      ];
  }
}

List<_RoleTextItem> _actionsFor(AppLoginRole role) {
  switch (role) {
    case AppLoginRole.user:
      return const [
        _RoleTextItem(
            'Open Sensors',
            'Start with the sensor list to check field visibility and latest hardware state.',
            Icons.sensors_outlined),
        _RoleTextItem(
            'Review Alerts',
            'Work through active alerts before spending time in deeper analytics views.',
            Icons.notifications_none_rounded),
        _RoleTextItem(
            'Analyze Trends',
            'Use analytics after you identify the affected sensors or locations.',
            Icons.analytics_outlined),
      ];
    case AppLoginRole.userAdmin:
      return const [
        _RoleTextItem(
            'Audit User Access',
            'Review user records and make sure the role mix still reflects operations.',
            Icons.people_outline_rounded),
        _RoleTextItem(
            'Update Organizations',
            'Keep organization and site ownership structure current.',
            Icons.business_outlined),
        _RoleTextItem(
            'Track Alert Routing',
            'Confirm active alerts are being seen by the right people.',
            Icons.campaign_outlined),
      ];
    case AppLoginRole.engineer:
      return const [
        _RoleTextItem(
            'Check Devices',
            'Start with device health and connectivity before editing sensor setup.',
            Icons.devices_other_outlined),
        _RoleTextItem(
            'Review Sensor Mapping',
            'Confirm sensor-to-device relationships and configuration integrity.',
            Icons.sensors_outlined),
        _RoleTextItem(
            'Investigate Alerts',
            'Use alerts as diagnostics for hardware, thresholds, and field readiness.',
            Icons.build_outlined),
      ];
    case AppLoginRole.vendor:
      return const [
        _RoleTextItem(
            'Review Customers',
            'Check organizations and user footprint for active vendor accounts.',
            Icons.groups_outlined),
        _RoleTextItem(
            'Open Map View',
            'Use map visibility to understand deployment spread and support load.',
            Icons.map_outlined),
        _RoleTextItem(
            'Inspect Analytics',
            'Watch signal and site performance trends that impact service quality.',
            Icons.analytics_outlined),
      ];
    case AppLoginRole.analytics:
    case AppLoginRole.analyticsRole:
      return const [
        _RoleTextItem(
            'Open Analytics',
            'Start where signal behavior and trend summaries are most visible.',
            Icons.insights_outlined),
        _RoleTextItem(
            'Review Reports',
            'Translate observed behavior into shareable summaries for other teams.',
            Icons.assessment_outlined),
        _RoleTextItem(
            'Correlate Alerts',
            'Use alert sequences to frame deeper analysis and prioritization.',
            Icons.notification_important_outlined),
      ];
    case AppLoginRole.admin:
      return const [
        _RoleTextItem(
            'Open Platform Dashboard',
            'Use the full shared dashboard to manage cross-role operations.',
            Icons.admin_panel_settings_outlined),
      ];
  }
}

class _RoleCard {
  const _RoleCard(this.label, this.value, this.helper, this.icon, this.color);

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;
}

class _RoleTextItem {
  const _RoleTextItem(this.title, this.body, this.icon);

  final String title;
  final String body;
  final IconData icon;
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: OpsColors.primary.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: OpsColors.primaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: OpsColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  color: OpsColors.muted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SnapshotItem {
  const _SnapshotItem(this.label, this.value);

  final String label;
  final String value;
}

class _SnapshotList extends StatelessWidget {
  const _SnapshotList({required this.items});

  final List<_SnapshotItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: OpsColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    item.value,
                    style: const TextStyle(
                      color: OpsColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
