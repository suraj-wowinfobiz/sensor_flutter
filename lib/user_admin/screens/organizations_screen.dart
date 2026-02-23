import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/organization.dart';
import '../models/site.dart';
import '../models/zone.dart';
import '../providers/user_admin_database_provider.dart';
import '../widgets/crud_modal.dart';

class UserAdminOrganizationsScreen extends StatefulWidget {
  const UserAdminOrganizationsScreen({super.key});

  @override
  State<UserAdminOrganizationsScreen> createState() =>
      _UserAdminOrganizationsScreenState();
}

class _UserAdminOrganizationsScreenState
    extends State<UserAdminOrganizationsScreen> {
  String? _selectedOrganizationId;
  String? _selectedSiteId;
  String? _selectedZoneId;

  void _ensureSelections(UserAdminDatabaseProvider db) {
    if (db.organizations.isNotEmpty &&
        (_selectedOrganizationId == null ||
            db.organizations.every((o) => o.id != _selectedOrganizationId))) {
      _selectedOrganizationId = db.organizations.first.id;
    }

    final sites = db.sites
        .where((s) => s.organizationId == _selectedOrganizationId)
        .toList();
    if (sites.isNotEmpty &&
        (_selectedSiteId == null ||
            sites.every((s) => s.id != _selectedSiteId))) {
      _selectedSiteId = sites.first.id;
    }
    if (sites.isEmpty) _selectedSiteId = null;

    final zones = db.zones.where((z) => z.siteId == _selectedSiteId).toList();
    if (zones.isNotEmpty &&
        (_selectedZoneId == null ||
            zones.every((z) => z.id != _selectedZoneId))) {
      _selectedZoneId = zones.first.id;
    }
    if (zones.isEmpty) _selectedZoneId = null;
  }

  void _showOrganizationModal({
    Organization? organization,
    required UserAdminDatabaseProvider db,
  }) {
    var name = organization?.name ?? '';
    var email = organization?.email ?? '';
    var status = organization?.status ?? 'active';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return UserAdminCrudModal(
            title:
                organization == null ? 'Add Organization' : 'Edit Organization',
            fields: [
              {
                'label': 'Name',
                'value': name,
                'onChanged': (String value) => setState(() => name = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'Email',
                'value': email,
                'onChanged': (String value) => setState(() => email = value),
                'keyboardType': TextInputType.emailAddress,
              },
              {
                'label': 'Status',
                'type': 'select',
                'value': status,
                'onChanged': (String? value) =>
                    setState(() => status = value ?? status),
                'options': const [
                  {'label': 'Active', 'value': 'active'},
                  {'label': 'Inactive', 'value': 'inactive'},
                  {'label': 'Suspended', 'value': 'suspended'},
                ],
              },
            ],
            onSave: () {
              if (organization == null) {
                db.create('organizations', {
                  'name': name,
                  'email': email,
                  'status': status,
                  'owner_user_id': db.users.first.id,
                });
              } else {
                db.update('organizations', organization.id, {
                  'name': name,
                  'email': email,
                  'status': status,
                });
              }
              Navigator.pop(context);
            },
            onCancel: () => Navigator.pop(context),
          );
        },
      ),
    );
  }

  void _showSiteModal({Site? site, required UserAdminDatabaseProvider db}) {
    if (_selectedOrganizationId == null && site == null) return;

    var name = site?.name ?? '';
    var location = site?.location ?? '';
    var organizationId = site?.organizationId ?? _selectedOrganizationId!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return UserAdminCrudModal(
            title: site == null ? 'Add Site' : 'Edit Site',
            fields: [
              {
                'label': 'Name',
                'value': name,
                'onChanged': (String value) => setState(() => name = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'Location',
                'value': location,
                'onChanged': (String value) => setState(() => location = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'Organization',
                'type': 'select',
                'value': organizationId,
                'onChanged': (String? value) =>
                    setState(() => organizationId = value ?? organizationId),
                'options': db.organizations
                    .map((o) => {'label': o.name, 'value': o.id})
                    .toList(),
              },
            ],
            onSave: () {
              if (site == null) {
                db.create('sites', {
                  'name': name,
                  'location': location,
                  'organization_id': organizationId,
                });
              } else {
                db.update('sites', site.id, {
                  'name': name,
                  'location': location,
                  'organization_id': organizationId,
                });
              }
              Navigator.pop(context);
            },
            onCancel: () => Navigator.pop(context),
          );
        },
      ),
    );
  }

  void _showZoneModal({Zone? zone, required UserAdminDatabaseProvider db}) {
    if (_selectedSiteId == null && zone == null) return;

    var name = zone?.name ?? '';
    var siteId = zone?.siteId ?? _selectedSiteId!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return UserAdminCrudModal(
            title: zone == null ? 'Add Zone' : 'Edit Zone',
            fields: [
              {
                'label': 'Name',
                'value': name,
                'onChanged': (String value) => setState(() => name = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'Site',
                'type': 'select',
                'value': siteId,
                'onChanged': (String? value) =>
                    setState(() => siteId = value ?? siteId),
                'options': db.sites
                    .map((s) => {'label': s.name, 'value': s.id})
                    .toList(),
              },
            ],
            onSave: () {
              if (zone == null) {
                db.create('zones', {
                  'name': name,
                  'site_id': siteId,
                });
              } else {
                db.update('zones', zone.id, {
                  'name': name,
                  'site_id': siteId,
                });
              }
              Navigator.pop(context);
            },
            onCancel: () => Navigator.pop(context),
          );
        },
      ),
    );
  }

  void _addSampleData(UserAdminDatabaseProvider db) {
    if (db.organizations.isNotEmpty) return;
    db.create('organizations', {
      'name': 'Default Organization',
      'email': 'contact@defaultorg.com',
      'status': 'active',
      'owner_user_id': db.users.first.id,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserAdminDatabaseProvider>(
      builder: (context, db, child) {
        final isLight = Theme.of(context).brightness == Brightness.light;
        _ensureSelections(db);

        final organizations = db.organizations;
        final sites = db.sites
            .where((s) => s.organizationId == _selectedOrganizationId)
            .toList();
        final zones =
            db.zones.where((z) => z.siteId == _selectedSiteId).toList();
        final locations = db.devices
            .where((d) => d.zoneId == _selectedZoneId)
            .map((d) => d.deviceCode)
            .toList();

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
                        'Organization Hierarchy',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFF0f202d)
                                  : const Color(0xFFd4e4ef),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage organizations, sites, zones, and sensor locations',
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
                      _chipButton(
                        label: 'Add Sample Data',
                        icon: Icons.auto_awesome,
                        onTap: () => _addSampleData(db),
                      ),
                      _infoChip('${organizations.length} Orgs'),
                      _infoChip('${db.sites.length} Sites'),
                      _infoChip('${db.zones.length} Zones'),
                      _infoChip('${db.devices.length} Locations'),
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
                          onAdd: () => _showOrganizationModal(db: db),
                          child: _buildOrganizationsList(organizations, db),
                        ),
                        const SizedBox(height: 12),
                        _columnCard(
                          title: 'Sites',
                          icon: Icons.map_outlined,
                          onAdd: _selectedOrganizationId == null
                              ? null
                              : () => _showSiteModal(db: db),
                          child: _buildSitesList(sites, db),
                        ),
                        const SizedBox(height: 12),
                        _columnCard(
                          title: 'Zones',
                          icon: Icons.layers_outlined,
                          onAdd: _selectedSiteId == null
                              ? null
                              : () => _showZoneModal(db: db),
                          child: _buildZonesList(zones, db),
                        ),
                        const SizedBox(height: 12),
                        _columnCard(
                          title: 'Locations',
                          icon: Icons.location_on_outlined,
                          child: _buildLocationsList(locations),
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
                          onAdd: () => _showOrganizationModal(db: db),
                          child: _buildOrganizationsList(organizations, db),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _columnCard(
                          title: 'Sites',
                          icon: Icons.map_outlined,
                          onAdd: _selectedOrganizationId == null
                              ? null
                              : () => _showSiteModal(db: db),
                          child: _buildSitesList(sites, db),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _columnCard(
                          title: 'Zones',
                          icon: Icons.layers_outlined,
                          onAdd: _selectedSiteId == null
                              ? null
                              : () => _showZoneModal(db: db),
                          child: _buildZonesList(zones, db),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _columnCard(
                          title: 'Locations',
                          icon: Icons.location_on_outlined,
                          child: _buildLocationsList(locations),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _columnCard({
    required String title,
    required IconData icon,
    required Widget child,
    VoidCallback? onAdd,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      constraints: const BoxConstraints(minHeight: 600),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.07 : 0.16),
            blurRadius: 16,
            offset: Offset(0, 6),
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
              borderRadius: BorderRadius.only(
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
                      fontSize: 20 > 18 ? 20 - 2 : 18,
                      fontWeight: FontWeight.w800,
                      color: isLight
                          ? const Color(0xFF132733)
                          : const Color(0xFFD8E8F5),
                    ),
                  ),
                ),
                if (onAdd != null)
                  InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isLight
                            ? const Color(0xFFE6EFF3)
                            : const Color(0xFF243E52),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Icon(
                        Icons.add,
                        color: isLight
                            ? const Color(0xFF203845)
                            : const Color(0xFFD7E8F6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationsList(
      List<Organization> organizations, UserAdminDatabaseProvider db) {
    if (organizations.isEmpty) {
      return const _EmptyHint(text: 'No organizations yet');
    }
    return Column(
      children: organizations.map((org) {
        final selected = org.id == _selectedOrganizationId;
        final sitesCount =
            db.sites.where((s) => s.organizationId == org.id).length;
        return _ListTileCard(
          selected: selected,
          title: org.name,
          subtitle: org.email,
          badge: '$sitesCount sites',
          onTap: () => setState(() {
            _selectedOrganizationId = org.id;
            _selectedSiteId = null;
            _selectedZoneId = null;
          }),
          onEdit: () => _showOrganizationModal(organization: org, db: db),
          onDelete: () {
            db.delete('organizations', org.id);
            setState(() {
              if (_selectedOrganizationId == org.id) {
                _selectedOrganizationId = null;
                _selectedSiteId = null;
                _selectedZoneId = null;
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSitesList(List<Site> sites, UserAdminDatabaseProvider db) {
    if (_selectedOrganizationId == null) {
      return const _EmptyHint(text: 'Select an organization');
    }
    if (sites.isEmpty) {
      return const _EmptyHint(text: 'No sites in this organization');
    }
    return Column(
      children: sites.map((site) {
        final selected = site.id == _selectedSiteId;
        return _ListTileCard(
          selected: selected,
          title: site.name,
          subtitle: site.location,
          onTap: () => setState(() {
            _selectedSiteId = site.id;
            _selectedZoneId = null;
          }),
          onEdit: () => _showSiteModal(site: site, db: db),
          onDelete: () {
            db.delete('sites', site.id);
            setState(() {
              if (_selectedSiteId == site.id) {
                _selectedSiteId = null;
                _selectedZoneId = null;
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildZonesList(List<Zone> zones, UserAdminDatabaseProvider db) {
    if (_selectedSiteId == null) {
      return const _EmptyHint(text: 'Select a site');
    }
    if (zones.isEmpty) {
      return const _EmptyHint(text: 'No zones in this site');
    }
    return Column(
      children: zones.map((zone) {
        final selected = zone.id == _selectedZoneId;
        return _ListTileCard(
          selected: selected,
          title: zone.name,
          subtitle: 'Zone',
          onTap: () => setState(() => _selectedZoneId = zone.id),
          onEdit: () => _showZoneModal(zone: zone, db: db),
          onDelete: () {
            db.delete('zones', zone.id);
            setState(() {
              if (_selectedZoneId == zone.id) _selectedZoneId = null;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildLocationsList(List<String> locations) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    if (_selectedZoneId == null) {
      return const _EmptyHint(text: 'Select a zone');
    }
    if (locations.isEmpty) {
      return const _EmptyHint(text: 'No locations in this zone');
    }
    return Column(
      children: locations
          .map((loc) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFF4F8FB)
                      : const Color(0xFF253F52),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 15,
                      color: isLight
                          ? const Color(0xFF4C7084)
                          : const Color(0xFFBBD0E0),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc,
                        style: TextStyle(
                          fontSize: 13,
                          color: isLight
                              ? const Color(0xFF1f3642)
                              : const Color(0xFFE2EDF8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _chipButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F729C),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22117AA8),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
}

class _ListTileCard extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ListTileCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
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
                    _actionIcon(
                      context: context,
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF2E4B5B),
                      onTap: onEdit,
                    ),
                    const SizedBox(width: 6),
                    _actionIcon(
                      context: context,
                      icon: Icons.delete_outline,
                      color: const Color(0xFFD33A3A),
                      onTap: onDelete,
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
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionIcon({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFEAF1F6) : const Color(0xFF2B4659),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    isLight ? const Color(0xFFEAF3F8) : const Color(0xFF2B4659),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_tree_outlined,
                color:
                    isLight ? const Color(0xFF5B7686) : const Color(0xFFBBD0E0),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color:
                    isLight ? const Color(0xFF5D7381) : const Color(0xFFBBD0E0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
