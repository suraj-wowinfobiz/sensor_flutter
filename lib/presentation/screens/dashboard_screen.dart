import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/database_provider.dart';
import '../widgets/animated/alert_item.dart';
import '../widgets/animated/chart_card.dart';
import '../widgets/animated/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, db, child) {
        final stats = [
          {
            'icon': Icons.business,
            'value': db.organizations.length.toString(),
            'label': 'Organizations'
          },
          {
            'icon': Icons.location_on,
            'value': (db.organizations.length * 2).toString(),
            'label': 'Sites'
          },
          {
            'icon': Icons.sensors,
            'value': db.sensors.length.toString(),
            'label': 'Sensors'
          },
          {
            'icon': Icons.notifications,
            'value': db.activeAlerts.length.toString(),
            'label': 'Active Alerts'
          },
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 1100
                      ? 4
                      : width > 700
                          ? 2
                          : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.8,
                    ),
                    itemCount: stats.length,
                    itemBuilder: (context, index) {
                      final stat = stats[index];
                      return AnimatedStatCard(
                        icon: stat['icon'] as IconData,
                        value: stat['value'] as String,
                        label: stat['label'] as String,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AnimatedChartCard(
                        title: 'Real-time Tilt Readings',
                        icon: Icons.show_chart,
                        isLive: true,
                        chart: _buildTiltChart(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedChartCard(
                        title: 'Sensor Distribution',
                        icon: Icons.pie_chart,
                        chart: _buildDistributionChart(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recent Active Alerts',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      if (db.activeAlerts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: Text('No active alerts')),
                        ),
                      ...db.activeAlerts.take(5).map(
                            (a) => AnimatedAlertItem(
                              message: a.message,
                              sensorId: a.sensorId,
                              time: _formatTime(a.triggeredAt),
                              level: a.alertLevel,
                              onResolve: () => db.resolveAlert(a.id),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTiltChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(24, (i) => FlSpot(i.toDouble(), 2 + i * 0.08)),
            isCurved: true,
            barWidth: 3,
            color: const Color(0xFF1f7bcf),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots:
                List.generate(24, (i) => FlSpot(i.toDouble(), 1.5 + i * 0.1)),
            isCurved: true,
            barWidth: 3,
            color: const Color(0xFFe68a2e),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionChart() {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
              value: 30, title: 'A', color: const Color(0xFF1f7bcf)),
          PieChartSectionData(
              value: 25, title: 'B', color: const Color(0xFFe68a2e)),
          PieChartSectionData(
              value: 20, title: 'C', color: const Color(0xFF27a36a)),
          PieChartSectionData(
              value: 15, title: 'D', color: const Color(0xFFd64545)),
          PieChartSectionData(
              value: 10, title: 'E', color: const Color(0xFF9b59b6)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return '${diff.inDays} d ago';
  }
}
