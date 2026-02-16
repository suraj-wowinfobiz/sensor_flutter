import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/threshold_profile.dart';
import '../providers/database_provider.dart';
import '../widgets/crud_modal.dart';
import '../widgets/crud_table.dart';

class ThresholdsScreen extends StatefulWidget {
  const ThresholdsScreen({super.key});

  @override
  State<ThresholdsScreen> createState() => _ThresholdsScreenState();
}

class _ThresholdsScreenState extends State<ThresholdsScreen> {
  String? _editingId;
  String _name = '';
  String _description = '';

  void _showThresholdModal({ThresholdProfile? profile}) {
    if (profile != null) {
      _editingId = profile.id;
      _name = profile.name;
      _description = profile.description;
    } else {
      _editingId = null;
      _name = '';
      _description = '';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CrudModal(
            title: profile == null
                ? 'Add Threshold Profile'
                : 'Edit Threshold Profile',
            fields: [
              {
                'label': 'Name',
                'value': _name,
                'onChanged': (String value) => setState(() => _name = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'Description',
                'value': _description,
                'onChanged': (String value) =>
                    setState(() => _description = value),
                'keyboardType': TextInputType.text,
              },
            ],
            onSave: () {
              final db = Provider.of<DatabaseProvider>(context, listen: false);
              if (_editingId == null) {
                db.create('thresholds', {
                  'name': _name,
                  'description': _description,
                });
              } else {
                db.update('thresholds', _editingId!, {
                  'name': _name,
                  'description': _description,
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
          title: 'Threshold Profiles',
          icon: Icons.settings,
          columns: const ['Name', 'Description'],
          data: db.thresholdProfiles
              .map((profile) => [profile.name, profile.description])
              .toList(),
          onAdd: () => _showThresholdModal(),
          onEdit: (index) =>
              _showThresholdModal(profile: db.thresholdProfiles[index]),
          onDelete: (index) =>
              db.delete('thresholds', db.thresholdProfiles[index].id),
        );
      },
    );
  }
}
