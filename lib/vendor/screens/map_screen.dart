import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../super_admin/core/theme/custom_theme_tokens.dart';

class VendorMapScreen extends StatelessWidget {
  const VendorMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<CustomThemeTokens>()!;

    const center = LatLng(19.0760, 72.8777);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Street Map Monitoring',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: tokens.heading,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'OpenStreetMap with drag and zoom controls for live vendor operations.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: tokens.subheading),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 980;
                final mapPanel = _mapPanel(context, center);
                final sidePanel = _mapEventsPanel(context);
                if (compact) {
                  return Column(
                    children: [
                      mapPanel,
                      const SizedBox(height: 10),
                      sidePanel,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: mapPanel),
                    const SizedBox(width: 10),
                    Expanded(flex: 4, child: sidePanel),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            const _MapStats(),
            const SizedBox(height: 12),
            _mapActionCards(context),
          ],
        ),
      ),
    );
  }

  Widget _mapPanel(BuildContext context, LatLng center) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      height: 410,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.07 : 0.16),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color:
                  isLight ? const Color(0xFFF5FAFD) : const Color(0xFF223B4E),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Live Street Map',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                  ),
                  child: Text(
                    'Drag + Zoom',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 11,
                      minZoom: 3,
                      maxZoom: 18,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.drag |
                            InteractiveFlag.pinchZoom |
                            InteractiveFlag.doubleTapZoom |
                            InteractiveFlag.flingAnimation,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.industrial.tilt.vendor',
                      ),
                      MarkerLayer(
                        markers: [
                          _marker(const LatLng(19.085, 72.882), 'Plant A',
                              const Color(0xFF1E9B63)),
                          _marker(const LatLng(19.061, 72.910), 'Zone C',
                              const Color(0xFFDA8C16)),
                          _marker(const LatLng(19.092, 72.839), 'Warehouse 2',
                              const Color(0xFF1E9B63)),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(
                            fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
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

  Marker _marker(LatLng point, String label, Color color) {
    return Marker(
      point: point,
      width: 110,
      height: 62,
      child: Column(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapEventsPanel(BuildContext context) {
    final tokens = Theme.of(context).extension<CustomThemeTokens>()!;
    return Container(
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
            'Map Events',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _event('11:14', 'Arun reached North Plant gate'),
          _event('12:02', 'Zone C vibration trend increased'),
          _event('12:40', 'Mira route updated via map drag/zoom review'),
          const SizedBox(height: 8),
          Text(
            'Drag map to inspect adjacent zones and zoom in to verify street-level site access.',
            style: TextStyle(fontSize: 12.5, color: tokens.subheading),
          ),
        ],
      ),
    );
  }

  Widget _event(String time, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child:
                Text(time, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _mapActionCards(BuildContext context) {
    final tokens = Theme.of(context).extension<CustomThemeTokens>()!;
    return Container(
      width: double.infinity,
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
            'Live Map Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _mapChip(
                context,
                Icons.notification_important_outlined,
                'Send Geo Alert',
              ),
              _mapChip(
                context,
                Icons.person_pin_circle_outlined,
                'Track Engineer',
              ),
              _mapChip(
                context,
                Icons.route_outlined,
                'Optimized Route',
              ),
              _mapChip(
                context,
                Icons.layers_outlined,
                'Toggle Site Layer',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tip: Use map drag + zoom to verify access roads before dispatching teams.',
            style: TextStyle(fontSize: 12.5, color: tokens.subheading),
          ),
        ],
      ),
    );
  }

  Widget _mapChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).extension<CustomThemeTokens>()!.softPanel,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _MapStats extends StatelessWidget {
  const _MapStats();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 740;
        if (compact) {
          return const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 220,
                child: _StatCard(
                  title: 'Mapped Streets',
                  value: '57',
                  icon: Icons.alt_route,
                ),
              ),
              SizedBox(
                width: 220,
                child: _StatCard(
                  title: 'Engineer Route Updates',
                  value: '23',
                  icon: Icons.navigation_outlined,
                ),
              ),
              SizedBox(
                width: 220,
                child: _StatCard(
                  title: 'Issue Zones',
                  value: '2',
                  icon: Icons.warning_amber_outlined,
                ),
              ),
            ],
          );
        }
        return const Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Mapped Streets',
                value: '57',
                icon: Icons.alt_route,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                title: 'Engineer Route Updates',
                value: '23',
                icon: Icons.navigation_outlined,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                title: 'Issue Zones',
                value: '2',
                icon: Icons.warning_amber_outlined,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
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
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }
}
