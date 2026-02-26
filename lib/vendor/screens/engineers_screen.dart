import 'package:flutter/material.dart';

import '../../super_admin/core/theme/custom_theme_tokens.dart';

enum _EngineerTab { team, schedule }

class VendorEngineersScreen extends StatefulWidget {
  const VendorEngineersScreen({super.key});

  @override
  State<VendorEngineersScreen> createState() => _VendorEngineersScreenState();
}

class _VendorEngineersScreenState extends State<VendorEngineersScreen> {
  _EngineerTab _activeTab = _EngineerTab.team;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<CustomThemeTokens>()!;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Engineer Operations',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: tokens.heading,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Track team capacity and schedule execution for vendor sites.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.subheading,
              ),
            ),
            const SizedBox(height: 14),
            _topCards(context),
            const SizedBox(height: 10),
            _segmentedTabBar(context),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _activeTab == _EngineerTab.team
                    ? const _TeamView(key: ValueKey('team-tab'))
                    : const _ScheduleView(key: ValueKey('schedule-tab')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        if (compact) {
          return const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 220,
                child: _TopMetricCard(
                  title: 'TOTAL ENGINEER',
                  value: '12',
                  subtitle: 'Active roster',
                  icon: Icons.groups_outlined,
                ),
              ),
              SizedBox(
                width: 220,
                child: _TopMetricCard(
                  title: 'NETWORK ENG',
                  value: '4',
                  subtitle: 'Connectivity',
                  icon: Icons.router_outlined,
                ),
              ),
              SizedBox(
                width: 220,
                child: _TopMetricCard(
                  title: 'FIELD ENG',
                  value: '5',
                  subtitle: 'On ground',
                  icon: Icons.engineering_outlined,
                ),
              ),
              SizedBox(
                width: 220,
                child: _TopMetricCard(
                  title: 'FIRMWARE ENG',
                  value: '3',
                  subtitle: 'Edge updates',
                  icon: Icons.memory_outlined,
                ),
              ),
            ],
          );
        }
        return const Row(
          children: [
            Expanded(
              child: _TopMetricCard(
                title: 'TOTAL ENGINEER',
                value: '12',
                subtitle: 'Active roster',
                icon: Icons.groups_outlined,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _TopMetricCard(
                title: 'NETWORK ENG',
                value: '4',
                subtitle: 'Connectivity',
                icon: Icons.router_outlined,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _TopMetricCard(
                title: 'FIELD ENG',
                value: '5',
                subtitle: 'On ground',
                icon: Icons.engineering_outlined,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _TopMetricCard(
                title: 'FIRMWARE ENG',
                value: '3',
                subtitle: 'Edge updates',
                icon: Icons.memory_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _segmentedTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      (_EngineerTab.team, Icons.groups_outlined, 'Team'),
      (_EngineerTab.schedule, Icons.event_note_outlined, 'Schedule'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.extension<CustomThemeTokens>()!.softPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: items.map((item) {
          final selected = item.$1 == _activeTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = item.$1),
              child: Container(
                margin: const EdgeInsets.all(2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? theme.cardColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      selected ? Border.all(color: theme.dividerColor) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$2,
                      size: 18,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(item.$3,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _TopMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
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
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(title,
              style:
                  const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
          Text(subtitle, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _TeamView extends StatelessWidget {
  const _TeamView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListView(
        children: const [
          _EngineerTile(
            name: 'Arun Patel',
            role: 'Network Engineer',
            status: 'On Site',
            color: Color(0xFF4D7DFF),
          ),
          _EngineerTile(
            name: 'Mira Joseph',
            role: 'Firmware Engineer',
            status: 'Available',
            color: Color(0xFF1E9B63),
          ),
          _EngineerTile(
            name: 'Nikhil Rao',
            role: 'Field Engineer',
            status: 'Traveling',
            color: Color(0xFFDA8C16),
          ),
          _EngineerTile(
            name: 'Ria Sen',
            role: 'Field Engineer',
            status: 'Available',
            color: Color(0xFF1E9B63),
          ),
        ],
      ),
    );
  }
}

class _ScheduleView extends StatelessWidget {
  const _ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<CustomThemeTokens>()!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListView(
        children: [
          const _ScheduleCard(
            title: 'North Plant Router Migration',
            when: 'Today, 2:00 PM',
            engineers: 'Arun, Ria',
          ),
          const _ScheduleCard(
            title: 'Zone C Sensor Audit',
            when: 'Tomorrow, 10:30 AM',
            engineers: 'Nikhil',
          ),
          const _ScheduleCard(
            title: 'Warehouse 2 Firmware Patch',
            when: 'Friday, 9:00 AM',
            engineers: 'Mira',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.softPanel.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Schedule Note: 2 engineers available for urgent assignment after 4:30 PM.',
              style: TextStyle(color: tokens.subheading),
            ),
          ),
        ],
      ),
    );
  }
}

class _EngineerTile extends StatelessWidget {
  final String name;
  final String role;
  final String status;
  final Color color;

  const _EngineerTile({
    required this.name,
    required this.role,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(Icons.engineering, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(role, style: const TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: color.withValues(alpha: 0.12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final String title;
  final String when;
  final String engineers;

  const _ScheduleCard({
    required this.title,
    required this.when,
    required this.engineers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(when, style: const TextStyle(fontSize: 12.5)),
          const SizedBox(height: 2),
          Text('Engineers: $engineers', style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }
}
