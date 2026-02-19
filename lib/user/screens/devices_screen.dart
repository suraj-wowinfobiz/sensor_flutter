import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_database_provider.dart';

class UserDevicesScreen extends StatefulWidget {
  const UserDevicesScreen({super.key});

  @override
  State<UserDevicesScreen> createState() => _UserDevicesScreenState();
}

class _UserDevicesScreenState extends State<UserDevicesScreen> {
  bool _isCardView = true;
  bool _showFilters = false;
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDatabaseProvider>(
      builder: (context, db, child) {
        final devices = db.devices.where((d) {
          final query = _searchQuery.trim().toLowerCase();
          final matchesSearch =
              query.isEmpty || d.deviceCode.toLowerCase().contains(query);
          final matchesStatus =
              _statusFilter == 'all' || d.status == _statusFilter;
          return matchesSearch && matchesStatus;
        }).toList();
        final isLight = Theme.of(context).brightness == Brightness.light;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Devices',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: isLight
                                ? const Color(0xFF0f202d)
                                : const Color(0xFFd4e4ef),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Monitor gateway devices',
                          style:
                              TextStyle(fontSize: 15, color: Color(0xFF4e6473)),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildViewToggle(),
                      _headerButton(
                        label: 'Filters',
                        icon: Icons.filter_list,
                        onTap: () =>
                            setState(() => _showFilters = !_showFilters),
                      ),
                    ],
                  ),
                ],
              ),
              if (_showFilters) const SizedBox(height: 14),
              if (_showFilters) _buildFilterPanel(context, db, devices.length),
              const SizedBox(height: 16),
              if (_isCardView)
                _buildCards(devices)
              else
                _buildList(context, devices),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EFF3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8D6DD)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton(
            active: _isCardView,
            icon: Icons.grid_view_rounded,
            onTap: () => setState(() => _isCardView = true),
          ),
          _toggleButton(
            active: !_isCardView,
            icon: Icons.view_list_rounded,
            onTap: () => setState(() => _isCardView = false),
          ),
        ],
      ),
    );
  }

  Widget _headerButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE6EFF3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC8D6DD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF18313F)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF18313F),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel(
    BuildContext context,
    UserDatabaseProvider db,
    int filteredCount,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8D6DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Devices',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A303D),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 280,
                child: _field(
                  'Search',
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Device ID, Serial, MAC, IP...',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: _selectField(
                  label: 'Status',
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                        value: 'inactive', child: Text('Inactive')),
                    DropdownMenuItem(
                      value: 'maintenance',
                      child: Text('Maintenance'),
                    ),
                    DropdownMenuItem(value: 'retired', child: Text('Retired')),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 26),
                child: Text(
                  'Showing $filteredCount of ${db.devices.length} devices',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF48606E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF4D6472),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFC8D6DD)),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _selectField({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return _field(
      label,
      DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }

  Widget _toggleButton({
    required bool active,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0f8f92) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? Colors.white : const Color(0xFF2a414e),
        ),
      ),
    );
  }

  Widget _buildCards(List<dynamic> devices) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1200
            ? 4
            : width >= 900
                ? 3
                : width >= 600
                    ? 2
                    : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: devices.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final device = devices[index];
            final active = device.status == 'active';
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC8D6DD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.deviceCode,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF162f3a),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _statusChip(active, device.status),
                  const Spacer(),
                  Text(
                    'Installed: ${device.installedAt.day}/${device.installedAt.month}/${device.installedAt.year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4e6473),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<dynamic> devices) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8D6DD)),
      ),
      child: Column(
        children: devices.map((device) {
          final active = device.status == 'active';
          final installedAt =
              '${device.installedAt.day}/${device.installedAt.month}/${device.installedAt.year}';
          final details = <String>[
            'ID: ${device.id}',
            'Code: ${device.deviceCode}',
            'Status: ${device.status}',
            'Site ID: ${device.siteId}',
            'Zone ID: ${device.zoneId}',
            'Installed: $installedAt',
          ];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFDCE5EA)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.router_rounded,
                      color: active
                          ? const Color(0xFF1f9b58)
                          : const Color(0xFFd39a00),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        device.deviceCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1a2f3b),
                        ),
                      ),
                    ),
                    _statusChip(active, device.status),
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
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2F6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD0DEE6)),
                          ),
                          child: Text(
                            detail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF3E5765),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statusChip(bool active, String status) {
    final color = active ? const Color(0xFF1f9b58) : const Color(0xFFd39a00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
