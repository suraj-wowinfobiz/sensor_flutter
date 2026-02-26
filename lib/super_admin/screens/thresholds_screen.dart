import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/threshold_profile.dart';
import '../providers/super_admin_backend_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final db = Provider.of<SuperAdminBackendProvider>(context, listen: false);
      await db.loadThresholdProfiles();
    });
  }

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
            onSave: () async {
              final db = Provider.of<SuperAdminBackendProvider>(context, listen: false);
              try {
                if (_editingId == null) {
                  await db.create('thresholds', {
                    'name': _name,
                    'description': _description,
                  });
                } else {
                  await db.update('thresholds', _editingId!, {
                    'name': _name,
                    'description': _description,
                  });
                }
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save threshold: $e')),
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
          title: 'Threshold Profiles',
          icon: Icons.settings,
          columns: const ['Name', 'Description'],
          data: db.thresholdProfiles
              .map((profile) => [profile.name, profile.description])
              .toList(),
          onAdd: () => _showThresholdModal(),
          onEdit: (index) =>
              _showThresholdModal(profile: db.thresholdProfiles[index]),
          onDelete: (index) async {
            try {
              await db.delete('thresholds', db.thresholdProfiles[index].id);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete threshold: $e')),
                );
              }
            }
          },
        );
      },
    );
  }
}
