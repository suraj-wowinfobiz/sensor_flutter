import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/ops_theme.dart';
import '../providers/super_admin_backend_provider.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SuperAdminBackendProvider>(
      builder: (context, db, child) {
        final items = [
          _StatData(
            icon: Icons.business,
            value: db.getStats('organizations').toString(),
            label: 'Organizations',
          ),
          _StatData(
            icon: Icons.location_on,
            value: db.getStats('sites').toString(),
            label: 'Sites',
          ),
          _StatData(
            icon: Icons.sensors,
            value: db.getStats('sensors').toString(),
            label: 'Sensors',
          ),
          _StatData(
            icon: Icons.notifications,
            value: db.getStats('alerts').toString(),
            label: 'Active Alerts',
          ),
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1180
                  ? 4
                  : width >= 760
                      ? 2
                      : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 116,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildStatCard(
                    context,
                    icon: item.icon,
                    value: item.value,
                    label: item.label,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OpsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: OpsColors.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: OpsColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 32 / 28,
                    fontWeight: FontWeight.w700,
                    color: OpsColors.text,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: OpsColors.muted,
                    letterSpacing: .4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;

  const _StatData({
    required this.icon,
    required this.value,
    required this.label,
  });
}
