import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/zone.dart';
import '../providers/database_provider.dart';
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

  void _showZoneModal({Zone? zone}) {
    final db = Provider.of<DatabaseProvider>(context, listen: false);

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
            onSave: () {
              final db = Provider.of<DatabaseProvider>(context, listen: false);
              if (_editingId == null) {
                db.create('zones', {
                  'name': _name,
                  'site_id': _siteId,
                });
              } else {
                db.update('zones', _editingId!, {
                  'name': _name,
                  'site_id': _siteId,
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

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
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
          onDelete: (index) => db.delete('zones', db.zones[index].id),
        );
      },
    );
  }
}
