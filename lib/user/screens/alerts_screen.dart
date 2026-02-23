import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/custom_theme_tokens.dart';
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
    final tokens = Theme.of(context).extension<CustomThemeTokens>()!;
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
                  color: tokens.heading,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Monitor and manage system alerts',
                style: TextStyle(
                  fontSize: 15,
                  color: tokens.subheading,
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
        final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(
              1.0,
              1.35,
            );
        final crossAxisCount = width >= 1000
            ? 3
            : width >= 700
                ? 2
                : 1;
        final baseCardHeight = crossAxisCount == 3
            ? 96.0
            : crossAxisCount == 2
                ? 92.0
                : 88.0;
        final cardHeight = (baseCardHeight * textScale).clamp(88.0, 132.0);

        final cards = [
          _summaryCard(
            context,
            'Active Alerts',
            '$activeCount',
            Theme.of(context).colorScheme.onSurface,
          ),
          _summaryCard(
            context,
            'Critical',
            '$criticalCount',
            Theme.of(context).extension<CustomThemeTokens>()!.statusCritical,
          ),
          _summaryCard(
            context,
            'Warnings',
            '$warningCount',
            Theme.of(context).extension<CustomThemeTokens>()!.statusWarning,
          ),
        ];

        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, index) => cards[index],
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
    final tokens = Theme.of(context).extension<CustomThemeTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final veryCompact = constraints.maxHeight < 68;
        final compact = constraints.maxHeight < 78;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: veryCompact ? 6 : (compact ? 8 : 12),
          ),
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
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: veryCompact ? 12 : (compact ? 13 : 15),
                  fontWeight: FontWeight.w700,
                  color: tokens.heading,
                ),
              ),
              SizedBox(height: veryCompact ? 1 : (compact ? 2 : 4)),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: veryCompact ? 17 : (compact ? 20 : 30),
                        fontWeight: FontWeight.w800,
                        color: valueColor,
                      ),
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
    UserDatabaseProvider db,
    List<Alert> activeAlerts,
  ) {
    final tokens = Theme.of(context).extension<CustomThemeTokens>()!;
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
              color: tokens.heading,
            ),
          ),
          const SizedBox(height: 14),
          if (activeAlerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No active alerts',
                style: TextStyle(
                  color: tokens.mutedText,
                ),
              ),
            ),
          ...activeAlerts.map((alert) {
            final isCritical = alert.alertLevel == 'critical';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.softPanel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final badge = Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCritical
                          ? tokens.statusCritical
                          : tokens.statusWarning,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alert.alertLevel,
                      style: TextStyle(
                        color: ThemeData.estimateBrightnessForColor(isCritical
                                    ? tokens.statusCritical
                                    : tokens.statusWarning) ==
                                Brightness.dark
                            ? Colors.white
                            : const Color(0xFF0E1D2A),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                isCritical
                                    ? Icons.cancel
                                    : Icons.warning_amber_rounded,
                                color: isCritical
                                    ? tokens.statusCritical
                                    : tokens.statusWarning,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                alert.message,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Triggered: ${_formatDate(alert.triggeredAt)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: tokens.mutedText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _actionButton(
                              context,
                              label: 'Acknowledge',
                              onTap: () => db.resolveAlert(alert.id),
                            ),
                            _actionButton(
                              context,
                              label: 'View Details',
                              onTap: () => _showDetails(context, alert),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        badge,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          isCritical
                              ? Icons.cancel
                              : Icons.warning_amber_rounded,
                          color: isCritical
                              ? tokens.statusCritical
                              : tokens.statusWarning,
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
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Triggered: ${_formatDate(alert.triggeredAt)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: tokens.mutedText,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _actionButton(
                                  context,
                                  label: 'Acknowledge',
                                  onTap: () => db.resolveAlert(alert.id),
                                ),
                                _actionButton(
                                  context,
                                  label: 'View Details',
                                  onTap: () => _showDetails(context, alert),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      badge,
                    ],
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _actionButton(
    context, {
    required String label,
    required VoidCallback onTap,
  }) {
    final tokens = Theme.of(context).extension<CustomThemeTokens>()!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: tokens.softButton,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: tokens.heading,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
