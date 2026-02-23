import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../providers/user_admin_database_provider.dart';

class UserAdminAlertsScreen extends StatelessWidget {
  const UserAdminAlertsScreen({super.key});

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
    return Consumer<UserAdminDatabaseProvider>(
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
              const Text(
                'Monitor and manage system alerts',
                style: TextStyle(fontSize: 15, color: Color(0xFF4e6473)),
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
          childAspectRatio: width >= 1000 ? 2.8 : 2.6,
          children: [
            _summaryCard(
                'Active Alerts', '$activeCount', const Color(0xFF071d28)),
            _summaryCard('Critical', '$criticalCount', const Color(0xFFef2e38)),
            _summaryCard('Warnings', '$warningCount', const Color(0xFFd39a00)),
          ],
        );
      },
    );
  }

  Widget _summaryCard(String label, String value, Color valueColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ultraCompact = constraints.maxHeight < 70;
        final compact = constraints.maxHeight < 90;
        final cardPadding = ultraCompact
            ? 6.0
            : compact
                ? 10.0
                : 18.0;
        final labelSize = ultraCompact
            ? 12.0
            : compact
                ? 13.0
                : 15.0;
        final valueSize = ultraCompact
            ? 18.0
            : compact
                ? 24.0
                : 30.0;
        final gap = ultraCompact
            ? 2.0
            : compact
                ? 6.0
                : 12.0;

        return Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFc8d6dc)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1a303c),
                  ),
                ),
              ),
              SizedBox(height: gap),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: valueSize,
                      fontWeight: FontWeight.w800,
                      color: valueColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveAlertsPanel(
    BuildContext context,
    UserAdminDatabaseProvider db,
    List<Alert> activeAlerts,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFc8d6dc)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF132733),
            ),
          ),
          const SizedBox(height: 14),
          if (activeAlerts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No active alerts',
                style: TextStyle(color: Color(0xFF60717c)),
              ),
            ),
          ...activeAlerts.map((alert) {
            final isCritical = alert.alertLevel == 'critical';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD7E2E8)),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1a2f3b),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Triggered: ${_formatDate(alert.triggeredAt)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF506775),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _actionButton(
                              label: 'Acknowledge',
                              onTap: () => db.resolveAlert(alert.id),
                            ),
                            _actionButton(
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

  Widget _actionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE7EFF3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFC8D6DD)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF203845),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
