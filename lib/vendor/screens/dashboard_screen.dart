import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../super_admin/core/theme/custom_theme_tokens.dart';

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<CustomThemeTokens>()!;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vendor Command Center',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: tokens.heading,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Engineer performance, pending site completion, and one-day execution overview.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.subheading,
              ),
            ),
            const SizedBox(height: 14),
            _topMetrics(context),
            const SizedBox(height: 12),
            _performanceAndStatus(context),
            const SizedBox(height: 12),
            _completionAndTopEngineer(context),
          ],
        ),
      ),
    );
  }

  Widget _topMetrics(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        if (compact) {
          return const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 220,
                child: _MetricCard(
                  title: 'Active Engineers',
                  value: '7',
                  icon: Icons.engineering_outlined,
                ),
              ),
              SizedBox(
                width: 220,
                child: _MetricCard(
                  title: 'Pending Sites',
                  value: '3',
                  icon: Icons.pending_actions_outlined,
                ),
              ),
              SizedBox(
                width: 220,
                child: _MetricCard(
                  title: 'Completed Today',
                  value: '9',
                  icon: Icons.task_alt_outlined,
                ),
              ),
              SizedBox(
                width: 220,
                child: _MetricCard(
                  title: 'Top Engineer Score',
                  value: '96',
                  icon: Icons.workspace_premium_outlined,
                ),
              ),
            ],
          );
        }
        return const Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Active Engineers',
                value: '7',
                icon: Icons.engineering_outlined,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Pending Sites',
                value: '3',
                icon: Icons.pending_actions_outlined,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Completed Today',
                value: '9',
                icon: Icons.task_alt_outlined,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Top Engineer Score',
                value: '96',
                icon: Icons.workspace_premium_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _performanceAndStatus(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        if (compact) {
          return const Column(
            children: [
              _EngineerPerformanceChart(),
              SizedBox(height: 10),
              _PendingCompletionPie(),
            ],
          );
        }
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: _EngineerPerformanceChart()),
            SizedBox(width: 10),
            Expanded(flex: 4, child: _PendingCompletionPie()),
          ],
        );
      },
    );
  }

  Widget _completionAndTopEngineer(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        if (compact) {
          return const Column(
            children: [
              _OneDayCompletionBarChart(),
              SizedBox(height: 10),
              _TopEngineerPanel(),
            ],
          );
        }
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: _OneDayCompletionBarChart()),
            SizedBox(width: 10),
            Expanded(flex: 4, child: _TopEngineerPanel()),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _EngineerPerformanceChart extends StatelessWidget {
  const _EngineerPerformanceChart();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<CustomThemeTokens>()!;
    return Container(
      height: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Engineer Performance (7 days)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 60,
                maxY: 100,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: tokens.chartGrid.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Theme.of(context).dividerColor),
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 10,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style:
                            TextStyle(fontSize: 11, color: tokens.subheading),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ];
                        final i = value.toInt();
                        if (i < 0 || i >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(days[i],
                            style: TextStyle(
                                fontSize: 11, color: tokens.subheading));
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 78),
                      FlSpot(1, 82),
                      FlSpot(2, 88),
                      FlSpot(3, 84),
                      FlSpot(4, 91),
                      FlSpot(5, 94),
                      FlSpot(6, 96),
                    ],
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingCompletionPie extends StatelessWidget {
  const _PendingCompletionPie();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<CustomThemeTokens>()!;
    return Container(
      height: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Site Completion Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 42,
                sectionsSpace: 4,
                sections: [
                  PieChartSectionData(
                    value: 68,
                    title: '68%',
                    radius: 46,
                    color: const Color(0xFF1E9B63),
                    titleStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                  PieChartSectionData(
                    value: 22,
                    title: '22%',
                    radius: 44,
                    color: const Color(0xFFDA8C16),
                    titleStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                  PieChartSectionData(
                    value: 10,
                    title: '10%',
                    radius: 42,
                    color: const Color(0xFFD64545),
                    titleStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _legendRow(tokens.statusNormal, 'Completed (68%)'),
          _legendRow(tokens.statusWarning, 'Pending (22%)'),
          _legendRow(tokens.statusCritical, 'Blocked (10%)'),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _OneDayCompletionBarChart extends StatelessWidget {
  const _OneDayCompletionBarChart();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<CustomThemeTokens>()!;
    return Container(
      height: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'One-Day Site Completion',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: 12,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: tokens.chartGrid.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Theme.of(context).dividerColor),
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style:
                            TextStyle(fontSize: 11, color: tokens.subheading),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (v, _) {
                        const labels = ['NP', 'ZC', 'W2', 'SY', 'EA'];
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(labels[i],
                            style: TextStyle(
                                fontSize: 11, color: tokens.subheading));
                      },
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [
                    BarChartRodData(
                        toY: 10, width: 14, color: const Color(0xFF5973D8))
                  ]),
                  BarChartGroupData(x: 1, barRods: [
                    BarChartRodData(
                        toY: 7, width: 14, color: const Color(0xFF0F9CA0))
                  ]),
                  BarChartGroupData(x: 2, barRods: [
                    BarChartRodData(
                        toY: 5, width: 14, color: const Color(0xFFDA8C16))
                  ]),
                  BarChartGroupData(x: 3, barRods: [
                    BarChartRodData(
                        toY: 8, width: 14, color: const Color(0xFF1E9B63))
                  ]),
                  BarChartGroupData(x: 4, barRods: [
                    BarChartRodData(
                        toY: 6, width: 14, color: const Color(0xFF8C6AD9))
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopEngineerPanel extends StatelessWidget {
  const _TopEngineerPanel();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<CustomThemeTokens>()!;
    return Container(
      height: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Highest Performance Engineer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: tokens.softPanel.withValues(alpha: 0.5),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.14),
                        child: Icon(Icons.emoji_events_outlined,
                            size: 17,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Arun Patel',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: tokens.statusNormal.withValues(alpha: 0.14),
                        ),
                        child: Text(
                          'Score 96',
                          style: TextStyle(
                              color: tokens.statusNormal,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Completed: 11 tasks today'),
                  const SizedBox(height: 4),
                  const Text('Avg response: 14 min'),
                  const SizedBox(height: 4),
                  const Text('Escalations resolved: 3/3'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const _MiniEngineerRow(name: 'Mira Joseph', score: 92),
            const _MiniEngineerRow(name: 'Nikhil Rao', score: 88),
            const _MiniEngineerRow(name: 'Ria Sen', score: 85),
          ],
        ),
      ),
    );
  }
}

class _MiniEngineerRow extends StatelessWidget {
  final String name;
  final int score;

  const _MiniEngineerRow({required this.name, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
          Text('Score $score', style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }
}
