import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/organization_model.dart';
import '../providers/database_provider.dart';
import '../widgets/animated/data_table.dart';

class OrganizationsScreen extends StatelessWidget {
  const OrganizationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, db, child) {
        return AnimatedDataTable(
          title: 'Organizations',
          icon: Icons.business,
          columns: const ['Name', 'Email', 'Status', 'Created'],
          data: db.organizations
              .map((org) =>
                  [org.name, org.email, org.status, _formatDate(org.createdAt)])
              .toList(),
          onAdd: () => _showOrgDialog(context, db),
          onEdit: (index) =>
              _showOrgDialog(context, db, org: db.organizations[index]),
          onDelete: (index) =>
              db.deleteOrganization(db.organizations[index].id),
        );
      },
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _showOrgDialog(BuildContext context, DatabaseProvider db,
      {OrganizationModel? org}) async {
    final nameCtrl = TextEditingController(text: org?.name ?? '');
    final emailCtrl = TextEditingController(text: org?.email ?? '');
    String status = org?.status ?? 'active';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(org == null ? 'Add Organization' : 'Edit Organization'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email')),
            DropdownButtonFormField<String>(
              initialValue: status,
              items: const [
                DropdownMenuItem(value: 'active', child: Text('active')),
                DropdownMenuItem(value: 'inactive', child: Text('inactive')),
              ],
              onChanged: (v) => status = v ?? status,
              decoration: const InputDecoration(labelText: 'Status'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (org == null) {
                await db.addOrganization(
                  OrganizationModel(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    status: status,
                    ownerUserId: 'owner1',
                    createdAt: DateTime.now(),
                  ),
                );
              } else {
                await db.updateOrganization(org.copyWith(
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    status: status));
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
