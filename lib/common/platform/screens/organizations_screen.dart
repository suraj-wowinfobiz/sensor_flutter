import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/ops_theme.dart';
import '../models/organization.dart';
import '../models/site.dart';
import '../models/zone.dart';
import '../providers/super_admin_backend_provider.dart';
import '../providers/super_admin_riverpod_provider.dart';
import '../widgets/crud_modal.dart';

class OrganizationsScreen extends ConsumerStatefulWidget {
  const OrganizationsScreen({super.key});

  @override
  ConsumerState<OrganizationsScreen> createState() =>
      _OrganizationsScreenState();
}

class _OrganizationsScreenState extends ConsumerState<OrganizationsScreen> {
  bool _selectionSyncQueued = false;
  String? get _selectedOrganizationId =>
      ref.read(superAdminSelectedOrganizationIdStateProvider);
  set _selectedOrganizationId(String? value) =>
      ref.read(superAdminSelectedOrganizationIdStateProvider.notifier).state =
          value;

  String? get _selectedSiteId =>
      ref.read(superAdminSelectedSiteIdStateProvider);
  set _selectedSiteId(String? value) =>
      ref.read(superAdminSelectedSiteIdStateProvider.notifier).state = value;

  String? get _selectedZoneId =>
      ref.read(superAdminSelectedZoneIdStateProvider);
  set _selectedZoneId(String? value) =>
      ref.read(superAdminSelectedZoneIdStateProvider.notifier).state = value;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(superAdminBackendChangeNotifierProvider);
    await Future.wait([
      db.loadOrganizations(),
      db.loadOrganizations().then((_) => db.loadSites()),
    ]);
    final firstOrgId =
        db.organizations.isNotEmpty ? db.organizations.first.id : null;
    final firstSiteId = db.sites
        .where((s) => s.organizationId == firstOrgId)
        .map((s) => s.id)
        .firstOrNull;
    if (firstSiteId != null) {
      await db.loadZones(firstSiteId);
    }
    _ensureSelections(db);
    ref.read(superAdminIsLoadingStateProvider.notifier).state = false;
  }

  void _showApiError(Object e) {
    final text = e.toString().replaceFirst('ApiException: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm delete'),
        content: Text('Are you sure you want to delete this $label?'),
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
    return confirmed == true;
  }

  void _ensureSelections(SuperAdminBackendProvider db) {
    final currentOrgId = _selectedOrganizationId;
    final currentSiteId = _selectedSiteId;
    final currentZoneId = _selectedZoneId;

    String? nextOrgId = currentOrgId;
    if (db.organizations.isNotEmpty &&
        (nextOrgId == null ||
            db.organizations.every((o) => o.id != nextOrgId))) {
      nextOrgId = db.organizations.first.id;
    }
    if (db.organizations.isEmpty) nextOrgId = null;

    final scopedSites =
        db.sites.where((s) => s.organizationId == nextOrgId).toList();
    String? nextSiteId = currentSiteId;
    if (scopedSites.isNotEmpty &&
        (nextSiteId == null || scopedSites.every((s) => s.id != nextSiteId))) {
      nextSiteId = scopedSites.first.id;
    }
    if (scopedSites.isEmpty) nextSiteId = null;

    final scopedZones = db.zones.where((z) => z.siteId == nextSiteId).toList();
    String? nextZoneId = currentZoneId;
    if (scopedZones.isNotEmpty &&
        (nextZoneId == null || scopedZones.every((z) => z.id != nextZoneId))) {
      nextZoneId = scopedZones.first.id;
    }
    if (scopedZones.isEmpty) nextZoneId = null;

    final hasChanges = nextOrgId != currentOrgId ||
        nextSiteId != currentSiteId ||
        nextZoneId != currentZoneId;
    if (!hasChanges || _selectionSyncQueued) return;

    _selectionSyncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectionSyncQueued = false;
      if (!mounted) return;
      ref.read(superAdminSelectedOrganizationIdStateProvider.notifier).state =
          nextOrgId;
      ref.read(superAdminSelectedSiteIdStateProvider.notifier).state =
          nextSiteId;
      ref.read(superAdminSelectedZoneIdStateProvider.notifier).state =
          nextZoneId;
    });
  }

  void _showOrganizationModal({
    Organization? organization,
    required SuperAdminBackendProvider db,
  }) {
    var name = organization?.name ?? '';
    var email = organization?.email ?? '';
    var status = organization?.status ?? 'active';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CrudModal(
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
            onSave: () async {
              try {
                if (name.trim().isEmpty || email.trim().isEmpty) {
                  throw Exception('name can not be empty');
                }
                if (organization == null) {
                  await db.create('organizations', {
                    'name': name.trim(),
                    'email': email.trim(),
                    'status': status,
                    'owner_user_id': '',
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Organization created')));
                    Navigator.pop(context);
                  }
                } else {
                  await db.update('organizations', organization.id, {
                    'name': name.trim(),
                    'email': email.trim(),
                    'status': status,
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) _showApiError(e);
              }
            },
            onCancel: () => Navigator.pop(context),
          );
        },
      ),
    );
  }

  void _showSiteModal({Site? site, required SuperAdminBackendProvider db}) {
    if (_selectedOrganizationId == null && site == null) return;

    var name = site?.name ?? '';
    var organizationId = site?.organizationId ?? _selectedOrganizationId!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CrudModal(
            title: site == null ? 'Add Site' : 'Edit Site',
            fields: [
              {
                'label': 'Name',
                'value': name,
                'onChanged': (String value) => setState(() => name = value),
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
            onSave: () async {
              try {
                if (organizationId.trim().isEmpty) {
                  throw Exception('orgId is required');
                }
                if (name.trim().isEmpty) {
                  throw Exception("site name can't be empty");
                }
                final fallbackLocation =
                    (site?.location.trim().isNotEmpty ?? false)
                        ? site!.location.trim()
                        : 'N/A';
                if (site == null) {
                  await db.create('sites', {
                    'name': name.trim(),
                    'location': fallbackLocation,
                    'organization_id': organizationId,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Site created successfully')));
                  }
                } else {
                  await db.update('sites', site.id, {
                    'name': name.trim(),
                    'location': fallbackLocation,
                    'organization_id': organizationId,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Site updated successfully')));
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  _showApiError(e);
                }
              }
            },
            onCancel: () => Navigator.pop(context),
          );
        },
      ),
    );
  }

  void _showZoneModal({Zone? zone, required SuperAdminBackendProvider db}) {
    if (_selectedSiteId == null && zone == null) return;

    var name = zone?.name ?? '';
    var siteId = zone?.siteId ?? _selectedSiteId!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CrudModal(
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
            onSave: () async {
              try {
                if (siteId.trim().isEmpty) {
                  throw Exception('siteId is required');
                }
                if (name.trim().isEmpty) {
                  throw Exception("name can not be empty");
                }
                if (zone == null) {
                  await db.create('zones', {
                    'name': name.trim(),
                    'site_id': siteId,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Zone created successfully')));
                  }
                } else {
                  await db.update('zones', zone.id, {
                    'name': name.trim(),
                    'site_id': siteId,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Zone updated successfully')));
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  _showApiError(e);
                }
              }
            },
            onCancel: () => Navigator.pop(context),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(superAdminIsLoadingStateProvider);
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final selectedOrganizationId =
        ref.watch(superAdminSelectedOrganizationIdStateProvider);
    final selectedSiteId = ref.watch(superAdminSelectedSiteIdStateProvider);
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    _ensureSelections(db);
    final viewportHeight = MediaQuery.of(context).size.height;
    final desktopCardHeight =
        (viewportHeight - 250).clamp(380.0, 760.0).toDouble();
    const mobileCardHeight = 420.0;

    final organizations = db.organizations;
    final sites = db.sites
        .where((s) => s.organizationId == selectedOrganizationId)
        .toList();
    final zones = db.zones.where((z) => z.siteId == selectedSiteId).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
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
                  const Text(
                    'Organization Hierarchy',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: OpsColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Manage organizations, sites, and zones',
                    style: TextStyle(
                      fontSize: 15,
                      color: OpsColors.muted,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _infoChip('${organizations.length} Orgs'),
                  _infoChip('${db.sites.length} Sites'),
                  _infoChip('${db.zones.length} Zones'),
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
                      onAdd: () => _showOrganizationModal(db: db),
                      child: _buildOrganizationsList(organizations, db),
                    ),
                    const SizedBox(height: 12),
                    _columnCard(
                      title: 'Sites',
                      icon: Icons.map_outlined,
                      height: mobileCardHeight,
                      onAdd: _selectedOrganizationId == null
                          ? null
                          : () => _showSiteModal(db: db),
                      child: _buildSitesList(sites, db),
                    ),
                    const SizedBox(height: 12),
                    _columnCard(
                      title: 'Zones',
                      icon: Icons.layers_outlined,
                      height: mobileCardHeight,
                      onAdd: _selectedSiteId == null
                          ? null
                          : () => _showZoneModal(db: db),
                      child: _buildZonesList(zones, db),
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
                      onAdd: () => _showOrganizationModal(db: db),
                      child: _buildOrganizationsList(organizations, db),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _columnCard(
                      title: 'Sites',
                      icon: Icons.map_outlined,
                      height: desktopCardHeight,
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
                      height: desktopCardHeight,
                      onAdd: _selectedSiteId == null
                          ? null
                          : () => _showZoneModal(db: db),
                      child: _buildZonesList(zones, db),
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

  Widget _columnCard({
    required String title,
    required IconData icon,
    required double height,
    required Widget child,
    VoidCallback? onAdd,
  }) {
    return Container(
      height: height,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: OpsColors.surfaceLow,
              border: Border(
                bottom: BorderSide(color: OpsColors.border),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: OpsColors.primary.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 17,
                    color: OpsColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20 > 18 ? 20 - 2 : 18,
                      fontWeight: FontWeight.w800,
                      color: OpsColors.text,
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
                        color: OpsColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: OpsColors.border),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: OpsColors.text,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationsList(
      List<Organization> organizations, SuperAdminBackendProvider db) {
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
          onDelete: () async {
            final confirm = await _confirmDelete(context, 'organization');
            if (!confirm || !mounted) return;
            try {
              await db.delete('organizations', org.id);
              setState(() {
                if (_selectedOrganizationId == org.id) {
                  _selectedOrganizationId = null;
                  _selectedSiteId = null;
                  _selectedZoneId = null;
                }
              });
            } catch (e) {
              if (mounted) _showApiError(e);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildSitesList(List<Site> sites, SuperAdminBackendProvider db) {
    if (_selectedOrganizationId == null) {
      return const _EmptyHint(text: 'Select an organization');
    }
    if (sites.isEmpty) {
      return const _EmptyHint(text: 'No sites in this organization');
    }
    return Column(
      children: sites.map((site) {
        final selected = site.id == _selectedSiteId;
        final zonesCount = db.zones.where((z) => z.siteId == site.id).length;
        return _ListTileCard(
          selected: selected,
          title: site.name,
          subtitle: 'Site',
          badge: '$zonesCount zones',
          onTap: () {
            setState(() {
              _selectedSiteId = site.id;
              _selectedZoneId = null;
            });
            db.loadZones(site.id);
          },
          onEdit: () => _showSiteModal(site: site, db: db),
          onDelete: () async {
            final confirm = await _confirmDelete(context, 'site');
            if (!confirm || !mounted) return;
            try {
              await db.delete('sites', site.id);
              setState(() {
                if (_selectedSiteId == site.id) {
                  _selectedSiteId = null;
                  _selectedZoneId = null;
                }
              });
            } catch (e) {
              if (mounted) _showApiError(e);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildZonesList(List<Zone> zones, SuperAdminBackendProvider db) {
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
          onDelete: () async {
            final confirm = await _confirmDelete(context, 'zone');
            if (!confirm || !mounted) return;
            try {
              await db.delete('zones', zone.id);
              setState(() {
                if (_selectedZoneId == zone.id) _selectedZoneId = null;
              });
            } catch (e) {
              if (mounted) _showApiError(e);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _infoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: OpsColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OpsColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: OpsColors.text,
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
                      color: isLight
                          ? const Color(0xFF2E4B5B)
                          : const Color(0xFFBBD0E0),
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
                      offset: const Offset(0, 0),
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
