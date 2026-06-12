import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/ops_theme.dart';
import '../providers/user_database_provider.dart';

class UserAnalyticsScreen extends StatefulWidget {
  const UserAnalyticsScreen({super.key});

  @override
  State<UserAnalyticsScreen> createState() => _UserAnalyticsScreenState();
}

class _UserAnalyticsScreenState extends State<UserAnalyticsScreen> {
  String _range = '7d';
  String _scope = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDatabaseProvider>(
      builder: (context, db, child) {
        final activeDevices =
            db.devices.where((d) => d.status == 'active').length;
        final uptime = db.devices.isEmpty
            ? '96.4%'
            : '${((activeDevices / db.devices.length) * 100).toStringAsFixed(1)}%';
        final alertCount = db.alerts.where((a) => !a.isResolved).length;

        return OpsPage(
          title: 'Analytics',
          subtitle:
              'Review trends, alert patterns, sensor stability, and site performance across monitored construction environments',
          actions: [
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String>(
                initialValue: _range,
                decoration: const InputDecoration(labelText: 'Date Range'),
                items: const [
                  DropdownMenuItem(value: '24h', child: Text('Last 24 Hours')),
                  DropdownMenuItem(value: '7d', child: Text('Last 7 Days')),
                  DropdownMenuItem(value: '30d', child: Text('Last 30 Days')),
                ],
                onChanged: (value) => setState(() => _range = value ?? '7d'),
              ),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                initialValue: _scope,
                decoration: const InputDecoration(labelText: 'Comparison'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Sites')),
                  DropdownMenuItem(value: 'single', child: Text('Single Site')),
                  DropdownMenuItem(value: 'multi', child: Text('Multi-site')),
                ],
                onChanged: (value) => setState(() => _scope = value ?? 'all'),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Generate Report'),
            ),
          ],
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final count = constraints.maxWidth >= 1160
                      ? 6
                      : constraints.maxWidth >= 760
                          ? 3
                          : 1;
                  final cards = [
                    const OpsKpiCard(
                      label: 'Site Health Score',
                      value: '84 / 100',
                      helper: 'Reporting health and alert load',
                      icon: Icons.health_and_safety_outlined,
                    ),
                    OpsKpiCard(
                      label: 'Alert Frequency',
                      value: '${alertCount == 0 ? 32 : alertCount}',
                      helper: 'Total alerts in selected period',
                      icon: Icons.notifications_active_rounded,
                      color: OpsColors.danger,
                    ),
                    const OpsKpiCard(
                      label: 'Sensor Stability',
                      value: '88%',
                      helper: 'Stable reporting across sensors',
                      icon: Icons.sensors_rounded,
                      color: OpsColors.success,
                    ),
                    OpsKpiCard(
                      label: 'Device Uptime',
                      value: uptime,
                      helper: 'Across all monitored devices',
                      icon: Icons.router_rounded,
                      color: OpsColors.success,
                    ),
                    const OpsKpiCard(
                      label: 'Breach Rate',
                      value: '11%',
                      helper: 'Readings outside safe range',
                      icon: Icons.stacked_line_chart_rounded,
                      color: OpsColors.warning,
                    ),
                    const OpsKpiCard(
                      label: 'Highest Risk Site',
                      value: 'East Metro',
                      helper: 'Requires operational review',
                      icon: Icons.location_on_outlined,
                      color: OpsColors.warning,
                    ),
                  ];
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: count,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: count == 1 ? 96 : 104,
                    ),
                    itemBuilder: (context, index) => cards[index],
                  );
                },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final vertical = constraints.maxWidth < 1100;
                  const performance = OpsPanel(
                    title: 'Site Performance Overview',
                    subtitle:
                        'Health score derived from reporting consistency, alert load, threshold compliance, and device availability',
                    child: _SitePerformanceTable(),
                  );
                  const findings = OpsPanel(
                    title: 'Key Findings',
                    subtitle: 'Operational insights for the selected range',
                    child: _KeyFindings(),
                  );
                  if (vertical) {
                    return const Column(
                      children: [
                        performance,
                        SizedBox(height: 16),
                        findings,
                      ],
                    );
                  }
                  return const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: performance),
                      SizedBox(width: 16),
                      Expanded(flex: 5, child: findings),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final vertical = constraints.maxWidth < 1100;
                  const alertTrend = OpsPanel(
                    title: 'Alert Trend Analysis',
                    subtitle: 'Volume by category and severity',
                    child: _AlertTrendContent(),
                  );
                  const stability = OpsPanel(
                    title: 'Sensor Stability Analysis',
                    subtitle:
                        'Unstable, drifting, or repeatedly breached sensors',
                    child: _SensorStabilityTable(),
                  );
                  if (vertical) {
                    return const Column(
                      children: [
                        alertTrend,
                        SizedBox(height: 16),
                        stability,
                      ],
                    );
                  }
                  return const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: alertTrend),
                      SizedBox(width: 16),
                      Expanded(child: stability),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              const OpsPanel(
                title: 'Recommendations',
                subtitle:
                    'Suggested follow-up actions based on breach clusters and reliability patterns',
                child: _Recommendations(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SitePerformanceTable extends StatelessWidget {
  const _SitePerformanceTable();

  @override
  Widget build(BuildContext context) {
    const rows = [
      (
        'Tower A Redevelopment',
        '91',
        '24',
        '98.2%',
        '2',
        '3',
        '1.1 min',
        'Low'
      ),
      ('East Metro Segment', '68', '31', '90.7%', '5', '12', '4.8 min', 'High'),
      ('Riverside Expansion', '88', '19', '97.4%', '1', '2', '1.4 min', 'Low'),
      (
        'Industrial Block C',
        '74',
        '22',
        '92.1%',
        '3',
        '7',
        '3.2 min',
        'Medium'
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('SITE')),
          DataColumn(label: Text('HEALTH')),
          DataColumn(label: Text('SENSORS')),
          DataColumn(label: Text('UPTIME')),
          DataColumn(label: Text('ALERTS')),
          DataColumn(label: Text('BREACHES')),
          DataColumn(label: Text('AVG DELAY')),
          DataColumn(label: Text('RISK')),
        ],
        rows: rows.map((row) {
          return DataRow(cells: [
            DataCell(Text(row.$1)),
            DataCell(Text(row.$2)),
            DataCell(Text(row.$3)),
            DataCell(Text(row.$4)),
            DataCell(Text(row.$5)),
            DataCell(Text(row.$6)),
            DataCell(Text(row.$7)),
            DataCell(OpsStatusBadge(row.$8)),
          ]);
        }).toList(),
      ),
    );
  }
}

class _KeyFindings extends StatelessWidget {
  const _KeyFindings();

  @override
  Widget build(BuildContext context) {
    const findings = [
      'East Metro Segment is the highest-risk site this week due to repeated vibration breaches and unstable gateway reporting.',
      'Gateway D-14 and Sensor V-118 appear in multiple risk patterns and should be reviewed together.',
      'Sensor uptime remains strong overall, but tunnel-zone reporting consistency is declining.',
      'Most sites remain stable, with risk concentrated in a small number of devices and sensors.',
    ];

    return Column(
      children: findings.map((finding) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading:
              const Icon(Icons.insights_outlined, color: OpsColors.primary),
          title: Text(finding),
        );
      }).toList(),
    );
  }
}

class _AlertTrendContent extends StatelessWidget {
  const _AlertTrendContent();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Threshold exceeded', 46, OpsColors.danger),
      ('Device offline', 28, OpsColors.warning),
      ('Abnormal vibration', 18, OpsColors.warning),
      ('Temperature spike', 8, OpsColors.primary),
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Expanded(child: Text(row.$1)),
              SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: row.$2 / 100,
                  color: row.$3,
                  backgroundColor: OpsColors.surfaceHigh,
                ),
              ),
              const SizedBox(width: 12),
              Text('${row.$2}%'),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SensorStabilityTable extends StatelessWidget {
  const _SensorStabilityTable();

  @override
  Widget build(BuildContext context) {
    const rows = [
      (
        'Vibration Sensor V-118',
        'Vibration',
        '61',
        '7',
        'Rising variability',
        'High'
      ),
      ('Tilt Sensor T-301', 'Tilt', '42', '5', 'Missing data', 'High'),
      (
        'Temperature Sensor TMP-77',
        'Temperature',
        '66',
        '4',
        'Elevated trend',
        'Medium'
      ),
    ];

    return Column(
      children: rows.map((row) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title:
              Text(row.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${row.$2} - Stability ${row.$3} - ${row.$5}'),
          trailing: OpsStatusBadge(row.$6),
        );
      }).toList(),
    );
  }
}

class _Recommendations extends StatelessWidget {
  const _Recommendations();

  @override
  Widget build(BuildContext context) {
    const items = [
      'Inspect devices with repeated communication delays.',
      'Review vibration threshold profiles for high-noise zones.',
      'Prioritize calibration checks for sensors with unstable trend behavior.',
      'Investigate zones with rising alert density.',
      'Escalate repeated critical breaches with unresolved status.',
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) {
        return Container(
          width: 320,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: OpsColors.surfaceLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: OpsColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.task_alt_rounded, color: OpsColors.success),
              const SizedBox(width: 10),
              Expanded(child: Text(item)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
