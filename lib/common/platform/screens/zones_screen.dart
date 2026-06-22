import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/zone.dart';
import '../providers/super_admin_backend_provider.dart';
import '../widgets/crud_modal.dart';
import '../widgets/crud_table.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  String? _editingId;
  String _name = '';
  String _siteId = '';

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text('Are you sure you want to delete this zone?'),
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
      await db.loadSites();
      for (final site in db.sites) {
        await db.loadZones(site.id);
      }
    });
  }

  void _showZoneModal({Zone? zone}) {
    final db = Provider.of<SuperAdminBackendProvider>(context, listen: false);

    if (zone != null) {
      _editingId = zone.id;
      _name = zone.name;
      _siteId = zone.siteId;
    } else {
      _editingId = null;
      _name = '';
      _siteId = db.sites.isNotEmpty ? db.sites[0].id : '';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CrudModal(
            title: zone == null ? 'Add Zone' : 'Edit Zone',
            fields: [
              {
                'label': 'Name',
                'value': _name,
                'onChanged': (String value) => setState(() => _name = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'Site',
                'type': 'select',
                'value': _siteId,
                'onChanged': (String? value) =>
                    setState(() => _siteId = value ?? _siteId),
                'options': db.sites
                    .map((site) => {'label': site.name, 'value': site.id})
                    .toList(),
              },
            ],
            onSave: () async {
              final db = Provider.of<SuperAdminBackendProvider>(context,
                  listen: false);
              try {
                if (_editingId == null) {
                  await db.create('zones', {
                    'name': _name,
                    'site_id': _siteId,
                  });
                } else {
                  await db.update('zones', _editingId!, {
                    'name': _name,
                    'site_id': _siteId,
                  });
                }
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save zone: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<SuperAdminBackendProvider>(
      builder: (context, db, child) {
        return CrudTable(
          title: 'Zones',
          icon: Icons.layers,
          columns: const ['Name', 'Site'],
          data: db.zones
              .map((zone) => [
                    zone.name,
                    db.sites.firstWhere((s) => s.id == zone.siteId).name,
                  ])
              .toList(),
          onAdd: () => _showZoneModal(),
          onEdit: (index) => _showZoneModal(zone: db.zones[index]),
          onDelete: (index) async {
            final confirm = await _confirmDelete(context);
            if (!confirm || !context.mounted) return;
            try {
              await db.delete('zones', db.zones[index].id);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete zone: $e')),
                );
              }
            }
          },
        );
      },
    );
  }
}
