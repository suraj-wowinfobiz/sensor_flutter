import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../providers/user_database_provider.dart';

class UserAlertsScreen extends StatelessWidget {
  const UserAlertsScreen({super.key});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:00';
  }

  void _showDetails(BuildContext context, Alert alert) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Alert Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Message: ${alert.message}'),
              const SizedBox(height: 8),
              Text('Level: ${alert.alertLevel}'),
              const SizedBox(height: 8),
              Text('Sensor ID: ${alert.sensorId}'),
              const SizedBox(height: 8),
              Text('Triggered: ${_formatDate(alert.triggeredAt)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Consumer<UserDatabaseProvider>(
      builder: (context, db, child) {
        final activeAlerts = db.alerts.where((a) => !a.isResolved).toList();
        final criticalCount =
            activeAlerts.where((a) => a.alertLevel == 'critical').length;
        final warningCount =
            activeAlerts.where((a) => a.alertLevel != 'critical').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alert Management',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF0f202d)
                      : const Color(0xFFd4e4ef),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Monitor and manage system alerts',
                style: TextStyle(
                  fontSize: 15,
                  color: isLight
                      ? const Color(0xFF4e6473)
                      : const Color(0xFF9db7d2),
                ),
              ),
              const SizedBox(height: 18),
              _buildSummaryCards(
                activeCount: activeAlerts.length,
                criticalCount: criticalCount,
                warningCount: warningCount,
              ),
              const SizedBox(height: 16),
              _buildActiveAlertsPanel(context, db, activeAlerts),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards({
    required int activeCount,
    required int criticalCount,
    required int warningCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1000
            ? 3
            : width >= 700
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: width >= 1000 ? 2.8 : 3.4,
          children: [
            _summaryCard(
              context,
              'Active Alerts',
              '$activeCount',
              Theme.of(context).brightness == Brightness.light ? const Color(0xFF071d28) : const Color(0xFFD8E8F5),
            ),
            _summaryCard(
              context,
              'Critical',
              '$criticalCount',
              const Color(0xFFef2e38),
            ),
            _summaryCard(
              context,
              'Warnings',
              '$warningCount',
              const Color(0xFFd39a00),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isLight
                  ? const Color(0xFF1a303c)
                  : const Color(0xFFD8E8F5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 40 > 30 ? 40 - 10 : 30,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlertsPanel(
    BuildContext context,
    UserDatabaseProvider db,
    List<Alert> activeAlerts,
  ) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isLight
                  ? const Color(0xFF132733)
                  : const Color(0xFFD8E8F5),
            ),
          ),
          const SizedBox(height: 14),
          if (activeAlerts.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No active alerts',
                style: TextStyle(
                  color: isLight
                      ? const Color(0xFF60717c)
                      : const Color(0xFF9FB4C6),
                ),
              ),
            ),
          ...activeAlerts.map((alert) {
            final isCritical = alert.alertLevel == 'critical';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLight
                    ? const Color(0xFFF2F6F8)
                    : const Color(0xFF223B4E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      isCritical ? Icons.cancel : Icons.warning_amber_rounded,
                      color: isCritical
                          ? const Color(0xFFef2e38)
                          : const Color(0xFFd39a00),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.message,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isLight
                                ? const Color(0xFF1a2f3b)
                                : const Color(0xFFE2EDF8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Triggered: ${_formatDate(alert.triggeredAt)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isLight
                                ? const Color(0xFF506775)
                                : const Color(0xFF9FB4C6),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _actionButton(context, 
                              label: 'Acknowledge',
                              onTap: () => db.resolveAlert(alert.id),
                            ),
                            _actionButton(context, 
                              label: 'View Details',
                              onTap: () => _showDetails(context, alert),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCritical
                          ? const Color(0xFFef2e38)
                          : const Color(0xFFd39a00),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alert.alertLevel,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _actionButton(context, {
    required String label,
    required VoidCallback onTap,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFE7EFF3) : const Color(0xFF243E52),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color:
                isLight ? const Color(0xFF203845) : const Color(0xFFD8E8F5),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
