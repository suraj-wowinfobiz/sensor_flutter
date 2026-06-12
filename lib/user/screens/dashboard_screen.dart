import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/ops_theme.dart';
import '../models/alert.dart';
import '../providers/user_riverpod_provider.dart';

class UserDashboardScreen extends ConsumerWidget {
  final bool embeddedScroll;

  const UserDashboardScreen({super.key, this.embeddedScroll = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(userDatabaseChangeNotifierProvider);
    final alerts = db.alerts;
    final openAlerts = alerts.where((a) => !a.isResolved).toList();

    return OpsPage(
      title: 'Dashboard',
      subtitle:
          'Real-time overview of your construction sites and sensor health',
      actions: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: const Text('May 20 - May 26, 2024'),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Widget'),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.file_download_outlined, size: 18),
          label: const Text('Export'),
        ),
      ],
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 620
                      ? 2
                      : 1;
              final cardHeight = count == 3 ? 168.0 : 148.0;
              final cards = [
                const OpsKpiCard(
                  label: 'Total Sensors',
                  value: '128',
                  helper: '+2.4%',
                  icon: Icons.sensors_rounded,
                ),
                const OpsKpiCard(
                  label: 'Online',
                  value: '96.2%',
                  helper: 'Stable',
                  icon: Icons.check_circle_rounded,
                  color: OpsColors.success,
                ),
                OpsKpiCard(
                  label: 'Alerts',
                  value: '${openAlerts.isEmpty ? 12 : openAlerts.length}',
                  helper: 'Action Req.',
                  icon: Icons.warning_rounded,
                  color: OpsColors.danger,
                ),
                const OpsKpiCard(
                  label: 'Active Sites',
                  value: '5',
                  helper: '',
                  icon: Icons.location_on_rounded,
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
                  valueSuffix: '°C',
                  helper: 'Avg',
                  icon: Icons.thermostat_rounded,
                  color: OpsColors.primaryContainer,
                ),
              ];
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  mainAxisExtent: cardHeight,
                ),
                itemBuilder: (context, index) => cards[index],
              );
            },
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final vertical = constraints.maxWidth < 900;
              const left = OpsPanel(
                title: 'Sensor Status',
                padding: EdgeInsets.all(24),
                child: _SensorStatusDonut(
                  online: 96,
                  warning: 20,
                  offline: 12,
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
                    const SizedBox(height: 16),
                    center,
                    const SizedBox(height: 16),
                    right,
                  ],
                );
              }

              return SizedBox(
                height: 430,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(child: left),
                    const SizedBox(width: 20),
                    Expanded(child: center),
                    const SizedBox(width: 20),
                    const Expanded(child: right),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const OpsFramedPanel(
            header: _SiteOverviewHeader(),
            child: _SiteOverviewTable(),
          ),
          const SizedBox(height: 20),
          const OpsPanel(
            title: 'Sensor Health Over Time',
            padding: EdgeInsets.all(24),
            child: _HealthTrend(),
          ),
          const SizedBox(height: 20),
          const _DashboardFooter(),
        ],
      ),
    );
  }
}

class _SensorStatusDonut extends StatelessWidget {
  final int online;
  final int warning;
  final int offline;

  const _SensorStatusDonut({
    required this.online,
    required this.warning,
    required this.offline,
  });

  @override
  Widget build(BuildContext context) {
    final total = (online + warning + offline).clamp(1, 99999);
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
    final factor = value / total;
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
          Text('$value (${(factor * 100).round()}%)',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double online;
  final double warning;
  final double offline;

  const _DonutPainter({
    required this.online,
    required this.warning,
    required this.offline,
  });

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
  final List<Alert> openAlerts;

  const _AlertSummary({required this.openAlerts});

  @override
  Widget build(BuildContext context) {
    final critical = openAlerts
        .where((a) => a.alertLevel.toLowerCase().contains('critical'))
        .length;
    return Column(
      children: [
        _CategoryRow(
          'Critical',
          critical == 0 ? 3 : critical,
          .25,
          OpsColors.danger,
        ),
        const _CategoryRow('High', 5, .42, Color(0xFFF97316)),
        const _CategoryRow('Medium', 8, .66, OpsColors.amber),
        const _CategoryRow('Low', 12, 1, OpsColors.primary),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String label;
  final int value;
  final double factor;
  final Color color;

  const _CategoryRow(this.label, this.value, this.factor, this.color);

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
        '28.4 °C',
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
        '0.32°',
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
                : const Border(
                    bottom: BorderSide(color: Color(0xFFECEEF0)),
                  ),
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
                    Text(row.$3,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        )),
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
  const _SiteOverviewTable();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Project Alpha', 'Online', '42 / 45', '2', '2 mins ago'),
      ('Project Beta', 'Online', '36 / 38', '1', '5 mins ago'),
      ('Project Gamma', 'Warning', '28 / 32', '3', '8 mins ago'),
      ('Project Delta', 'Offline', '12 / 15', '6', '15 mins ago'),
      (
        'Project Epsilon',
        'Online',
        '10 / 12',
        '0',
        '1 min ago',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(760.0, constraints.maxWidth);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                const _SiteTableHeader(),
                ...rows.map(
                  (row) => _SiteTableRow(
                    site: row.$1,
                    status: row.$2,
                    sensors: row.$3,
                    alerts: row.$4,
                    lastReading: row.$5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SiteTableHeader extends StatelessWidget {
  const _SiteTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      color: OpsColors.surfaceLow,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: const Row(
        children: [
          _TableCellText('SITE', flex: 2, header: true),
          _TableCellText('STATUS', flex: 1, header: true),
          _TableCellText('SENSORS', flex: 1, header: true, center: true),
          _TableCellText('ALERTS', flex: 1, header: true, center: true),
          _TableCellText('LAST\nREADING', flex: 1, header: true),
        ],
      ),
    );
  }
}

class _SiteTableRow extends StatelessWidget {
  final String site;
  final String status;
  final String sensors;
  final String alerts;
  final String lastReading;

  const _SiteTableRow({
    required this.site,
    required this.status,
    required this.sensors,
    required this.alerts,
    required this.lastReading,
  });

  @override
  Widget build(BuildContext context) {
    final alertColor = alerts == '0'
        ? OpsColors.muted
        : alerts == '1'
            ? OpsColors.warning
            : OpsColors.danger;

    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: OpsColors.border)),
      ),
      child: Row(
        children: [
          _TableCellText(site, flex: 2, bold: true),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: OpsStatusBadge(status),
            ),
          ),
          _TableCellText(sensors, flex: 1, center: true, bold: true),
          _TableCellText(
            alerts,
            flex: 1,
            center: true,
            bold: true,
            color: alertColor,
          ),
          _TableCellText(lastReading, flex: 1, color: OpsColors.muted),
        ],
      ),
    );
  }
}

class _TableCellText extends StatelessWidget {
  final String text;
  final int flex;
  final bool header;
  final bool center;
  final bool bold;
  final Color? color;

  const _TableCellText(
    this.text, {
    required this.flex,
    this.header = false,
    this.center = false,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        maxLines: header ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ?? (header ? OpsColors.muted : OpsColors.text),
          fontSize: header ? 12 : 14,
          height: header ? 16 / 12 : 20 / 14,
          letterSpacing: header ? .6 : 0,
          fontWeight: header || bold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _SiteOverviewHeader extends StatelessWidget {
  const _SiteOverviewHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'SITE OVERVIEW',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: OpsColors.outline,
                letterSpacing: .4,
              ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () {},
          iconAlignment: IconAlignment.end,
          label: const Text('View all'),
          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
          style: TextButton.styleFrom(
            foregroundColor: OpsColors.primary,
            textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _HealthTrend extends StatelessWidget {
  const _HealthTrend();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 250,
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
            top: 30,
            bottom: 24,
            left: 0,
            width: 34,
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
            top: 30,
            bottom: 28,
            left: 42,
            right: 0,
            child: CustomPaint(
              painter: _TrendPainter(),
              child: SizedBox.expand(),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 42,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('May 20'),
                Text('May 21'),
                Text('May 22'),
                Text('May 23'),
                Text('May 24'),
                Text('May 25'),
                Text('May 26'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot(this.label, this.color);

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
      canvas,
      size,
      const [78, 88, 74, 84, 94, 79, 88],
      OpsColors.success,
    );
    _drawLine(
      canvas,
      size,
      const [25, 31, 19, 22, 28, 31, 25],
      OpsColors.amber,
    );
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
      canvas.drawLine(Offset(x, start.dy),
          Offset(math.min(x + dash, end.dx), end.dy), paint);
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
