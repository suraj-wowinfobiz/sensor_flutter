import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/site.dart';
import '../providers/super_admin_backend_provider.dart';
import '../widgets/crud_modal.dart';
import '../widgets/crud_table.dart';

class SitesScreen extends StatefulWidget {
  const SitesScreen({super.key});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  String? _editingId;
  String _name = '';
  String _location = '';
  String _organizationId = '';

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text('Are you sure you want to delete this site?'),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final db = Provider.of<SuperAdminBackendProvider>(context, listen: false);
      await db.loadOrganizations();
      await db.loadSites();
    });
  }

  void _showSiteModal({Site? site}) {
    final db = Provider.of<SuperAdminBackendProvider>(context, listen: false);

    if (site != null) {
      _editingId = site.id;
      _name = site.name;
      _location = site.location;
      _organizationId = site.organizationId;
    } else {
      _editingId = null;
      _name = '';
      _location = '';
      _organizationId =
          db.organizations.isNotEmpty ? db.organizations[0].id : '';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CrudModal(
            title: site == null ? 'Add Site' : 'Edit Site',
            fields: [
              {
                'label': 'Name',
                'value': _name,
                'onChanged': (String value) => setState(() => _name = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'Location',
                'value': _location,
                'onChanged': (String value) =>
                    setState(() => _location = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'Organization',
                'type': 'select',
                'value': _organizationId,
                'onChanged': (String? value) =>
                    setState(() => _organizationId = value ?? _organizationId),
                'options': db.organizations
                    .map((org) => {'label': org.name, 'value': org.id})
                    .toList(),
              },
            ],
            onSave: () async {
              final db = Provider.of<SuperAdminBackendProvider>(context, listen: false);
              try {
                if (_editingId == null) {
                  await db.create('sites', {
                    'name': _name,
                    'location': _location,
                    'organization_id': _organizationId,
                  });
                } else {
                  await db.update('sites', _editingId!, {
                    'name': _name,
                    'location': _location,
                    'organization_id': _organizationId,
                  });
                }
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save site: $e')),
                  );
                }
              }
            },
            onCancel: () => Navigator.pop(context),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SuperAdminBackendProvider>(
      builder: (context, db, child) {
        return CrudTable(
          title: 'Sites',
          icon: Icons.location_on,
          columns: const ['Name', 'Location', 'Organization', 'Created'],
          data: db.sites
              .map((site) => [
                    site.name,
                    site.location,
                    db.organizations
                        .firstWhere((o) => o.id == site.organizationId)
                        .name,
                    _formatDate(site.createdAt),
                  ])
              .toList(),
          onAdd: () => _showSiteModal(),
          onEdit: (index) => _showSiteModal(site: db.sites[index]),
          onDelete: (index) async {
            final confirm = await _confirmDelete(context);
            if (!confirm || !context.mounted) return;
            try {
              await db.delete('sites', db.sites[index].id);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete site: $e')),
                );
              }
            }
          },
        );
      },
    );
  }
}
