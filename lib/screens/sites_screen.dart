import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/site.dart';
import '../providers/database_provider.dart';
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

  void _showSiteModal({Site? site}) {
    final db = Provider.of<DatabaseProvider>(context, listen: false);

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
            onSave: () {
              final db = Provider.of<DatabaseProvider>(context, listen: false);
              if (_editingId == null) {
                db.create('sites', {
                  'name': _name,
                  'location': _location,
                  'organization_id': _organizationId,
                });
              } else {
                db.update('sites', _editingId!, {
                  'name': _name,
                  'location': _location,
                  'organization_id': _organizationId,
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
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
          onDelete: (index) => db.delete('sites', db.sites[index].id),
        );
      },
    );
  }
}
