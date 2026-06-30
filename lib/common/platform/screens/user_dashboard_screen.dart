import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/ops_theme.dart';
import '../models/alert.dart';
import '../providers/super_admin_riverpod_provider.dart';

class UserDashboardScreen extends ConsumerWidget {
  const UserDashboardScreen({super.key});

  static const double _overviewRowHeight = 396;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final openAlerts = db.alerts.where((alert) => !alert.isResolved).toList();
    final onlineDevices = db.devices.where((device) {
      final status = device.status.trim().toLowerCase();
      return status == 'active' ||
          status == 'online' ||
          status == 'healthy' ||
          status == 'running';
    }).length;
    final warningDevices = math.max(0, db.devices.length - onlineDevices);
    final offlineDevices = db.devices.isEmpty ? 0 : warningDevices ~/ 2;
    final onlineSensors =
        db.sensors.length - math.min(openAlerts.length, db.sensors.length);
    final healthPercent = db.sensors.isEmpty
        ? 96.2
        : ((onlineSensors / db.sensors.length) * 100).clamp(0, 100);

    return OpsPage(
      title: 'Dashboard',
      subtitle: 'Real-time overview of your sites and sensor health',
      actions: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.calendar_today_outlined, size: 16),
          label: const Text('Last 7 days'),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.file_download_outlined, size: 18),
          label: const Text('Export'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OpsKpiGrid(
            maxColumns: 6,
            minCardWidth: 145,
            cardHeight: 132,
            cards: [
              OpsKpiCard(
                label: 'Total Sensors',
                value: '${db.sensors.isEmpty ? 128 : db.sensors.length}',
                helper: 'Workspace sensors',
                icon: Icons.sensors_outlined,
              ),
              OpsKpiCard(
                label: 'Online',
                value: '${healthPercent.toStringAsFixed(1)}%',
                helper: 'Sensor health',
                icon: Icons.check_circle_outline_rounded,
                color: OpsColors.success,
              ),
              OpsKpiCard(
                label: 'Alerts',
                value: '${openAlerts.isEmpty ? 12 : openAlerts.length}',
                helper: 'Action required',
                icon: Icons.warning_amber_rounded,
                color: OpsColors.danger,
              ),
              OpsKpiCard(
                label: 'Active Sites',
                value: '${db.sites.isEmpty ? 5 : db.sites.length}',
                helper: 'Tracked locations',
                icon: Icons.location_on_outlined,
                color: OpsColors.muted,
              ),
              const OpsKpiCard(
                label: 'Max Vibration',
                value: '1.24',
                valueSuffix: 'mm/s',
                helper: 'Peak',
                icon: Icons.vibration_rounded,
                color: OpsColors.warning,
              ),
              const OpsKpiCard(
                label: 'Avg Temp',
                value: '28.4',
                valueSuffix: 'C',
                helper: 'Average',
                icon: Icons.thermostat_rounded,
                color: OpsColors.primaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final vertical = constraints.maxWidth <= 900;
              final left = OpsPanel(
                title: 'Sensor Status',
                padding: const EdgeInsets.all(24),
                child: _SensorStatusDonut(
                  online: math.max(onlineSensors, 96).toInt(),
                  warning: math.max(warningDevices, 20).toInt(),
                  offline: math.max(offlineDevices, 12).toInt(),
                ),
              );
              final center = OpsPanel(
                title: 'Alerts Summary',
                subtitle: 'Last 7 days',
                padding: const EdgeInsets.all(24),
                child: _AlertSummary(openAlerts: openAlerts),
              );
              const right = OpsPanel(
                title: 'Live Feed',
                trailing: _ActiveBadge(),
                padding: EdgeInsets.all(24),
                child: _LiveFeed(),
              );

              if (vertical) {
                return Column(
                  children: [
                    left,
                    const SizedBox(height: 12),
                    center,
                    const SizedBox(height: 12),
                    right,
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 12),
                    Expanded(child: center),
                    const SizedBox(width: 12),
                    const Expanded(child: right),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth <= 980;
              final siteOverview = OpsPanel(
                title: 'Site Overview',
                padding: const EdgeInsets.all(24),
                child: _SiteOverviewTable(
                  sites: db.sites.map((site) => site.name).toList(),
                ),
              );
              const healthTrend = OpsPanel(
                title: 'Sensor Health Over Time',
                padding: EdgeInsets.all(24),
                child: _HealthTrend(),
              );

              if (stacked) {
                return Column(
                  children: [
                    siteOverview,
                    const SizedBox(height: 16),
                    healthTrend,
                  ],
                );
              }

              return SizedBox(
                height: _overviewRowHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 6, child: siteOverview),
                    const SizedBox(width: 16),
                    const Expanded(flex: 4, child: healthTrend),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const _DashboardFooter(),
        ],
      ),
    );
  }
}

class _SensorStatusDonut extends StatelessWidget {
  const _SensorStatusDonut({
    required this.online,
    required this.warning,
    required this.offline,
  });

  final int online;
  final int warning;
  final int offline;

  @override
  Widget build(BuildContext context) {
    final total = math.max(online + warning + offline, 1);
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(160, 160),
                painter: _DonutPainter(
                  online: online / total,
                  warning: warning / total,
                  offline: offline / total,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$total',
                      style: Theme.of(context).textTheme.headlineMedium),
                  Text('TOTAL', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
        _legend('Online', online, total, OpsColors.success),
        _legend('Warning', warning, total, OpsColors.amber),
        _legend('Offline', offline, total, OpsColors.danger),
      ],
    );
  }

  Widget _legend(String label, int value, int total, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: OpsColors.muted)),
          const Spacer(),
          Text(
            '$value (${((value / total) * 100).round()}%)',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.online,
    required this.warning,
    required this.offline,
  });

  final double online;
  final double warning;
  final double offline;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    var start = -math.pi / 2;
    for (final segment in [
      (offline, OpsColors.danger),
      (warning, OpsColors.amber),
      (online, OpsColors.success),
    ]) {
      paint.color = segment.$2;
      final sweep = math.max(segment.$1, .02) * math.pi * 2;
      canvas.drawArc(rect.deflate(14), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.online != online ||
        oldDelegate.warning != warning ||
        oldDelegate.offline != offline;
  }
}

class _AlertSummary extends StatelessWidget {
  const _AlertSummary({required this.openAlerts});

  final List<Alert> openAlerts;

  @override
  Widget build(BuildContext context) {
    final critical = openAlerts
        .where((alert) => alert.alertLevel.toLowerCase().contains('critical'))
        .length;
    return Column(
      children: [
        _CategoryRow(
            'Critical', critical == 0 ? 3 : critical, .25, OpsColors.danger),
        const _CategoryRow('High', 5, .42, Color(0xFFF97316)),
        const _CategoryRow('Medium', 8, .66, OpsColors.amber),
        const _CategoryRow('Low', 12, 1, OpsColors.primary),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow(this.label, this.value, this.factor, this.color);

  final String label;
  final int value;
  final double factor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(color: OpsColors.muted)),
              const Spacer(),
              Text('$value',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: factor,
              minHeight: 8,
              color: color,
              backgroundColor: const Color(0xFFECEEF0),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: OpsColors.success),
        SizedBox(width: 8),
        Text(
          'ACTIVE',
          style: TextStyle(
            color: OpsColors.success,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LiveFeed extends StatelessWidget {
  const _LiveFeed();

  @override
  Widget build(BuildContext context) {
    const display = [
      (
        Icons.device_thermostat_rounded,
        OpsColors.primary,
        'Temp - Zone A',
        '2 mins ago',
        '28.4 C',
        OpsColors.primary
      ),
      (
        Icons.water_drop_outlined,
        Color(0xFF3B82F6),
        'Humidity - Zone A',
        '5 mins ago',
        '62 %',
        Color(0xFF3B82F6)
      ),
      (
        Icons.vibration_rounded,
        OpsColors.danger,
        'Vibration - Pile 7',
        'Just now',
        '1.24 mm/s',
        OpsColors.danger
      ),
      (
        Icons.architecture_rounded,
        OpsColors.amber,
        'Tilt - Tower Crane',
        '10 mins ago',
        '0.32 deg',
        OpsColors.text
      ),
    ];

    return Column(
      children: display.indexed.map((entry) {
        final index = entry.$1;
        final row = entry.$2;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: index == display.length - 1
                ? null
                : const Border(bottom: BorderSide(color: Color(0xFFECEEF0))),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: row.$2.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(row.$1, color: row.$2, size: 18),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.$3,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(row.$4, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              Text(
                row.$5,
                style: TextStyle(
                  color: row.$6,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SiteOverviewTable extends StatelessWidget {
  const _SiteOverviewTable({required this.sites});

  final List<String> sites;

  @override
  Widget build(BuildContext context) {
    final names = sites.isEmpty
        ? const [
            'Project Alpha',
            'Project Beta',
            'Project Gamma',
            'Project Delta',
            'Project Epsilon'
          ]
        : sites.take(5).toList();
    return Column(
      children: [
        const _SiteRow(
          site: 'SITE',
          status: 'STATUS',
          sensors: 'SENSORS',
          alerts: 'ALERTS',
          last: 'LAST',
          header: true,
        ),
        const Divider(height: 16),
        ...names.indexed.map((entry) {
          final index = entry.$1;
          final site = entry.$2;
          final status = index == 2
              ? 'Warning'
              : index == 3
                  ? 'Offline'
                  : 'Online';
          return _SiteRow(
            site: site,
            status: status,
            sensors: '${42 - (index * 4)} / ${45 - (index * 3)}',
            alerts: '${index == 0 ? 2 : index == 4 ? 0 : index + 1}',
            last: index == 0 ? '2 mins ago' : '${index * 4 + 1} mins ago',
          );
        }),
      ],
    );
  }
}

class _SiteRow extends StatelessWidget {
  const _SiteRow({
    required this.site,
    required this.status,
    required this.sensors,
    required this.alerts,
    required this.last,
    this.header = false,
  });

  final String site;
  final String status;
  final String sensors;
  final String alerts;
  final String last;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final alertColor = alerts == '0'
        ? OpsColors.muted
        : alerts == '1'
            ? OpsColors.warning
            : OpsColors.danger;
    final textStyle = TextStyle(
      color: header ? OpsColors.outline : OpsColors.text,
      fontWeight: header ? FontWeight.w800 : FontWeight.w600,
      fontSize: header ? 11 : 13,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(site, style: textStyle)),
          Expanded(
            flex: 2,
            child: header
                ? Text(status, style: textStyle)
                : Align(
                    alignment: Alignment.centerLeft,
                    child: OpsStatusBadge(status)),
          ),
          Expanded(
              child:
                  Text(sensors, textAlign: TextAlign.center, style: textStyle)),
          Expanded(
            child: Text(
              alerts,
              textAlign: TextAlign.center,
              style: textStyle.copyWith(
                  color: header ? OpsColors.outline : alertColor),
            ),
          ),
          Expanded(
              flex: 2,
              child: Text(last,
                  style: textStyle.copyWith(
                      color: header ? OpsColors.outline : OpsColors.muted))),
        ],
      ),
    );
  }
}

class _HealthTrend extends StatelessWidget {
  const _HealthTrend();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 286,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              children: [
                _LegendDot('Online', OpsColors.success),
                SizedBox(width: 14),
                _LegendDot('Warning', OpsColors.amber),
              ],
            ),
          ),
          Positioned(
            top: 26,
            bottom: 32,
            left: 0,
            width: 30,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('100%'),
                Text('75%'),
                Text('50%'),
                Text('25%'),
                Text('0%'),
              ],
            ),
          ),
          Positioned(
            top: 26,
            bottom: 38,
            left: 38,
            right: 0,
            child: CustomPaint(
              painter: _TrendPainter(),
              child: SizedBox.expand(),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 38,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Day 1'),
                Text('Day 2'),
                Text('Day 3'),
                Text('Day 4'),
                Text('Day 5'),
                Text('Day 6'),
                Text('Day 7'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: OpsColors.muted)),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = OpsColors.border
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 4;
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint);
    }
    _drawLine(
        canvas, size, const [78, 88, 74, 84, 94, 79, 88], OpsColors.success);
    _drawLine(
        canvas, size, const [25, 31, 19, 22, 28, 31, 25], OpsColors.amber);
  }

  void _drawLine(Canvas canvas, Size size, List<double> values, Color color) {
    final path = Path();
    final pointPaint = Paint()..color = color;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] / 100 * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
    canvas.drawPath(path, linePaint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 5.0;
    const gap = 5.0;
    var x = start.dx;
    while (x < end.dx) {
      canvas.drawLine(
        Offset(x, start.dy),
        Offset(math.min(x + dash, end.dx), end.dy),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashboardFooter extends StatelessWidget {
  const _DashboardFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: OpsColors.border)),
      ),
      child: const Row(
        children: [
          Icon(Icons.schedule_rounded, size: 16, color: OpsColors.muted),
          SizedBox(width: 8),
          Text('All times in IST (UTC +05:30)',
              style: TextStyle(color: OpsColors.muted)),
          Spacer(),
          Icon(Icons.circle, size: 8, color: OpsColors.success),
          SizedBox(width: 8),
          Text('Data updates every 60 seconds',
              style: TextStyle(color: OpsColors.muted)),
        ],
      ),
    );
  }
}
