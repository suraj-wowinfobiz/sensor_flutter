import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/user_admin_database_provider.dart';

class UserAdminUsersScreen extends StatefulWidget {
  const UserAdminUsersScreen({super.key});

  @override
  State<UserAdminUsersScreen> createState() => _UserAdminUsersScreenState();
}

class _UserAdminUsersScreenState extends State<UserAdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isCardView = true;
  String _roleFilter = 'all';
  String _statusFilter = 'all';
  String _searchText = '';

  final Set<String> _restrictedUsers = {};
  final Map<String, Set<String>> _userOrganizationAccess = {};
  final Map<String, Set<String>> _userSiteAccess = {};
  final Map<String, Set<String>> _userZoneAccess = {};
  String? _editingId;
  String _name = '';
  String _email = '';
  String _role = 'operator';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showUserModal({User? user}) async {
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

    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final roleController = TextEditingController(text: _role);
    final organizationController = TextEditingController();

    const templates = <Map<String, String>>[
      {
        'title': 'Full Organization Admin',
        'name': 'New Org Admin',
        'email': 'admin@example.com',
        'role': 'admin',
        'organization': 'Default Organization',
      },
      {
        'title': 'Site Installation Engineer',
        'name': 'New Site Engineer',
        'email': 'engineer@example.com',
        'role': 'engineer',
        'organization': 'Field Operations',
      },
      {
        'title': 'Monitoring Operator',
        'name': 'New Monitoring User',
        'email': 'operator@example.com',
        'role': 'operator',
        'organization': 'Monitoring Center',
      },
    ];
    var useTemplateTab = user == null;
    var selectedTemplate = 0;

    String normalizeRole(String value) {
      final lower = value.trim().toLowerCase();
      if (lower == 'admin') return 'admin';
      if (lower == 'engineer') return 'engineer';
      return 'operator';
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final db =
              Provider.of<UserAdminDatabaseProvider>(context, listen: false);

          void saveUser() {
            final name = nameController.text.trim();
            final email = emailController.text.trim();
            final role = normalizeRole(roleController.text);

            if (name.isEmpty || email.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Name and email are required')),
              );
              return;
            }

            final payload = {
              'name': name,
              'email': email,
              'role': role,
            };

            if (_editingId == null) {
              db.create('users', payload);
            } else {
              db.update('users', _editingId!, payload);
            }
            Navigator.pop(context);
          }

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Color(0xFF0f729c), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          user == null ? 'Create New User' : 'Edit User',
                          style: const TextStyle(
                            fontSize: 34 > 30 ? 34 - 4 : 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF142936),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    Text(
                      user == null
                          ? 'Choose a template for quick setup or configure manually'
                          : 'Update user details and access role',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF506775),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7EFF3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _tabOption(
                              active: useTemplateTab,
                              icon: Icons.auto_awesome_outlined,
                              label: 'Quick Templates',
                              onTap: () =>
                                  setState(() => useTemplateTab = true),
                            ),
                          ),
                          Expanded(
                            child: _tabOption(
                              active: !useTemplateTab,
                              icon: Icons.build_outlined,
                              label: 'Manual Setup',
                              onTap: () =>
                                  setState(() => useTemplateTab = false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (useTemplateTab) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F5FB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFB8D9EA)),
                        ),
                        child: const Text(
                          'Select a template to prefill manual setup.',
                          style: TextStyle(
                            color: Color(0xFF2B5368),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 620;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: List.generate(templates.length, (i) {
                              final template = templates[i];
                              final active = i == selectedTemplate;
                              return InkWell(
                                onTap: () => setState(() {
                                  selectedTemplate = i;
                                  nameController.text = template['name']!;
                                  emailController.text = template['email']!;
                                  roleController.text = template['role']!;
                                  organizationController.text =
                                      template['organization']!;
                                  useTemplateTab = false;
                                }),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: compact
                                      ? constraints.maxWidth
                                      : (constraints.maxWidth - 10) / 2,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: active
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFFEAF5FC),
                                              Color(0xFFF2F8FC)
                                            ],
                                          )
                                        : null,
                                    color:
                                        active ? null : const Color(0xFFF7FBFD),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: active
                                          ? const Color(0xFF88BFD9)
                                          : const Color(0xFFD7E5EC),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        template['title']!,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF152A36),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Prefill: ${template['role']}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF4E6775),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (!useTemplateTab) ...[
                      const Text(
                        'Full Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1b313d),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _inputBox(
                        child: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'John Doe',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1b313d),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _inputBox(
                        child: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'john@example.com',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Role',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1b313d),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _inputBox(
                        child: TextField(
                          controller: roleController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'operator / engineer / admin',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Organization',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1b313d),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _inputBox(
                        child: TextField(
                          controller: organizationController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'Organization name',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Spacer(),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            onPressed: saveUser,
                            child: Text(
                              _editingId == null
                                  ? 'Create User'
                                  : 'Update User',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    nameController.dispose();
    emailController.dispose();
    roleController.dispose();
    organizationController.dispose();
  }

  Widget _tabOption({
    required bool active,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? (isLight ? Colors.white : const Color(0xFF2B4659))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? Theme.of(context).dividerColor : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF203845)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF203845),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBox({required Widget child}) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF243E52),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }

  void _generateSampleUsers(UserAdminDatabaseProvider db) {
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

  Map<String, Set<String>> _defaultAccessForUser(
    User user,
    UserAdminDatabaseProvider db,
  ) {
    final index = db.users.indexOf(user).clamp(0, 9999);
    final isAdmin = user.role == 'admin';
    final isEngineer = user.role == 'engineer';

    final organizationIds = isAdmin
        ? db.organizations.map((o) => o.id).toSet()
        : <String>{
            if (db.organizations.isNotEmpty)
              db.organizations[index % db.organizations.length].id,
            if (isEngineer && db.organizations.length > 1)
              db.organizations[(index + 1) % db.organizations.length].id,
          };

    final scopedSites = db.sites
        .where((s) => organizationIds.contains(s.organizationId))
        .toList();
    final siteIds = isAdmin
        ? scopedSites.map((s) => s.id).toSet()
        : scopedSites
            .skip(index % (scopedSites.isEmpty ? 1 : scopedSites.length))
            .take(isEngineer ? 2 : 1)
            .map((s) => s.id)
            .toSet();

    final scopedZones =
        db.zones.where((z) => siteIds.contains(z.siteId)).toList();
    final zoneIds = isAdmin
        ? scopedZones.map((z) => z.id).toSet()
        : scopedZones
            .skip(index % (scopedZones.isEmpty ? 1 : scopedZones.length))
            .take(isEngineer ? 3 : 2)
            .map((z) => z.id)
            .toSet();

    return {
      'organizations': organizationIds,
      'sites': siteIds,
      'zones': zoneIds,
    };
  }

  void _showAccessDialog(
      BuildContext context, User user, UserAdminDatabaseProvider db) {
    final defaultAccess = _defaultAccessForUser(user, db);
    final defaultOrganizations = defaultAccess['organizations'] ?? <String>{};
    final defaultSites = defaultAccess['sites'] ?? <String>{};
    final defaultZones = defaultAccess['zones'] ?? <String>{};
    Set<String> organizationIds = Set<String>.from(
        _userOrganizationAccess[user.id] ?? defaultOrganizations);
    Set<String> siteIds =
        Set<String>.from(_userSiteAccess[user.id] ?? defaultSites);
    Set<String> zoneIds =
        Set<String>.from(_userZoneAccess[user.id] ?? defaultZones);
    var editMode = false;

    showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          final availableSites = db.sites
              .where((s) => organizationIds.contains(s.organizationId))
              .toList();
          final availableZones =
              db.zones.where((z) => siteIds.contains(z.siteId)).toList();

          final organizations = db.organizations
              .where((o) => organizationIds.contains(o.id))
              .map((o) => o.name)
              .toList();
          final sites = db.sites
              .where((s) => siteIds.contains(s.id))
              .map((s) => s.name)
              .toList();
          final zones = db.zones
              .where((z) => zoneIds.contains(z.id))
              .map((z) => z.name)
              .toList();

          return AlertDialog(
            title: Row(
              children: [
                Expanded(child: Text('${user.name} Access')),
                TextButton.icon(
                  onPressed: () => setDialogState(() => editMode = !editMode),
                  icon: Icon(editMode ? Icons.visibility : Icons.edit_outlined),
                  label: Text(editMode ? 'Preview' : 'Edit Access'),
                ),
              ],
            ),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Role: ${user.role[0].toUpperCase()}${user.role.substring(1)}',
                    ),
                    const SizedBox(height: 12),
                    if (!editMode) ...[
                      _accessPreviewSection(
                        title: 'Organizations',
                        icon: Icons.apartment_outlined,
                        values: organizations,
                      ),
                      const SizedBox(height: 10),
                      _accessPreviewSection(
                        title: 'Sites',
                        icon: Icons.business_outlined,
                        values: sites,
                      ),
                      const SizedBox(height: 10),
                      _accessPreviewSection(
                        title: 'Zones',
                        icon: Icons.location_on_outlined,
                        values: zones,
                      ),
                    ] else ...[
                      _editableAccessSection(
                        title: 'Organizations',
                        icon: Icons.apartment_outlined,
                        options: db.organizations
                            .map((o) => MapEntry(o.id, o.name))
                            .toList(),
                        selected: organizationIds,
                        selectedLabels: organizations,
                        onToggle: (id) => setDialogState(() {
                          if (organizationIds.contains(id)) {
                            organizationIds.remove(id);
                          } else {
                            organizationIds.add(id);
                          }
                          siteIds = siteIds
                              .where((s) => db.sites.any((site) =>
                                  site.id == s &&
                                  organizationIds
                                      .contains(site.organizationId)))
                              .toSet();
                          zoneIds = zoneIds
                              .where((z) => db.zones.any((zone) =>
                                  zone.id == z &&
                                  siteIds.contains(zone.siteId)))
                              .toSet();
                        }),
                        onViewAll: () async {
                          final next = await _showAccessSelectorDialog(
                            context: context,
                            title: 'Select Organizations',
                            options: db.organizations
                                .map((o) => MapEntry(o.id, o.name))
                                .toList(),
                            selected: organizationIds,
                          );
                          if (next == null || !context.mounted) return;
                          setDialogState(() {
                            organizationIds = next;
                            siteIds = siteIds
                                .where((s) => db.sites.any((site) =>
                                    site.id == s &&
                                    organizationIds
                                        .contains(site.organizationId)))
                                .toSet();
                            zoneIds = zoneIds
                                .where((z) => db.zones.any((zone) =>
                                    zone.id == z &&
                                    siteIds.contains(zone.siteId)))
                                .toSet();
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _editableAccessSection(
                        title: 'Sites',
                        icon: Icons.business_outlined,
                        options: availableSites
                            .map((s) => MapEntry(s.id, s.name))
                            .toList(),
                        selected: siteIds,
                        selectedLabels: sites,
                        onToggle: (id) => setDialogState(() {
                          if (siteIds.contains(id)) {
                            siteIds.remove(id);
                          } else {
                            siteIds.add(id);
                          }
                          zoneIds = zoneIds
                              .where((z) => db.zones.any((zone) =>
                                  zone.id == z &&
                                  siteIds.contains(zone.siteId)))
                              .toSet();
                        }),
                        onViewAll: () async {
                          final next = await _showAccessSelectorDialog(
                            context: context,
                            title: 'Select Sites',
                            options: availableSites
                                .map((s) => MapEntry(s.id, s.name))
                                .toList(),
                            selected: siteIds,
                          );
                          if (next == null || !context.mounted) return;
                          setDialogState(() {
                            siteIds = next;
                            zoneIds = zoneIds
                                .where((z) => db.zones.any((zone) =>
                                    zone.id == z &&
                                    siteIds.contains(zone.siteId)))
                                .toSet();
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _editableAccessSection(
                        title: 'Zones',
                        icon: Icons.location_on_outlined,
                        options: availableZones
                            .map((z) => MapEntry(z.id, z.name))
                            .toList(),
                        selected: zoneIds,
                        selectedLabels: zones,
                        onToggle: (id) => setDialogState(() {
                          if (zoneIds.contains(id)) {
                            zoneIds.remove(id);
                          } else {
                            zoneIds.add(id);
                          }
                        }),
                        onViewAll: () async {
                          final next = await _showAccessSelectorDialog(
                            context: context,
                            title: 'Select Zones',
                            options: availableZones
                                .map((z) => MapEntry(z.id, z.name))
                                .toList(),
                            selected: zoneIds,
                          );
                          if (next == null || !context.mounted) return;
                          setDialogState(() {
                            zoneIds = next;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              if (editMode)
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _userOrganizationAccess[user.id] =
                          Set<String>.from(organizationIds);
                      _userSiteAccess[user.id] = Set<String>.from(siteIds);
                      _userZoneAccess[user.id] = Set<String>.from(zoneIds);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save Access'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _accessPreviewSection({
    required String title,
    required IconData icon,
    required List<String> values,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD5E3EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF2C5B73)),
              const SizedBox(width: 6),
              Text(
                '$title (${values.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F3948),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (values.isEmpty)
            const Text(
              'No allocation',
              style: TextStyle(color: Color(0xFF607A88)),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: values
                  .map(
                    (v) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1EDF4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        v,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF27485A),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _editableAccessSection({
    required String title,
    required IconData icon,
    required List<MapEntry<String, String>> options,
    required Set<String> selected,
    required List<String> selectedLabels,
    required ValueChanged<String> onToggle,
    required Future<void> Function() onViewAll,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD5E3EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF2C5B73)),
              const SizedBox(width: 6),
              Text(
                '$title (${selected.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F3948),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (options.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onViewAll,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: const BorderSide(color: Color(0xFFB7CBD7)),
                ),
                child: const Text('View All'),
              ),
            ),
          if (options.isNotEmpty) const SizedBox(height: 8),
          if (options.isEmpty)
            const Text(
              'No options available',
              style: TextStyle(color: Color(0xFF607A88)),
            )
          else if (options.length > 12)
            SizedBox(
              height: 148,
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: options
                        .map(
                          (option) => FilterChip(
                            label: Text(option.value),
                            selected: selected.contains(option.key),
                            onSelected: (_) => onToggle(option.key),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: options
                  .map(
                    (option) => FilterChip(
                      label: Text(option.value),
                      selected: selected.contains(option.key),
                      onSelected: (_) => onToggle(option.key),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedLabels.isEmpty
                      ? 'No allocation'
                      : selectedLabels.take(3).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF607A88)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<Set<String>?> _showAccessSelectorDialog({
    required BuildContext context,
    required String title,
    required List<MapEntry<String, String>> options,
    required Set<String> selected,
  }) async {
    final searchController = TextEditingController();
    Set<String> tempSelected = Set<String>.from(selected);
    String query = '';

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final normalized = query.toLowerCase();
          final filtered = options.where((option) {
            return option.value.toLowerCase().contains(normalized) ||
                option.key.toLowerCase().contains(normalized);
          }).toList();

          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 520,
              height: 460,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (value) =>
                        setDialogState(() => query = value.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${tempSelected.length} selected',
                        style: const TextStyle(
                          color: Color(0xFF607A88),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setDialogState(() {
                          tempSelected.clear();
                        }),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching records',
                              style: TextStyle(color: Color(0xFF607A88)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final option = filtered[index];
                              final checked = tempSelected.contains(option.key);
                              return CheckboxListTile(
                                dense: true,
                                value: checked,
                                title: Text(option.value),
                                subtitle: Text(
                                  option.key,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onChanged: (_) {
                                  setDialogState(() {
                                    if (checked) {
                                      tempSelected.remove(option.key);
                                    } else {
                                      tempSelected.add(option.key);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                    dialogContext, Set<String>.from(tempSelected)),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );

    searchController.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserAdminDatabaseProvider>(
      builder: (context, db, child) {
        final isLight = Theme.of(context).brightness == Brightness.light;
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
                      Text(
                        'Manage users and their access control permissions',
                        style: TextStyle(
                          fontSize: 15,
                          color: isLight
                              ? const Color(0xFF4e6473)
                              : const Color(0xFF9db7d2),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildViewToggle(),
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 720;
                  if (!isNarrow) {
                    return Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
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
                            DropdownMenuItem(
                                value: 'all', child: Text('All Roles')),
                            DropdownMenuItem(
                                value: 'admin', child: Text('Admin')),
                            DropdownMenuItem(
                                value: 'engineer', child: Text('Engineer')),
                            DropdownMenuItem(
                                value: 'operator', child: Text('Operator')),
                          ],
                          onChanged: (value) =>
                              setState(() => _roleFilter = value!),
                        ),
                        const SizedBox(width: 10),
                        _dropdown(
                          value: _statusFilter,
                          width: 160,
                          items: const [
                            DropdownMenuItem(
                                value: 'all', child: Text('All Status')),
                            DropdownMenuItem(
                                value: 'active', child: Text('Active')),
                            DropdownMenuItem(
                                value: 'restricted', child: Text('Restricted')),
                          ],
                          onChanged: (value) =>
                              setState(() => _statusFilter = value!),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _dropdown(
                              value: _roleFilter,
                              width: double.infinity,
                              items: const [
                                DropdownMenuItem(
                                    value: 'all', child: Text('All Roles')),
                                DropdownMenuItem(
                                    value: 'admin', child: Text('Admin')),
                                DropdownMenuItem(
                                    value: 'engineer', child: Text('Engineer')),
                                DropdownMenuItem(
                                    value: 'operator', child: Text('Operator')),
                              ],
                              onChanged: (value) =>
                                  setState(() => _roleFilter = value!),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _dropdown(
                              value: _statusFilter,
                              width: double.infinity,
                              items: const [
                                DropdownMenuItem(
                                    value: 'all', child: Text('All Status')),
                                DropdownMenuItem(
                                    value: 'active', child: Text('Active')),
                                DropdownMenuItem(
                                    value: 'restricted',
                                    child: Text('Restricted')),
                              ],
                              onChanged: (value) =>
                                  setState(() => _statusFilter = value!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_isCardView)
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
                      border: Border.all(color: Theme.of(context).dividerColor),
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
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context).brightness ==
                                                Brightness.light
                                            ? const Color(0xFF102632)
                                            : const Color(0xFFE2EDF8),
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
                })
              else
                _buildUsersListView(context, db, users),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewToggle() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFE6EFF3) : const Color(0xFF243E52),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleOption(
            active: _isCardView,
            icon: Icons.grid_view_rounded,
            onTap: () => setState(() => _isCardView = true),
          ),
          _toggleOption(
            active: !_isCardView,
            icon: Icons.view_list_rounded,
            onTap: () => setState(() => _isCardView = false),
          ),
        ],
      ),
    );
  }

  Widget _toggleOption({
    required bool active,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0f729c) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active
              ? Colors.white
              : (isLight ? const Color(0xFF2a414e) : const Color(0xFFD7E8F6)),
        ),
      ),
    );
  }

  Widget _buildUsersListView(
    BuildContext context,
    UserAdminDatabaseProvider db,
    List<User> users,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: users.map((user) {
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
                  s.deviceId == db.devices[userIndex % db.devices.length].id)
              .take(3)
              .map((s) => s.serialNumber)
              .toList();
          final details = <String>[
            'Role: ${user.role}',
            'Status: ${restricted ? 'restricted' : 'active'}',
            'Site: $site',
            'Zone: $zone',
            'Sensors: ${sensorCodes.isEmpty ? 'No Sensors' : sensorCodes.join(', ')}',
          ];

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFDCE7ED),
                      child: Text(
                        _shortName(user.name),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF203845),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? const Color(0xFF102632)
                                  : const Color(0xFFE2EDF8),
                            ),
                          ),
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF516875),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _tag(
                      restricted ? 'Restricted' : 'Open',
                      icon: Icons.lock_outline,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: details
                      .map(
                        (detail) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? const Color(0xFFEAF2F6)
                                    : const Color(0xFF253F52),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Text(
                            detail,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? const Color(0xFF3E5765)
                                  : const Color(0xFFBBD0E0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _actionButton(
                      label: 'View Access',
                      icon: Icons.remove_red_eye_outlined,
                      onTap: () => _showAccessDialog(context, user, db),
                    ),
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
                    _iconAction(
                      icon: Icons.edit_outlined,
                      onTap: () => _showUserModal(user: user),
                    ),
                    _iconAction(
                      icon: Icons.cancel_outlined,
                      iconColor: const Color(0xFFD39A00),
                      onTap: () {
                        setState(() => _restrictedUsers.add(user.id));
                      },
                    ),
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
        }).toList(),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required double width,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: width,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF243E52),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: primary
              ? const Color(0xFF0f729c)
              : (isLight ? const Color(0xFFe6eff3) : const Color(0xFF243E52)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primary
                ? const Color(0xFF0f729c)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: primary
                    ? Colors.white
                    : (isLight
                        ? const Color(0xFF18313f)
                        : const Color(0xFFD7E8F6))),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: primary
                    ? Colors.white
                    : (isLight
                        ? const Color(0xFF18313f)
                        : const Color(0xFFD7E8F6)),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFE2EDF3) : const Color(0xFF2B4659),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color:
                  isLight ? const Color(0xFF2C4654) : const Color(0xFFD7E8F6),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color:
                  isLight ? const Color(0xFF1f3642) : const Color(0xFFD7E8F6),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isLight ? color : const Color(0xFF243E52),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color:
                    isLight ? const Color(0xFF246081) : const Color(0xFFBBD0E0),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isLight
                      ? const Color(0xFF173341)
                      : const Color(0xFFE2EDF8),
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
                        color: isLight
                            ? const Color(0xFFD2E3EC)
                            : const Color(0xFF2B4659),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isLight
                              ? const Color(0xFF203845)
                              : const Color(0xFFD7E8F6),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFE7EFF3) : const Color(0xFF243E52),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isLight ? const Color(0xFF1f3642) : const Color(0xFFD7E8F6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    isLight ? const Color(0xFF1f3642) : const Color(0xFFD7E8F6),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFE7EFF3) : const Color(0xFF243E52),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}
