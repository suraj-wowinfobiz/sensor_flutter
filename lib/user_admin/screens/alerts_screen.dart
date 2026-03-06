import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/alerts_api.dart';
import '../api/sensor_api.dart';
import '../models/alert.dart';
import '../providers/user_admin_api_riverpod_provider.dart';
import '../widgets/crud_modal.dart';

class UserAdminAlertsScreen extends ConsumerWidget {
  const UserAdminAlertsScreen({super.key});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:00';
  }

  void _showDetails(BuildContext context, Alert alert) {
    String fmtDate(DateTime? value) => value == null ? '-' : _formatDate(value);
    String fmtText(String value) => value.trim().isEmpty ? '-' : value.trim();
    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Alert Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alert ID: ${fmtText(alert.id)}'),
              const SizedBox(height: 8),
              Text('Status: ${fmtText(alert.status)}'),
              const SizedBox(height: 8),
              Text('Level: ${fmtText(alert.alertLevel)}'),
              const SizedBox(height: 8),
              Text('Message: ${fmtText(alert.message)}'),
              const SizedBox(height: 8),
              Text('Sensor ID: ${fmtText(alert.sensorId)}'),
              const SizedBox(height: 8),
              Text('Sensor Parameter ID: ${fmtText(alert.sensorParameterId)}'),
              const SizedBox(height: 8),
              Text('Assigned To: ${fmtText(alert.assignedTo)}'),
              const SizedBox(height: 8),
              Text('Triggered: ${fmtDate(alert.triggeredAt)}'),
              const SizedBox(height: 8),
              Text('Acknowledged: ${fmtDate(alert.acknowledgedAt)}'),
              const SizedBox(height: 8),
              Text('Resolved: ${fmtDate(alert.resolvedAt)}'),
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

  Future<void> _showCreateAlertDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final sensors = await SensorApi.getAllSensors();
    if (!context.mounted) return;
    final sensorOptions = <Map<String, String>>[];
    final sensorParameterBySensorId = <String, String>{};
    for (final sensor in sensors) {
      final id = (sensor['sensorId'] ?? sensor['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      final label =
          (sensor['name'] ?? sensor['serialNumber'] ?? id).toString().trim();
      sensorOptions.add({'value': id, 'label': label.isEmpty ? id : label});
      sensorParameterBySensorId[id] = (sensor['sensorParameterId'] ??
              sensor['sensor_parameter_id'] ??
              sensor['parameterId'] ??
              id)
          .toString()
          .trim();
    }

    String sensorId = '';
    String alertLevel = '';
    String message = '';
    String assignedTo = '';
    if (sensorOptions.isNotEmpty) {
      sensorId = sensorOptions.first['value']!;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return UserAdminCrudModal(
            title: 'Add Alert',
            fields: [
              if (sensorOptions.isNotEmpty)
                {
                  'label': 'sensor',
                  'type': 'select',
                  'value': sensorId.isEmpty ? null : sensorId,
                  'options': sensorOptions,
                  'onChanged': (String? value) =>
                      setDialogState(() => sensorId = value ?? ''),
                }
              else
                {
                  'label': 'sensor',
                  'value': sensorId,
                  'onChanged': (String value) =>
                      setDialogState(() => sensorId = value),
                  'keyboardType': TextInputType.text,
                },
              {
                'label': 'alertLevel',
                'value': alertLevel,
                'onChanged': (String value) =>
                    setDialogState(() => alertLevel = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'message',
                'value': message,
                'onChanged': (String value) =>
                    setDialogState(() => message = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'assignedTo',
                'value': assignedTo,
                'onChanged': (String value) =>
                    setDialogState(() => assignedTo = value),
                'keyboardType': TextInputType.text,
              },
            ],
            onSave: () async {
              final sensorParameterId =
                  sensorParameterBySensorId[sensorId]?.trim() ?? '';
              if (sensorId.trim().isEmpty ||
                  sensorParameterId.trim().isEmpty ||
                  alertLevel.trim().isEmpty ||
                  message.trim().isEmpty ||
                  assignedTo.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('All alert fields are required'),
                  ),
                );
                return;
              }
              try {
                await AlertsApi.createAlert(
                  sensorId: sensorId,
                  sensorParameterId: sensorParameterId,
                  alertLevel: alertLevel,
                  message: message,
                  assignedTo: assignedTo,
                );
                ref.invalidate(userAdminAlertsApiProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to create alert: $e')),
                  );
                }
              }
            },
            onCancel: () => Navigator.pop(dialogContext),
          );
        },
      ),
    );
  }

  Future<void> _showEditAlertDialog(
    BuildContext context,
    WidgetRef ref,
    Alert alert,
  ) async {
    final sensors = await SensorApi.getAllSensors();
    if (!context.mounted) return;
    final sensorOptions = <Map<String, String>>[];
    final sensorParameterBySensorId = <String, String>{};
    for (final sensor in sensors) {
      final id = (sensor['sensorId'] ?? sensor['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      final label =
          (sensor['name'] ?? sensor['serialNumber'] ?? id).toString().trim();
      sensorOptions.add({'value': id, 'label': label.isEmpty ? id : label});
      sensorParameterBySensorId[id] = (sensor['sensorParameterId'] ??
              sensor['sensor_parameter_id'] ??
              sensor['parameterId'] ??
              id)
          .toString()
          .trim();
    }

    String sensorId = alert.sensorId.trim();
    String alertLevel = alert.alertLevel.trim();
    String message = alert.message.trim();
    String assignedTo = alert.assignedTo.trim();
    if (sensorId.isEmpty && sensorOptions.isNotEmpty) {
      sensorId = sensorOptions.first['value']!;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return UserAdminCrudModal(
            title: 'Edit Alert',
            fields: [
              if (sensorOptions.isNotEmpty)
                {
                  'label': 'sensor',
                  'type': 'select',
                  'value': sensorId.isEmpty ? null : sensorId,
                  'options': sensorOptions,
                  'onChanged': (String? value) =>
                      setDialogState(() => sensorId = value ?? ''),
                }
              else
                {
                  'label': 'sensor',
                  'value': sensorId,
                  'onChanged': (String value) =>
                      setDialogState(() => sensorId = value),
                  'keyboardType': TextInputType.text,
                },
              {
                'label': 'alertLevel',
                'value': alertLevel,
                'onChanged': (String value) =>
                    setDialogState(() => alertLevel = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'message',
                'value': message,
                'onChanged': (String value) =>
                    setDialogState(() => message = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'assignedTo',
                'value': assignedTo,
                'onChanged': (String value) =>
                    setDialogState(() => assignedTo = value),
                'keyboardType': TextInputType.text,
              },
            ],
            onSave: () async {
              final sensorParameterId =
                  sensorParameterBySensorId[sensorId]?.trim() ?? '';
              if (alert.id.trim().isEmpty ||
                  sensorId.trim().isEmpty ||
                  sensorParameterId.isEmpty ||
                  alertLevel.trim().isEmpty ||
                  message.trim().isEmpty ||
                  assignedTo.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('All alert fields are required'),
                  ),
                );
                return;
              }
              try {
                await AlertsApi.updateAlert(
                  id: alert.id,
                  sensorId: sensorId,
                  sensorParameterId: sensorParameterId,
                  alertLevel: alertLevel,
                  message: message,
                  assignedTo: assignedTo,
                );
                ref.invalidate(userAdminAlertsApiProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to update alert: $e')),
                  );
                }
              }
            },
            onCancel: () => Navigator.pop(dialogContext),
          );
        },
      ),
    );
  }

  Future<void> _deleteAlert(
    BuildContext context,
    WidgetRef ref,
    Alert alert,
  ) async {
    if (alert.id.trim().isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Alert'),
        content: const Text('Are you sure you want to delete this alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await AlertsApi.deleteAlert(alert.id);
      ref.invalidate(userAdminAlertsApiProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete alert: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final alertsAsync = ref.watch(userAdminAlertsApiProvider);
    final apiAlerts = alertsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <Alert>[],
    );
    final allAlerts = apiAlerts;
    final activeCount = allAlerts
        .where((a) => a.status.trim().toUpperCase() == 'ACTIVE')
        .length;
    final criticalCount = allAlerts
        .where((a) => a.alertLevel.trim().toLowerCase() == 'critical')
        .length;
    final warningCount = allAlerts
        .where((a) => a.alertLevel.trim().toLowerCase() != 'critical')
        .length;

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
              color:
                  isLight ? const Color(0xFF4e6473) : const Color(0xFF9db7d2),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _showCreateAlertDialog(context, ref),
              icon: const Icon(Icons.add_alert),
              label: const Text('Add Alert'),
            ),
          ),
          const SizedBox(height: 18),
          _buildSummaryCards(
            activeCount: activeCount,
            criticalCount: criticalCount,
            warningCount: warningCount,
          ),
          const SizedBox(height: 16),
          _buildActiveAlertsPanel(
            context,
            allAlerts,
            onAcknowledge: (alertId) async {
              await AlertsApi.resolveAlert(alertId);
              ref.invalidate(userAdminAlertsApiProvider);
            },
            onEdit: (alert) => _showEditAlertDialog(context, ref, alert),
            onDelete: (alert) => _deleteAlert(context, ref, alert),
          ),
        ],
      ),
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
            Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF071d28)
                : const Color(0xFFD8E8F5),
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
                  color: isLight
                      ? const Color(0xFF1a303c)
                      : const Color(0xFFD8E8F5),
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
                        fontSize: veryCompact ? 17 : (compact ? 20 : 28),
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
    List<Alert> alerts, {
    required Future<void> Function(String alertId) onAcknowledge,
    required Future<void> Function(Alert alert) onEdit,
    required Future<void> Function(Alert alert) onDelete,
  }) {
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
            'Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color:
                  isLight ? const Color(0xFF132733) : const Color(0xFFD8E8F5),
            ),
          ),
          const SizedBox(height: 14),
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No alerts found',
                style: TextStyle(
                  color: isLight
                      ? const Color(0xFF60717c)
                      : const Color(0xFF9FB4C6),
                ),
              ),
            ),
          ...alerts.map((alert) {
            final isCritical =
                alert.alertLevel.trim().toLowerCase() == 'critical';
            final messageText =
                alert.message.trim().isEmpty ? '-' : alert.message.trim();
            final statusText =
                alert.status.trim().isEmpty ? '-' : alert.status.trim();
            final sensorText =
                alert.sensorId.trim().isEmpty ? '-' : alert.sensorId.trim();
            final sensorParameterText = alert.sensorParameterId.trim().isEmpty
                ? '-'
                : alert.sensorParameterId.trim();
            final assignedToText =
                alert.assignedTo.trim().isEmpty ? '-' : alert.assignedTo.trim();
            final acknowledgedText = alert.acknowledgedAt == null
                ? '-'
                : _formatDate(alert.acknowledgedAt!);
            final resolvedText =
                alert.resolvedAt == null ? '-' : _formatDate(alert.resolvedAt!);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isLight ? const Color(0xFFF2F6F8) : const Color(0xFF223B4E),
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
                                    ? const Color(0xFFef2e38)
                                    : const Color(0xFFd39a00),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                messageText,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isLight
                                      ? const Color(0xFF1a2f3b)
                                      : const Color(0xFFE2EDF8),
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
                            color: isLight
                                ? const Color(0xFF506775)
                                : const Color(0xFF9FB4C6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Status: $statusText',
                          style: TextStyle(
                            fontSize: 13,
                            color: isLight
                                ? const Color(0xFF506775)
                                : const Color(0xFF9FB4C6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sensor: $sensorText | Parameter: $sensorParameterText',
                          style: TextStyle(
                            fontSize: 13,
                            color: isLight
                                ? const Color(0xFF506775)
                                : const Color(0xFF9FB4C6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Assigned To: $assignedToText',
                          style: TextStyle(
                            fontSize: 13,
                            color: isLight
                                ? const Color(0xFF506775)
                                : const Color(0xFF9FB4C6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Acknowledged: $acknowledgedText | Resolved: $resolvedText',
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
                            _actionButton(
                              context,
                              label: 'Acknowledge',
                              onTap: alert.id.trim().isEmpty
                                  ? () {}
                                  : () => onAcknowledge(alert.id),
                            ),
                            _actionButton(
                              context,
                              label: 'View Details',
                              onTap: () => _showDetails(context, alert),
                            ),
                            _actionButton(
                              context,
                              label: 'Edit',
                              onTap: () => onEdit(alert),
                            ),
                            _actionButton(
                              context,
                              label: 'Delete',
                              onTap: () => onDelete(alert),
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
                              messageText,
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
                            const SizedBox(height: 6),
                            Text(
                              'Status: $statusText',
                              style: TextStyle(
                                fontSize: 13,
                                color: isLight
                                    ? const Color(0xFF506775)
                                    : const Color(0xFF9FB4C6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sensor: $sensorText | Parameter: $sensorParameterText',
                              style: TextStyle(
                                fontSize: 13,
                                color: isLight
                                    ? const Color(0xFF506775)
                                    : const Color(0xFF9FB4C6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Assigned To: $assignedToText',
                              style: TextStyle(
                                fontSize: 13,
                                color: isLight
                                    ? const Color(0xFF506775)
                                    : const Color(0xFF9FB4C6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Acknowledged: $acknowledgedText | Resolved: $resolvedText',
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
                                _actionButton(
                                  context,
                                  label: 'Acknowledge',
                                  onTap: alert.id.trim().isEmpty
                                      ? () {}
                                      : () => onAcknowledge(alert.id),
                                ),
                                _actionButton(
                                  context,
                                  label: 'View Details',
                                  onTap: () => _showDetails(context, alert),
                                ),
                                _actionButton(
                                  context,
                                  label: 'Edit',
                                  onTap: () => onEdit(alert),
                                ),
                                _actionButton(
                                  context,
                                  label: 'Delete',
                                  onTap: () => onDelete(alert),
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
            color: isLight ? const Color(0xFF203845) : const Color(0xFFD8E8F5),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
