import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1200
                  ? 4
                  : width >= 900
                      ? 2
                      : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: width >= 1100
                      ? 2.1
                      : width >= 700
                          ? 2.6
                          : width >= 430
                              ? 3.2
                              : 2.6,
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 26, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF0a1a2a)
                        : const Color(0xFFe8f1fc),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF4a6b8a)
                        : const Color(0xFF8aaac9),
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
