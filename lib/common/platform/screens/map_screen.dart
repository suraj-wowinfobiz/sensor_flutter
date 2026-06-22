import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/ops_theme.dart';
import '../providers/super_admin_riverpod_provider.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final organizations = db.organizations;
    final sites = db.sites;
    final zones = db.zones;

    return OpsPage(
      title: 'Site Map',
      subtitle:
          'Location-focused overview for organizations, sites, and mapped operational zones.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _MapMetricCard(
                label: 'Organizations',
                value: '${organizations.length}',
                icon: Icons.business_outlined,
              ),
              _MapMetricCard(
                label: 'Sites',
                value: '${sites.length}',
                icon: Icons.location_city_outlined,
              ),
              _MapMetricCard(
                label: 'Zones',
                value: '${zones.length}',
                icon: Icons.map_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: OpsColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: OpsColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.public_outlined,
                      color: OpsColors.primaryContainer,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Map Workspace',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: OpsColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  sites.isEmpty
                      ? 'No site map data is available yet. As soon as organizations, sites, and zones are loaded, this vendor workspace can use them for geographic monitoring.'
                      : 'This shared map destination is wired for vendor login and summarizes the current site hierarchy for location-based operations.',
                  style: const TextStyle(
                    color: OpsColors.muted,
                    height: 1.5,
                  ),
                ),
                if (sites.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ...sites.take(6).map(
                        (site) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: OpsColors.surfaceLow,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: OpsColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: OpsColors.primary
                                        .withValues(alpha: .08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.place_outlined,
                                    color: OpsColors.primaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        site.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: OpsColors.text,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        site.location,
                                        style: const TextStyle(
                                          color: OpsColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMetricCard extends StatelessWidget {
  const _MapMetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OpsColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OpsColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: OpsColors.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: OpsColors.primaryContainer),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: OpsColors.text,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: OpsColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
