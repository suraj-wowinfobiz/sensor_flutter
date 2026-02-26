import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_model.dart';
import '../providers/database_provider.dart';
import '../widgets/animated/data_table.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, db, child) {
        return AnimatedDataTable(
          title: 'Users',
          icon: Icons.people,
          columns: const ['Name', 'Email', 'Role', 'Created'],
          data: db.users
              .map((user) => [
                    user.name,
                    user.email,
                    user.role,
                    _formatDate(user.createdAt),
                  ])
              .toList(),
          onAdd: () => _showUserDialog(context, db),
          onEdit: (index) =>
              _showUserDialog(context, db, user: db.users[index]),
          onDelete: (index) => db.deleteUser(db.users[index].id),
        );
      },
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _showUserDialog(BuildContext context, DatabaseProvider db,
      {UserModel? user}) async {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    String role = user?.role ?? 'admin';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user == null ? 'Add User' : 'Edit User'),
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
              initialValue: role,
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('admin')),
                DropdownMenuItem(value: 'engineer', child: Text('engineer')),
                DropdownMenuItem(value: 'viewer', child: Text('viewer')),
              ],
              onChanged: (v) => role = v ?? role,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final now = DateTime.now();
              if (user == null) {
                await db.addUser(
                  UserModel(
                    id: now.microsecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    role: role,
                    createdAt: now,
                    updatedAt: now,
                  ),
                );
              } else {
                await db.updateUser(user.copyWith(
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    role: role));
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
