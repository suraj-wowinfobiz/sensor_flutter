import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/database_provider.dart';
import '../widgets/crud_modal.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _roleFilter = 'all';
  String _statusFilter = 'all';
  String _searchText = '';

  final Set<String> _restrictedUsers = {};
  String? _editingId;
  String _name = '';
  String _email = '';
  String _role = 'operator';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserModal({User? user}) {
    if (user != null) {
      _editingId = user.id;
      _name = user.name;
      _email = user.email;
      _role = user.role;
    } else {
      _editingId = null;
      _name = '';
      _email = '';
      _role = 'operator';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CrudModal(
            title: user == null ? 'Add User' : 'Edit User',
            fields: [
              {
                'label': 'Name',
                'value': _name,
                'onChanged': (String value) => setState(() => _name = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'Email',
                'value': _email,
                'onChanged': (String value) => setState(() => _email = value),
                'keyboardType': TextInputType.emailAddress,
              },
              {
                'label': 'Role',
                'type': 'select',
                'value': _role,
                'onChanged': (String? value) =>
                    setState(() => _role = value ?? _role),
                'options': const [
                  {'label': 'Operator', 'value': 'operator'},
                  {'label': 'Engineer', 'value': 'engineer'},
                  {'label': 'Admin', 'value': 'admin'},
                ],
              },
            ],
            onSave: () {
              final db = Provider.of<DatabaseProvider>(context, listen: false);
              if (_editingId == null) {
                db.create('users', {
                  'name': _name,
                  'email': _email,
                  'role': _role,
                });
              } else {
                db.update('users', _editingId!, {
                  'name': _name,
                  'email': _email,
                  'role': _role,
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

  void _generateSampleUsers(DatabaseProvider db) {
    if (db.users.length >= 6) return;
    const sample = [
      {
        'name': 'Alice Johnson',
        'email': 'alice.johnson@acme.com',
        'role': 'operator'
      },
      {
        'name': 'Rohit Mehra',
        'email': 'rohit.mehra@acme.com',
        'role': 'engineer'
      },
      {'name': 'Priya Nair', 'email': 'priya.nair@acme.com', 'role': 'admin'},
    ];
    for (final u in sample) {
      db.create('users', {
        'name': u['name']!,
        'email': u['email']!,
        'role': u['role']!,
      });
    }
  }

  String _shortName(String name) {
    final parts = name.split(' ').where((e) => e.trim().isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  List<User> _applyFilters(List<User> users) {
    return users.where((u) {
      final matchesSearch = _searchText.isEmpty ||
          u.name.toLowerCase().contains(_searchText.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchText.toLowerCase());
      final matchesRole = _roleFilter == 'all' || u.role == _roleFilter;
      final isRestricted = _restrictedUsers.contains(u.id);
      final status = isRestricted ? 'restricted' : 'active';
      final matchesStatus = _statusFilter == 'all' || _statusFilter == status;
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  void _showAccessDialog(BuildContext context, User user, DatabaseProvider db) {
    final index = db.users.indexOf(user);
    final site = db.sites.isNotEmpty
        ? db.sites[index % db.sites.length].name
        : 'No Site';
    final zone = db.zones.isNotEmpty
        ? db.zones[index % db.zones.length].name
        : 'No Zone';
    final sensors = db.sensors
        .where((s) =>
            db.devices
                .where((d) => d.id == s.deviceId)
                .map((d) => d.siteId)
                .firstOrNull ==
            db.sites.where((s) => s.name == site).map((s) => s.id).firstOrNull)
        .take(3)
        .map((s) => s.serialNumber)
        .toList();

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${user.name} Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: ${user.role}'),
            const SizedBox(height: 8),
            Text('Site: $site'),
            const SizedBox(height: 6),
            Text('Zone: $zone'),
            const SizedBox(height: 6),
            Text('Sensors: ${sensors.isEmpty ? 'None' : sensors.join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, db, child) {
        final users = _applyFilters(db.users);

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
                        'User Management',
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
                      const Text(
                        'Manage users and their access control permissions',
                        style:
                            TextStyle(fontSize: 15, color: Color(0xFF4e6473)),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _headerButton(
                        label: 'Generate Sample Data',
                        icon: Icons.data_saver_on_outlined,
                        onTap: () => _generateSampleUsers(db),
                      ),
                      _headerButton(
                        label: 'Add User',
                        icon: Icons.add,
                        primary: true,
                        onTap: () => _showUserModal(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFC8D6DD)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _searchText = v.trim()),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: InputBorder.none,
                          hintText: 'Search by name or email...',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _dropdown(
                    value: _roleFilter,
                    width: 160,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Roles')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(
                          value: 'engineer', child: Text('Engineer')),
                      DropdownMenuItem(
                          value: 'operator', child: Text('Operator')),
                    ],
                    onChanged: (value) => setState(() => _roleFilter = value!),
                  ),
                  const SizedBox(width: 10),
                  _dropdown(
                    value: _statusFilter,
                    width: 160,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Status')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                          value: 'restricted', child: Text('Restricted')),
                    ],
                    onChanged: (value) =>
                        setState(() => _statusFilter = value!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...users.map((user) {
                final restricted = _restrictedUsers.contains(user.id);
                final userIndex = db.users.indexOf(user);
                final site = db.sites.isNotEmpty
                    ? db.sites[userIndex % db.sites.length].name
                    : 'No Site';
                final zone = db.zones.isNotEmpty
                    ? db.zones[userIndex % db.zones.length].name
                    : 'No Zone';
                final sensorCodes = db.sensors
                    .where((s) =>
                        s.deviceId ==
                        db.devices[userIndex % db.devices.length].id)
                    .take(2)
                    .map((s) => s.serialNumber)
                    .toList();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFC8D6DD)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFDCE7ED),
                        child: Text(
                          _shortName(user.name),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF203845),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF102632),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.check_circle,
                                    size: 16, color: Color(0xFF0ca15f)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF516875),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _tag(user.role[0].toUpperCase() +
                                    user.role.substring(1)),
                                _tag('Unknown'),
                                _tag(
                                  restricted ? 'Restricted' : 'Open',
                                  icon: Icons.lock_outline,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _accessBlock(
                              title: 'Sites (1)',
                              icon: Icons.business,
                              color: const Color(0xFFE2F0F8),
                              chips: [site],
                            ),
                            const SizedBox(height: 8),
                            _accessBlock(
                              title: 'Zones (1)',
                              icon: Icons.location_on_outlined,
                              color: const Color(0xFFE8EBF9),
                              chips: [zone],
                            ),
                            const SizedBox(height: 8),
                            _accessBlock(
                              title: 'Sensors (${sensorCodes.length})',
                              icon: Icons.sensors,
                              color: const Color(0xFFE6F4EA),
                              chips: sensorCodes.isEmpty
                                  ? const ['No Sensors']
                                  : sensorCodes,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        children: [
                          _actionButton(
                            label: 'View Access',
                            icon: Icons.remove_red_eye_outlined,
                            onTap: () => _showAccessDialog(context, user, db),
                          ),
                          const SizedBox(height: 8),
                          _iconAction(
                            icon: Icons.lock_outline,
                            onTap: () {
                              setState(() {
                                if (restricted) {
                                  _restrictedUsers.remove(user.id);
                                } else {
                                  _restrictedUsers.add(user.id);
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          _iconAction(
                            icon: Icons.edit_outlined,
                            onTap: () => _showUserModal(user: user),
                          ),
                          const SizedBox(height: 8),
                          _iconAction(
                            icon: Icons.cancel_outlined,
                            iconColor: const Color(0xFFD39A00),
                            onTap: () {
                              setState(() => _restrictedUsers.add(user.id));
                            },
                          ),
                          const SizedBox(height: 8),
                          _iconAction(
                            icon: Icons.delete_outline,
                            iconColor: Colors.red,
                            onTap: () => db.delete('users', user.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _dropdown({
    required String value,
    required double width,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: width,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC8D6DD)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _headerButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: primary ? const Color(0xFF0f729c) : const Color(0xFFe6eff3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primary ? const Color(0xFF0f729c) : const Color(0xFFc8d6dd),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: primary ? Colors.white : const Color(0xFF18313f)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: primary ? Colors.white : const Color(0xFF18313f),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE2EDF3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: const Color(0xFF2C4654)),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1f3642),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accessBlock({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> chips,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8D6DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFF246081)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF173341),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: chips
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD2E3EC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        c,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF203845),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFE7EFF3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFC8D6DD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1f3642)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1f3642),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF2f4654),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFE7EFF3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFC8D6DD)),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}
