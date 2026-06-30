import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/ops_theme.dart';
import '../api/users_api.dart';
import '../models/user.dart';
import '../providers/super_admin_backend_provider.dart';

class UsersScreen extends StatefulWidget {
  final String createDefaultRole;
  final List<String> selectableRoles;

  const UsersScreen({
    super.key,
    this.createDefaultRole = 'admin',
    this.selectableRoles = const ['admin', 'vendor', 'vendor_engineer', 'user'],
  });

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
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
  String _role = 'engineer';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final db = context.read<SuperAdminBackendProvider>();
      await db.loadOrganizations();
      await db.loadSites();
      await db.loadDevices();
      await db.loadSensors();
      for (final site in db.sites) {
        await db.loadZones(site.id);
      }
      await db.loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text('Are you sure you want to delete this user?'),
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

  Future<void> _showUserModal({User? user}) async {
    String readString(dynamic value, [String fallback = '']) {
      final parsed = value?.toString().trim() ?? '';
      return parsed.isEmpty ? fallback : parsed;
    }

    if (user != null) {
      _editingId = user.id;
      _name = user.name;
      _email = user.email;
      _role = user.role;
    } else {
      _editingId = null;
      _name = '';
      _email = '';
      _role = widget.createDefaultRole;
    }

    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final roleController = TextEditingController(text: _role);
    final organizationController = TextEditingController();
    final maxUsersAllowedController = TextEditingController(text: '20');
    final passwordController = TextEditingController();

    final parentContext = context;
    final db = parentContext.read<SuperAdminBackendProvider>();
    await db.loadDevices();
    await db.loadSensors();

    Map<String, dynamic> existingUserProfile = const {};
    var selectedSensorIds = <String>{};
    if (user != null) {
      try {
        existingUserProfile = await UsersApi.getUserById(user.id);
      } catch (_) {
        existingUserProfile = const {};
      }
      try {
        selectedSensorIds =
            (await UsersApi.getUserSensorAccess(user.id)).toSet();
      } catch (_) {
        selectedSensorIds = <String>{};
      }
    }

    var selectedOrganizationId = readString(
      existingUserProfile['organizationId'],
      db.organizations.isNotEmpty ? db.organizations.first.id : '',
    );

    String normalizeRole(String value) {
      final lower = value.trim().toLowerCase();
      if (lower == 'vendor_engineer' || lower == 'engineer') {
        return 'vendor_engineer';
      }
      if (lower == 'vendor') return 'vendor';
      if (lower == 'admin') return 'admin';
      if (lower == 'user') return 'user';
      final fallback = widget.selectableRoles.isNotEmpty
          ? widget.selectableRoles.first
          : widget.createDefaultRole;
      if (fallback.trim().toLowerCase() == 'engineer') return 'vendor_engineer';
      return fallback.trim().toLowerCase();
    }

    String labelForRole(String role) {
      switch (role) {
        case 'vendor_engineer':
          return 'Vendor Engineer';
        case 'admin':
          return 'User Admin';
        case 'vendor':
          return 'Vendor';
        case 'user':
          return 'User';
        default:
          return role;
      }
    }

    List<DropdownMenuItem<String>> roleItems() {
      return widget.selectableRoles
          .map(
            (role) => DropdownMenuItem<String>(
              value: role,
              child: Text(labelForRole(role)),
            ),
          )
          .toList();
    }

    List<SensorOption> sensorOptionsForOrganization(String organizationId) {
      final deviceById = {for (final device in db.devices) device.id: device};
      final siteById = {for (final site in db.sites) site.id: site};
      final options = db.sensors.where((sensor) {
        final device = deviceById[sensor.deviceId];
        if (device == null) return false;
        final site = siteById[device.siteId];
        return site?.organizationId == organizationId;
      }).map((sensor) {
        final device = deviceById[sensor.deviceId];
        return SensorOption(
          id: sensor.id,
          label:
              '${sensor.name} • ${(device?.deviceCode ?? sensor.deviceName).trim().isEmpty ? sensor.serialNumber : (device?.deviceCode ?? sensor.deviceName)}',
        );
      }).toList()
        ..sort(
            (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      return options;
    }

    if (!parentContext.mounted) return;
    await showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final theme = Theme.of(dialogContext);
          final isLight = theme.brightness == Brightness.light;
          final isDialogLight = theme.brightness == Brightness.light;
          final normalizedRole = normalizeRole(roleController.text);
          final sensorOptions =
              sensorOptionsForOrganization(selectedOrganizationId);
          final allowedSensorIds =
              sensorOptions.map((option) => option.id).toSet();
          selectedSensorIds =
              selectedSensorIds.where(allowedSensorIds.contains).toSet();

          Future<void> saveUser() async {
            final name = nameController.text.trim();
            final email = emailController.text.trim();
            final role = normalizeRole(roleController.text);
            final maxUsersAllowed =
                int.tryParse(maxUsersAllowedController.text.trim());
            final password = passwordController.text.trim();
            final visibleSensorIds = selectedSensorIds.toList()..sort();

            if (name.isEmpty || email.isEmpty) {
              ScaffoldMessenger.of(parentContext).showSnackBar(
                const SnackBar(content: Text('Name and email are required')),
              );
              return;
            }
            if (db.organizations.isEmpty) {
              ScaffoldMessenger.of(parentContext).showSnackBar(
                const SnackBar(
                    content: Text('Please create organization first')),
              );
              return;
            }
            if (selectedOrganizationId.isEmpty) {
              ScaffoldMessenger.of(parentContext).showSnackBar(
                const SnackBar(content: Text('Please select organization')),
              );
              return;
            }
            if (_editingId == null &&
                (maxUsersAllowed == null || maxUsersAllowed <= 0)) {
              ScaffoldMessenger.of(parentContext).showSnackBar(
                const SnackBar(
                    content:
                        Text('Max users allowed must be a positive number')),
              );
              return;
            }
            if (_editingId == null && password.isEmpty) {
              ScaffoldMessenger.of(parentContext).showSnackBar(
                const SnackBar(content: Text('Password is required')),
              );
              return;
            }

            final payload = {
              'name': name,
              'email': email,
              'role': role,
              'organization_id': selectedOrganizationId,
              if (_editingId == null) 'password': password,
              if (_editingId != null && password.isNotEmpty)
                'password': password,
              if (_editingId == null) 'maxUsersAllowed': maxUsersAllowed,
              if (role == 'user') 'sensor_ids': visibleSensorIds,
            };
            try {
              if (_editingId == null) {
                await db.create('users', payload);
              } else {
                await db.update('users', _editingId!, payload);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            } catch (e) {
              if (parentContext.mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text('Failed to save user: $e')),
                );
              }
            }
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(
                        alpha: isDialogLight ? 0.1 : 0.22,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Color(0xFF0f729c), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user == null ? 'Create New User' : 'Edit User',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 34 > 30 ? 34 - 4 : 30,
                                fontWeight: FontWeight.w800,
                                color: isLight
                                    ? const Color(0xFF142936)
                                    : const Color(0xFFE2EDF8),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                                width: 32, height: 32),
                            icon: Icon(
                              Icons.close,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        user == null
                            ? 'Enter user details and access role'
                            : 'Update user details and access role',
                        style: TextStyle(
                          fontSize: 15,
                          color: isLight
                              ? const Color(0xFF506775)
                              : const Color(0xFFBBD0E0),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...[
                        const SizedBox(height: 2),
                        Text(
                          'Full Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isLight
                                ? const Color(0xFF1B313D)
                                : const Color(0xFFE2EDF8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _textInput(
                          controller: nameController,
                          hintText: 'John Doe',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isLight
                                ? const Color(0xFF1B313D)
                                : const Color(0xFFE2EDF8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _textInput(
                          controller: emailController,
                          hintText: 'john@example.com',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Role',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isLight
                                ? const Color(0xFF1B313D)
                                : const Color(0xFFE2EDF8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (widget.selectableRoles.length == 1)
                          _selectBox(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                labelForRole(widget.selectableRoles.first),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isLight
                                      ? const Color(0xFF1B313D)
                                      : const Color(0xFFE2EDF8),
                                ),
                              ),
                            ),
                          )
                        else
                          _selectBox(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: widget.selectableRoles.contains(
                                        normalizeRole(roleController.text))
                                    ? normalizeRole(roleController.text)
                                    : (widget.selectableRoles.isNotEmpty
                                        ? widget.selectableRoles.first
                                        : normalizeRole(roleController.text)),
                                isExpanded: true,
                                isDense: true,
                                items: roleItems(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      roleController.text = value;
                                      if (normalizeRole(value) != 'user') {
                                        selectedSensorIds = <String>{};
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          'Organization',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isLight
                                ? const Color(0xFF1B313D)
                                : const Color(0xFFE2EDF8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _selectBox(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: db.organizations.any(
                                (o) => o.id == selectedOrganizationId,
                              )
                                  ? selectedOrganizationId
                                  : null,
                              isExpanded: true,
                              hint: const Text('Select organization'),
                              isDense: true,
                              items: db.organizations
                                  .map((org) => DropdownMenuItem<String>(
                                        value: org.id,
                                        child: Text(org.name),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedOrganizationId = value;
                                    final org = db.organizations
                                        .firstWhere((o) => o.id == value);
                                    organizationController.text = org.name;
                                    final allowed =
                                        sensorOptionsForOrganization(
                                      value,
                                    ).map((option) => option.id).toSet();
                                    selectedSensorIds = selectedSensorIds
                                        .where(allowed.contains)
                                        .toSet();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        if (normalizedRole == 'user') ...[
                          const SizedBox(height: 10),
                          Text(
                            'Visible Sensors',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isLight
                                  ? const Color(0xFF1B313D)
                                  : const Color(0xFFE2EDF8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (sensorOptions.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isLight
                                    ? const Color(0xFFF7FAFC)
                                    : const Color(0xFF1A3347),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              child: Text(
                                'No sensors available in the selected organization.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isLight
                                      ? const Color(0xFF506775)
                                      : const Color(0xFFBBD0E0),
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: sensorOptions.map((option) {
                                final isSelected =
                                    selectedSensorIds.contains(option.id);
                                return FilterChip(
                                  label: Text(option.label),
                                  selected: isSelected,
                                  onSelected: (value) {
                                    setState(() {
                                      if (value) {
                                        selectedSensorIds.add(option.id);
                                      } else {
                                        selectedSensorIds.remove(option.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                        ],
                        ...[
                          const SizedBox(height: 10),
                          Text(
                            _editingId == null
                                ? 'Password'
                                : 'Password (optional)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isLight
                                  ? const Color(0xFF1B313D)
                                  : const Color(0xFFE2EDF8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _textInput(
                            controller: passwordController,
                            hintText: 'Enter password',
                            obscureText: true,
                          ),
                        ],
                        if (_editingId == null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Max users allowed',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isLight
                                  ? const Color(0xFF1B313D)
                                  : const Color(0xFFE2EDF8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _textInput(
                            controller: maxUsersAllowedController,
                            hintText: '20',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                        const SizedBox(height: 14),
                        _dialogActions(
                          dialogContext: dialogContext,
                          onSave: saveUser,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dialogActions({
    required BuildContext dialogContext,
    required VoidCallback onSave,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: onSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(_editingId == null ? 'Create User' : 'Update User'),
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: onSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(_editingId == null ? 'Create User' : 'Update User'),
              ),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    bool filled = true,
  }) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final fillColor =
        isLight ? const Color(0xFFF7FAFC) : const Color(0xFF1A3347);
    final borderColor = theme.dividerColor;

    OutlineInputBorder border([Color? color, double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: color ?? borderColor,
          width: width,
        ),
      );
    }

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: isLight ? const Color(0xFF607A88) : const Color(0xFF9FB4C6),
      ),
      filled: filled,
      fillColor: fillColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: border(),
      enabledBorder: border(),
      focusedBorder:
          border(theme.colorScheme.primary.withValues(alpha: 0.55), 1.4),
      errorBorder: border(theme.colorScheme.error),
      focusedErrorBorder:
          border(theme.colorScheme.error.withValues(alpha: 0.85), 1.4),
    );
  }

  Widget _textInput({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textAlignVertical: TextAlignVertical.center,
      style: TextStyle(
        fontSize: 14,
        color: isLight ? const Color(0xFF1B313D) : const Color(0xFFE2EDF8),
      ),
      decoration: _fieldDecoration(hintText: hintText),
    );
  }

  Widget _selectBox({required Widget child}) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF7FAFC) : const Color(0xFF1A3347),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }

  String _shortName(String name) {
    final parts = name.split(' ').where((e) => e.trim().isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  List<User> _applyFilters(List<User> users) {
    final allowedRoles = widget.selectableRoles.map((role) {
      if (role == 'engineer') return 'vendor_engineer';
      return role.trim().toLowerCase();
    }).toSet();

    return users.where((u) {
      final normalizedRole = u.role.trim().toLowerCase();
      final matchesAllowedRoles =
          allowedRoles.isEmpty || allowedRoles.contains(normalizedRole);
      final matchesSearch = _searchText.isEmpty ||
          u.name.toLowerCase().contains(_searchText.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchText.toLowerCase());
      final matchesRole = _roleFilter == 'all' || normalizedRole == _roleFilter;
      final isRestricted = _restrictedUsers.contains(u.id);
      final status = isRestricted ? 'restricted' : 'active';
      final matchesStatus = _statusFilter == 'all' || _statusFilter == status;
      return matchesAllowedRoles &&
          matchesSearch &&
          matchesRole &&
          matchesStatus;
    }).toList();
  }

  List<DropdownMenuItem<String>> _roleFilterItems() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'all', child: Text('All Roles')),
    ];

    for (final role in widget.selectableRoles) {
      switch (role) {
        case 'admin':
          items.add(
            const DropdownMenuItem(value: 'admin', child: Text('User Admin')),
          );
          break;
        case 'vendor':
          items.add(
            const DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
          );
          break;
        case 'vendor_engineer':
          items.add(
            const DropdownMenuItem(
              value: 'vendor_engineer',
              child: Text('Vendor Engineer'),
            ),
          );
          break;
        case 'user':
          items.add(
            const DropdownMenuItem(value: 'user', child: Text('User')),
          );
          break;
      }
    }

    return items;
  }

  Map<String, Set<String>> _defaultAccessForUser(
    User user,
    SuperAdminBackendProvider db,
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

  String _principalTypeForRole(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized == 'engineer') return 'USER';
    if (normalized == 'user') return 'USER';
    if (normalized == 'vendor') return 'VENDOR';
    if (normalized == 'vendor_engineer') return 'VENDOR_ENGINEER';
    if (normalized == 'super_admin') return 'SUPER_ADMIN';
    return 'ADMIN';
  }

  Map<String, String> _parseAssignmentKey(String key) {
    final parts = key.split('|');
    return {
      'type': parts.isNotEmpty ? parts.first : '',
      'id': parts.length > 1 ? parts[1] : '',
    };
  }

  String _asTrimmedString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String? _assignmentKeyFromScope({
    String? organizationId,
    String? siteId,
    String? zoneId,
  }) {
    final normalizedOrganizationId = _asTrimmedString(organizationId);
    final normalizedSiteId = _asTrimmedString(siteId);
    final normalizedZoneId = _asTrimmedString(zoneId);
    if (normalizedOrganizationId.isNotEmpty) {
      return 'organization|$normalizedOrganizationId';
    }
    if (normalizedSiteId.isNotEmpty) return 'site|$normalizedSiteId';
    if (normalizedZoneId.isNotEmpty) return 'zone|$normalizedZoneId';
    return null;
  }

  List<Map<String, dynamic>> _scopesFromAccess(Map<String, dynamic> access) {
    final scopes = <Map<String, dynamic>>[];
    final rawScopes = access['scopes'];
    if (rawScopes is List) {
      for (final raw in rawScopes) {
        if (raw is Map<String, dynamic>) {
          scopes.add(raw);
        } else if (raw is Map) {
          scopes.add(raw.cast<String, dynamic>());
        }
      }
    }

    final rawScope = access['scope'];
    if (rawScope is Map<String, dynamic>) {
      scopes.add(rawScope);
    } else if (rawScope is Map) {
      scopes.add(rawScope.cast<String, dynamic>());
    }

    final organizationId = _asTrimmedString(
      access['organizationId'] ??
          access['organization_id'] ??
          (access['organization'] is Map
              ? (access['organization'] as Map)['organizationId']
              : null),
    );
    final siteId = _asTrimmedString(
      access['siteId'] ?? access['site_id'] ?? access['sitesID'],
    );
    final zoneId = _asTrimmedString(
      access['zoneId'] ?? access['zone_id'] ?? access['zonesID'],
    );
    if (organizationId.isNotEmpty || siteId.isNotEmpty || zoneId.isNotEmpty) {
      scopes.add({
        if (organizationId.isNotEmpty) 'organizationId': organizationId,
        if (siteId.isNotEmpty) 'siteId': siteId,
        if (zoneId.isNotEmpty) 'zoneId': zoneId,
      });
    }
    return scopes;
  }

  Future<Map<String, String>> _fetchAccessIdsByKey({
    required String principalType,
    required String principalId,
  }) async {
    final rawList = await UsersApi.getAccessList();
    final byKey = <String, String>{};
    for (final item in rawList) {
      final itemPrincipalType =
          _asTrimmedString(item['principalType']).toUpperCase();
      final itemPrincipalId = _asTrimmedString(item['principalId']);
      if (itemPrincipalType != principalType.toUpperCase() ||
          itemPrincipalId != principalId) {
        continue;
      }
      final accessId = _asTrimmedString(item['id']);
      if (accessId.isEmpty) continue;
      final scopes = _scopesFromAccess(item);
      for (final scope in scopes) {
        final key = _assignmentKeyFromScope(
          organizationId: scope['organizationId'] ?? scope['organization_id'],
          siteId: scope['siteId'] ?? scope['site_id'] ?? scope['sitesID'],
          zoneId: scope['zoneId'] ?? scope['zone_id'] ?? scope['zonesID'],
        );
        if (key != null && key.isNotEmpty) {
          byKey[key] = accessId;
        }
      }
    }
    return byKey;
  }

  List<Map<String, String>> _buildAccessScopes({
    required Set<String> siteIds,
    required Set<String> zoneIds,
    required SuperAdminBackendProvider db,
  }) {
    final scopes = <Map<String, String>>[];
    final siteIdsWithZone = <String>{};

    for (final zone in db.zones.where((z) => zoneIds.contains(z.id))) {
      final siteId = zone.siteId.trim();
      final zoneId = zone.id.trim();
      if (siteId.isEmpty || zoneId.isEmpty) continue;
      scopes.add({'siteId': siteId, 'zoneId': zoneId});
      siteIdsWithZone.add(siteId);
    }

    for (final siteId in siteIds) {
      final normalizedSiteId = siteId.trim();
      if (normalizedSiteId.isEmpty) continue;
      if (siteIdsWithZone.contains(normalizedSiteId)) continue;
      scopes.add({'siteId': normalizedSiteId});
    }
    return scopes;
  }

  Future<void> _showAccessDialog(
      BuildContext context, User user, SuperAdminBackendProvider db) async {
    final principalType = _principalTypeForRole(user.role);
    final defaultAccess = _defaultAccessForUser(user, db);
    final defaultOrganizations = defaultAccess['organizations'] ?? <String>{};
    final defaultSites = defaultAccess['sites'] ?? <String>{};
    final defaultZones = defaultAccess['zones'] ?? <String>{};

    Set<String> scopedSitesFromKeys(Set<String> keys) {
      final scoped = <String>{};
      for (final key in keys) {
        final parsed = _parseAssignmentKey(key);
        final type = parsed['type'] ?? '';
        final id = parsed['id'] ?? '';
        if (type == 'site' && id.isNotEmpty) {
          scoped.add(id);
        } else if (type == 'zone' && id.isNotEmpty) {
          final zoneSite = db.zones
              .where((zone) => zone.id == id)
              .map((zone) => zone.siteId)
              .firstOrNull;
          if (zoneSite != null && zoneSite.trim().isNotEmpty) {
            scoped.add(zoneSite);
          }
        }
      }
      return scoped;
    }

    Set<String> scopedOrganizationsFromSites(Set<String> scopedSiteIds) {
      return db.sites
          .where((site) => scopedSiteIds.contains(site.id))
          .map((site) => site.organizationId)
          .where((id) => id.trim().isNotEmpty)
          .toSet();
    }

    Set<String> resolvedOrganizationIds = Set<String>.from(
        _userOrganizationAccess[user.id] ?? defaultOrganizations);
    Set<String> resolvedSiteIds =
        Set<String>.from(_userSiteAccess[user.id] ?? defaultSites);
    Set<String> resolvedZoneIds =
        Set<String>.from(_userZoneAccess[user.id] ?? defaultZones);

    try {
      final accessIdsByKey = await _fetchAccessIdsByKey(
        principalType: principalType,
        principalId: user.id,
      );
      if (accessIdsByKey.isNotEmpty) {
        final apiOrganizationIds = <String>{};
        final apiSiteIds = <String>{};
        final apiZoneIds = <String>{};
        for (final key in accessIdsByKey.keys) {
          final parsed = _parseAssignmentKey(key);
          final type = parsed['type'] ?? '';
          final id = parsed['id'] ?? '';
          if (id.trim().isEmpty) continue;
          if (type == 'organization') apiOrganizationIds.add(id);
          if (type == 'site') apiSiteIds.add(id);
          if (type == 'zone') apiZoneIds.add(id);
        }
        resolvedOrganizationIds = apiOrganizationIds;
        resolvedSiteIds = apiSiteIds;
        resolvedZoneIds = apiZoneIds;
        if (resolvedOrganizationIds.isEmpty) {
          resolvedOrganizationIds = scopedOrganizationsFromSites(
            scopedSitesFromKeys(accessIdsByKey.keys.toSet()),
          );
        }
      }
    } catch (_) {
      // Keep local/default fallback if access list fails.
    }

    Set<String> organizationIds = Set<String>.from(
        resolvedOrganizationIds.isEmpty
            ? defaultOrganizations
            : resolvedOrganizationIds);
    Set<String> siteIds = Set<String>.from(resolvedSiteIds);
    Set<String> zoneIds = Set<String>.from(resolvedZoneIds);
    var editMode = false;
    var isSubmitting = false;

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final isLight = theme.brightness == Brightness.light;
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
          final screenSize = MediaQuery.sizeOf(context);
          final dialogWidth = (screenSize.width * 0.92).clamp(320.0, 560.0);

          return AlertDialog(
            backgroundColor: isLight
                ? theme.cardColor
                : Color.alphaBlend(
                    theme.colorScheme.primary.withValues(alpha: 0.06),
                    theme.cardColor,
                  ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user.name} Access'),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setDialogState(() => editMode = !editMode),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(
                      editMode ? Icons.visibility : Icons.edit_outlined,
                    ),
                    label: Text(editMode ? 'Preview' : 'Edit Access'),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: dialogWidth,
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
                        onToggle: (id) {
                          setDialogState(() {
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
                          });
                        },
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
                        onToggle: (id) {
                          setDialogState(() {
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
                            organizationIds = db.sites
                                .where((site) => siteIds.contains(site.id))
                                .map((site) => site.organizationId)
                                .toSet();
                          });
                        },
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
                            organizationIds = db.sites
                                .where((site) => siteIds.contains(site.id))
                                .map((site) => site.organizationId)
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
                        onToggle: (id) {
                          setDialogState(() {
                            if (zoneIds.contains(id)) {
                              zoneIds.remove(id);
                            } else {
                              zoneIds.add(id);
                            }
                            final zoneBackedSiteIds = db.zones
                                .where((zone) => zoneIds.contains(zone.id))
                                .map((zone) => zone.siteId)
                                .toSet();
                            siteIds = siteIds.union(zoneBackedSiteIds);
                            organizationIds = db.sites
                                .where((site) => siteIds.contains(site.id))
                                .map((site) => site.organizationId)
                                .toSet();
                          });
                        },
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
                            final zoneBackedSiteIds = db.zones
                                .where((zone) => zoneIds.contains(zone.id))
                                .map((zone) => zone.siteId)
                                .toSet();
                            siteIds = siteIds.union(zoneBackedSiteIds);
                            organizationIds = db.sites
                                .where((site) => siteIds.contains(site.id))
                                .map((site) => site.organizationId)
                                .toSet();
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
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            final scopes = _buildAccessScopes(
                              siteIds: siteIds,
                              zoneIds: zoneIds,
                              db: db,
                            );
                            if (scopes.isEmpty) {
                              throw Exception(
                                'Select at least one site or zone before submit.',
                              );
                            }
                            await UsersApi.createAccess(
                              principalType: principalType,
                              principalId: user.id,
                              scopes: scopes,
                            );
                            if (!context.mounted) return;
                            setState(() {
                              _userOrganizationAccess[user.id] =
                                  Set<String>.from(organizationIds);
                              _userSiteAccess[user.id] =
                                  Set<String>.from(siteIds);
                              _userZoneAccess[user.id] =
                                  Set<String>.from(zoneIds);
                            });
                            setDialogState(() {
                              editMode = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Access updated successfully'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update access: $e'),
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF3F8FB) : const Color(0xFF243E52),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight ? const Color(0xFFD5E3EA) : const Color(0xFF36566C),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    isLight ? const Color(0xFF2C5B73) : const Color(0xFFBBD0E0),
              ),
              const SizedBox(width: 6),
              Text(
                '$title (${values.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isLight
                      ? const Color(0xFF1F3948)
                      : const Color(0xFFE2EDF8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (values.isEmpty)
            Text(
              'No allocation',
              style: TextStyle(
                color:
                    isLight ? const Color(0xFF607A88) : const Color(0xFF9FB4C6),
              ),
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
                        color: isLight
                            ? const Color(0xFFE1EDF4)
                            : const Color(0xFF2A475C),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        v,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isLight
                              ? const Color(0xFF27485A)
                              : const Color(0xFFD7E8F6),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF3F8FB) : const Color(0xFF243E52),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight ? const Color(0xFFD5E3EA) : const Color(0xFF36566C),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    isLight ? const Color(0xFF2C5B73) : const Color(0xFFBBD0E0),
              ),
              const SizedBox(width: 6),
              Text(
                '$title (${selected.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isLight
                      ? const Color(0xFF1F3948)
                      : const Color(0xFFE2EDF8),
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
                  side: BorderSide(
                    color: isLight
                        ? const Color(0xFFB7CBD7)
                        : const Color(0xFF4A6B80),
                  ),
                ),
                child: const Text('View All'),
              ),
            ),
          if (options.isNotEmpty) const SizedBox(height: 8),
          if (options.isEmpty)
            Text(
              'No options available',
              style: TextStyle(
                color:
                    isLight ? const Color(0xFF607A88) : const Color(0xFF9FB4C6),
              ),
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
                            label: Text(
                              option.value,
                              style: TextStyle(
                                color: selected.contains(option.key)
                                    ? (isLight
                                        ? const Color(0xFF1D3949)
                                        : const Color(0xFFE7F3FF))
                                    : (isLight
                                        ? const Color(0xFF3D5C6E)
                                        : const Color(0xFFB9CDDD)),
                              ),
                            ),
                            selected: selected.contains(option.key),
                            selectedColor: isLight
                                ? const Color(0xFFD7ECF8)
                                : const Color(0xFF35596F),
                            backgroundColor: isLight
                                ? const Color(0xFFF6FAFD)
                                : const Color(0xFF2A465A),
                            checkmarkColor: isLight
                                ? const Color(0xFF2E5E77)
                                : const Color(0xFFDDEBFA),
                            side: BorderSide(
                              color: selected.contains(option.key)
                                  ? (isLight
                                      ? const Color(0xFF8CB4CA)
                                      : const Color(0xFF6E96AE))
                                  : (isLight
                                      ? const Color(0xFFC7D9E4)
                                      : const Color(0xFF4A6B80)),
                            ),
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
                      label: Text(
                        option.value,
                        style: TextStyle(
                          color: selected.contains(option.key)
                              ? (isLight
                                  ? const Color(0xFF1D3949)
                                  : const Color(0xFFE7F3FF))
                              : (isLight
                                  ? const Color(0xFF3D5C6E)
                                  : const Color(0xFFB9CDDD)),
                        ),
                      ),
                      selected: selected.contains(option.key),
                      selectedColor: isLight
                          ? const Color(0xFFD7ECF8)
                          : const Color(0xFF35596F),
                      backgroundColor: isLight
                          ? const Color(0xFFF6FAFD)
                          : const Color(0xFF2A465A),
                      checkmarkColor: isLight
                          ? const Color(0xFF2E5E77)
                          : const Color(0xFFDDEBFA),
                      side: BorderSide(
                        color: selected.contains(option.key)
                            ? (isLight
                                ? const Color(0xFF8CB4CA)
                                : const Color(0xFF6E96AE))
                            : (isLight
                                ? const Color(0xFFC7D9E4)
                                : const Color(0xFF4A6B80)),
                      ),
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
                  style: TextStyle(
                    color: isLight
                        ? const Color(0xFF607A88)
                        : const Color(0xFF9FB4C6),
                  ),
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
          final theme = Theme.of(context);
          final isLight = theme.brightness == Brightness.light;
          final normalized = query.toLowerCase();
          final filtered = options.where((option) {
            return option.value.toLowerCase().contains(normalized) ||
                option.key.toLowerCase().contains(normalized);
          }).toList();
          final screenSize = MediaQuery.sizeOf(context);
          final dialogWidth = (screenSize.width * 0.92).clamp(300.0, 520.0);
          final dialogHeight = (screenSize.height * 0.72).clamp(360.0, 460.0);

          return AlertDialog(
            backgroundColor: isLight
                ? theme.cardColor
                : Color.alphaBlend(
                    theme.colorScheme.primary.withValues(alpha: 0.06),
                    theme.cardColor,
                  ),
            title: Text(title),
            content: SizedBox(
              width: dialogWidth,
              height: dialogHeight,
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
                        style: TextStyle(
                          color: isLight
                              ? const Color(0xFF607A88)
                              : const Color(0xFF9FB4C6),
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
                        ? Center(
                            child: Text(
                              'No matching records',
                              style: TextStyle(
                                color: isLight
                                    ? const Color(0xFF607A88)
                                    : const Color(0xFF9FB4C6),
                              ),
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isLight
                                        ? const Color(0xFF607A88)
                                        : const Color(0xFF9FB4C6),
                                  ),
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
    return Consumer<SuperAdminBackendProvider>(
      builder: (context, db, child) {
        final users = _applyFilters(db.users);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
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
                      const Text(
                        'User Management',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: OpsColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Manage users and their access control permissions',
                        style: TextStyle(
                          fontSize: 15,
                          color: OpsColors.muted,
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
                  final isNarrow = constraints.maxWidth < 860;
                  if (!isNarrow) {
                    final dropdownWidth =
                        constraints.maxWidth < 980 ? 140.0 : 160.0;
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
                          width: dropdownWidth,
                          items: _roleFilterItems(),
                          onChanged: (value) =>
                              setState(() => _roleFilter = value!),
                        ),
                        const SizedBox(width: 10),
                        _dropdown(
                          value: _statusFilter,
                          width: dropdownWidth,
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
                              items: _roleFilterItems(),
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
                  final safeUserIndex = userIndex < 0 ? 0 : userIndex;
                  final site = db.sites.isNotEmpty
                      ? db.sites[safeUserIndex % db.sites.length].name
                      : 'No Site';
                  final zone = db.zones.isNotEmpty
                      ? db.zones[safeUserIndex % db.zones.length].name
                      : 'No Zone';
                  final sensorCodes = db.devices.isEmpty
                      ? <String>[]
                      : db.sensors
                          .where((s) =>
                              s.deviceId ==
                              db.devices[safeUserIndex % db.devices.length].id)
                          .take(2)
                          .map((s) => s.serialNumber)
                          .toList();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: OpsColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: OpsColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              OpsColors.primary.withValues(alpha: .10),
                          child: Text(
                            _shortName(user.name),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: OpsColors.primary,
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
                                        color: OpsColors.text,
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
                                style: TextStyle(
                                  fontSize: 14,
                                  color: OpsColors.muted,
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
                                    icon: restricted
                                        ? Icons.lock_outline
                                        : Icons.lock_open_outlined,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _accessBlock(
                                title: 'Organization (0)',
                                icon: Icons.business,
                                color: const Color(0xFFE2F0F8),
                                chips: [site],
                              ),
                              const SizedBox(height: 8),
                              _accessBlock(
                                title: 'Site (1)',
                                icon: Icons.location_on_outlined,
                                color: const Color(0xFFE8EBF9),
                                chips: [zone],
                              ),
                              const SizedBox(height: 8),
                              _accessBlock(
                                title: 'Zone (0)',
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
                              icon: restricted
                                  ? Icons.lock_outline
                                  : Icons.lock_open_outlined,
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
                              icon: Icons.delete_outline,
                              iconColor: Colors.red,
                              onTap: () async {
                                final confirm = await _confirmDelete(context);
                                if (!confirm || !context.mounted) return;
                                try {
                                  await db.delete('users', user.id);
                                  await db.loadUsers();
                                  if (mounted) setState(() {});
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Failed to delete user: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
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
    SuperAdminBackendProvider db,
    List<User> users,
  ) {
    final isLight = Theme.of(context).brightness == Brightness.light;
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
          final safeUserIndex = userIndex < 0 ? 0 : userIndex;
          final site = db.sites.isNotEmpty
              ? db.sites[safeUserIndex % db.sites.length].name
              : 'No Site';
          final zone = db.zones.isNotEmpty
              ? db.zones[safeUserIndex % db.zones.length].name
              : 'No Zone';
          final sensorCodes = db.devices.isEmpty
              ? <String>[]
              : db.sensors
                  .where((s) =>
                      s.deviceId ==
                      db.devices[safeUserIndex % db.devices.length].id)
                  .take(3)
                  .map((s) => s.serialNumber)
                  .toList();
          final details = <String>[
            user.role,
            restricted ? 'restricted' : 'active',
            site,
            zone,
            sensorCodes.isEmpty ? 'No Sensors' : sensorCodes.join(', '),
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
                      backgroundColor: isLight
                          ? const Color(0xFFDCE7ED)
                          : const Color(0xFF2A475A),
                      child: Text(
                        _shortName(user.name),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isLight
                              ? const Color(0xFF203845)
                              : const Color(0xFFDDEAF6),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isLight
                                  ? const Color(0xFF516875)
                                  : const Color(0xFFBBD0E0),
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
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFFEAF2F6)
                        : const Color(0xFF253F52),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    details.join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFF3E5765)
                          : const Color(0xFFBBD0E0),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
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
                      icon: restricted
                          ? Icons.lock_outline
                          : Icons.lock_open_outlined,
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
                      icon: Icons.delete_outline,
                      iconColor: Colors.red,
                      onTap: () async {
                        final confirm = await _confirmDelete(context);
                        if (!confirm || !context.mounted) return;
                        try {
                          await db.delete('users', user.id);
                          await db.loadUsers();
                          if (mounted) setState(() {});
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete user: $e'),
                              ),
                            );
                          }
                        }
                      },
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
    Color? iconColor,
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
        child: Icon(
          icon,
          size: 18,
          color: iconColor ??
              (isLight ? const Color(0xFF2f4654) : const Color(0xFFD7E8F6)),
        ),
      ),
    );
  }
}

class SensorOption {
  const SensorOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}
