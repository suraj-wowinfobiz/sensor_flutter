import 'package:flutter/material.dart';

class VendorSiteAllocationScreen extends StatefulWidget {
  const VendorSiteAllocationScreen({super.key});

  @override
  State<VendorSiteAllocationScreen> createState() =>
      _VendorSiteAllocationScreenState();
}

class _VendorSiteAllocationScreenState
    extends State<VendorSiteAllocationScreen> {
  String _selectedOrganization = 'Titan Infra';
  String _selectedSite = 'North Plant';
  String _selectedEngineer = 'Arun Patel';

  final Map<String, List<_SiteRecord>> _orgSites = const {
    'Titan Infra': [
      _SiteRecord(
        name: 'North Plant',
        status: 'High',
        engineers: [
          _EngineerRecord(
            name: 'Arun Patel',
            role: 'Network Engineer',
            skills: ['Routing', 'Switching', 'Firewall'],
          ),
          _EngineerRecord(
            name: 'Ria Sen',
            role: 'Field Engineer',
            skills: ['Commissioning', 'Diagnostics', 'Maintenance'],
          ),
        ],
      ),
      _SiteRecord(
        name: 'Zone C',
        status: 'Medium',
        engineers: [
          _EngineerRecord(
            name: 'Nikhil Rao',
            role: 'Field Engineer',
            skills: ['Sensor Replacement', 'Wiring', 'Calibration'],
          ),
        ],
      ),
      _SiteRecord(
        name: 'Warehouse 2',
        status: 'High',
        engineers: [
          _EngineerRecord(
            name: 'Mira Joseph',
            role: 'Firmware Engineer',
            skills: ['Firmware Patch', 'Gateway OTA', 'Debugging'],
          ),
        ],
      ),
    ],
    'Axis Utilities': [
      _SiteRecord(
        name: 'South Yard',
        status: 'Low',
        engineers: [
          _EngineerRecord(
            name: 'Karan Batra',
            role: 'Field Engineer',
            skills: ['Survey', 'Installation', 'Safety Audit'],
          ),
          _EngineerRecord(
            name: 'Asha Nair',
            role: 'Network Engineer',
            skills: ['LAN Setup', 'VPN', 'Access Point'],
          ),
        ],
      ),
      _SiteRecord(
        name: 'Dockline 4',
        status: 'Medium',
        engineers: [
          _EngineerRecord(
            name: 'Ishita Roy',
            role: 'Firmware Engineer',
            skills: ['Edge Config', 'OTA', 'Rollback'],
          ),
        ],
      ),
    ],
    'BluePeak Systems': [
      _SiteRecord(
        name: 'Metro Hub',
        status: 'Medium',
        engineers: [
          _EngineerRecord(
            name: 'Dev Shah',
            role: 'Network Engineer',
            skills: ['Backhaul', 'QoS', 'Routing'],
          ),
          _EngineerRecord(
            name: 'Priya Das',
            role: 'Field Engineer',
            skills: ['Sensor Audit', 'Actuator Test', 'Validation'],
          ),
        ],
      ),
      _SiteRecord(
        name: 'Plant West',
        status: 'Low',
        engineers: [
          _EngineerRecord(
            name: 'Rahul Jain',
            role: 'Field Engineer',
            skills: ['Maintenance', 'Inspection', 'Reporting'],
          ),
        ],
      ),
    ],
  };

  List<_SiteRecord> get _sitesForSelectedOrg =>
      _orgSites[_selectedOrganization] ?? const [];

  _SiteRecord? get _selectedSiteRecord {
    for (final s in _sitesForSelectedOrg) {
      if (s.name == _selectedSite) return s;
    }
    return null;
  }

  List<_EngineerRecord> get _engineersForSelectedSite =>
      _selectedSiteRecord?.engineers ?? const [];

  _EngineerRecord? get _selectedEngineerRecord {
    for (final e in _engineersForSelectedSite) {
      if (e.name == _selectedEngineer) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    if (_sitesForSelectedOrg.isNotEmpty &&
        !_sitesForSelectedOrg.any((s) => s.name == _selectedSite)) {
      _selectedSite = _sitesForSelectedOrg.first.name;
    }
    if (_engineersForSelectedSite.isNotEmpty &&
        !_engineersForSelectedSite.any((e) => e.name == _selectedEngineer)) {
      _selectedEngineer = _engineersForSelectedSite.first.name;
    }

    final totalSites =
        _orgSites.values.fold<int>(0, (sum, sites) => sum + sites.length);
    final totalEngineers = _orgSites.values
        .expand((sites) => sites)
        .fold<int>(0, (sum, site) => sum + site.engineers.length);

    final viewportHeight = MediaQuery.of(context).size.height;
    final desktopCardHeight =
        (viewportHeight - 250).clamp(380.0, 760.0).toDouble();
    const mobileCardHeight = 420.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Site Allocation Hierarchy',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: isLight
                          ? const Color(0xFF0f202d)
                          : const Color(0xFFd4e4ef),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage organizations, sites, engineers, and skill mapping',
                    style: TextStyle(
                      fontSize: 15,
                      color: isLight
                          ? const Color(0xFF4e6473)
                          : const Color(0xFF9db7d2),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _infoChip('${_orgSites.length} Orgs'),
                  _infoChip('$totalSites Sites'),
                  _infoChip('$totalEngineers Engineers'),
                  _infoChip(
                      '${_selectedSiteRecord?.engineers.length ?? 0} Active'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              if (width < 900) {
                return Column(
                  children: [
                    _columnCard(
                      title: 'Organizations',
                      icon: Icons.business,
                      height: mobileCardHeight,
                      child: _organizationsList(),
                    ),
                    const SizedBox(height: 12),
                    _columnCard(
                      title: 'Sites',
                      icon: Icons.map_outlined,
                      height: mobileCardHeight,
                      child: _sitesList(),
                    ),
                    const SizedBox(height: 12),
                    _columnCard(
                      title: 'Engineers',
                      icon: Icons.engineering_outlined,
                      height: mobileCardHeight,
                      child: _engineersList(),
                    ),
                    const SizedBox(height: 12),
                    _columnCard(
                      title: 'Current Working',
                      icon: Icons.tune,
                      height: mobileCardHeight,
                      child: _currentWorkingList(),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _columnCard(
                      title: 'Organizations',
                      icon: Icons.business,
                      height: desktopCardHeight,
                      child: _organizationsList(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _columnCard(
                      title: 'Sites',
                      icon: Icons.map_outlined,
                      height: desktopCardHeight,
                      child: _sitesList(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _columnCard(
                      title: 'Engineers',
                      icon: Icons.engineering_outlined,
                      height: desktopCardHeight,
                      child: _engineersList(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _columnCard(
                      title: 'Current Working',
                      icon: Icons.tune,
                      height: desktopCardHeight,
                      child: _currentWorkingList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _organizationsList() {
    if (_orgSites.isEmpty) {
      return const _EmptyHint(text: 'No organizations yet');
    }

    return Column(
      children: _orgSites.keys.map((org) {
        final selected = org == _selectedOrganization;
        final siteCount = _orgSites[org]!.length;
        return _ListTileCard(
          selected: selected,
          title: org,
          subtitle: 'Organization',
          badge: '$siteCount sites',
          onTap: () {
            setState(() {
              _selectedOrganization = org;
              _selectedSite = _orgSites[org]!.first.name;
              _selectedEngineer = _orgSites[org]!.first.engineers.first.name;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _sitesList() {
    if (_sitesForSelectedOrg.isEmpty) {
      return const _EmptyHint(text: 'No sites in this organization');
    }

    return Column(
      children: _sitesForSelectedOrg.map((site) {
        final selected = site.name == _selectedSite;
        return _ListTileCard(
          selected: selected,
          title: site.name,
          subtitle: '${site.engineers.length} engineers working',
          badge: site.status,
          onTap: () {
            setState(() {
              _selectedSite = site.name;
              _selectedEngineer = site.engineers.first.name;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _engineersList() {
    if (_engineersForSelectedSite.isEmpty) {
      return const _EmptyHint(text: 'No engineers in this site');
    }

    return Column(
      children: _engineersForSelectedSite.map((eng) {
        final selected = eng.name == _selectedEngineer;
        return _ListTileCard(
          selected: selected,
          title: eng.name,
          subtitle: eng.role,
          badge: '${eng.skills.length} skills',
          onTap: () => setState(() => _selectedEngineer = eng.name),
        );
      }).toList(),
    );
  }

  Widget _currentWorkingList() {
    final eng = _selectedEngineerRecord;
    if (eng == null) {
      return const _EmptyHint(text: 'Select an engineer');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ListTileCard(
          selected: true,
          title: eng.name,
          subtitle: eng.role,
          badge: 'On Duty',
          onTap: () {},
        ),
        _workCard(
          icon: Icons.work_outline,
          label: 'Current Task',
          value: 'Sensor network stability audit',
        ),
        _workCard(
          icon: Icons.av_timer_outlined,
          label: 'Shift ETA',
          value: 'Completes in 2h 15m',
        ),
        _workCard(
          icon: Icons.place_outlined,
          label: 'Working Location',
          value: _selectedSite,
        ),
        const SizedBox(height: 6),
        _actionButton(
          icon: Icons.notification_important_outlined,
          label: 'Send Alert',
          onTap: () => _showSnack('Alert sent for $_selectedSite'),
        ),
        const SizedBox(height: 6),
        _actionButton(
          icon: Icons.call_outlined,
          label: 'Contact Engineer',
          onTap: () => _showSnack('Contact request sent to ${eng.name}'),
        ),
      ],
    );
  }

  Widget _workCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFFF4F8FB)
            : const Color(0xFF253F52),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF4C7084)
                : const Color(0xFFBBD0E0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF4C7084)
                        : const Color(0xFFBBD0E0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF1f3642)
                        : const Color(0xFFE2EDF8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _columnCard({
    required String title,
    required IconData icon,
    required double height,
    required Widget child,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  isLight ? const Color(0xFFF5FAFD) : const Color(0xFF1f3342),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isLight
                        ? const Color(0xFFDBEDF8)
                        : const Color(0xFF315066),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    icon,
                    size: 17,
                    color: isLight
                        ? const Color(0xFF1271a0)
                        : const Color(0xFFD7E8F6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isLight
                          ? const Color(0xFF132733)
                          : const Color(0xFFD8E8F5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(child: child),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF3F8FC) : const Color(0xFF243E52),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isLight ? const Color(0xFF2B404D) : const Color(0xFFD7E8F6),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
          color: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFFF4F8FB)
              : const Color(0xFF253F52),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTileCard extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _ListTileCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final scheme = theme.colorScheme;
    final selectedStart = Color.alphaBlend(
      scheme.primary.withValues(alpha: isLight ? 0.18 : 0.34),
      theme.cardColor,
    );
    final selectedEnd = Color.alphaBlend(
      scheme.primary.withValues(alpha: isLight ? 0.1 : 0.24),
      theme.cardColor,
    );
    final normalStart = Color.alphaBlend(
      scheme.primary.withValues(alpha: isLight ? 0.04 : 0.1),
      theme.cardColor,
    );
    final normalEnd = Color.alphaBlend(
      scheme.primary.withValues(alpha: isLight ? 0.02 : 0.06),
      theme.cardColor,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(colors: [selectedStart, selectedEnd])
                  : LinearGradient(colors: [normalStart, normalEnd]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? scheme.primary.withValues(alpha: isLight ? 0.6 : 0.75)
                    : theme.dividerColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? scheme.primary
                            : scheme.onSurface.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (selected) ...[
                      Container(
                        width: 14,
                        height: 2,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(
                            alpha: isLight ? 0.7 : 0.9,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.78),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                if (badge != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(
                        alpha: isLight ? 0.14 : 0.28,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (selected)
            Positioned(
              left: 0,
              top: 14,
              bottom: 22,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: isLight ? 0.75 : 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SiteRecord {
  final String name;
  final String status;
  final List<_EngineerRecord> engineers;

  const _SiteRecord({
    required this.name,
    required this.status,
    required this.engineers,
  });
}

class _EngineerRecord {
  final String name;
  final String role;
  final List<String> skills;

  const _EngineerRecord({
    required this.name,
    required this.role,
    required this.skills,
  });
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFFF4F8FB)
            : const Color(0xFF253F52),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFF4C7084)
              : const Color(0xFFBBD0E0),
        ),
      ),
    );
  }
}
