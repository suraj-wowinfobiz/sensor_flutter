import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_database_provider.dart';

class UserSensorsScreen extends StatefulWidget {
  const UserSensorsScreen({super.key});

  @override
  State<UserSensorsScreen> createState() => _UserSensorsScreenState();
}

class _UserSensorsScreenState extends State<UserSensorsScreen> {
  bool _isCardView = true;
  bool _showFilters = false;
  String _searchQuery = '';
  String _typeFilter = 'all';
  String _deviceFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDatabaseProvider>(
      builder: (context, db, child) {
        final sensors = db.sensors.where((sensor) {
          final deviceCode = db.devices
                  .where((d) => d.id == sensor.deviceId)
                  .map((d) => d.deviceCode)
                  .firstOrNull ??
              '';
          final query = _searchQuery.trim().toLowerCase();
          final matchesSearch = query.isEmpty ||
              sensor.serialNumber.toLowerCase().contains(query) ||
              deviceCode.toLowerCase().contains(query);
          final matchesType =
              _typeFilter == 'all' || sensor.sensorTypeId == _typeFilter;
          final matchesDevice =
              _deviceFilter == 'all' || sensor.deviceId == _deviceFilter;
          return matchesSearch && matchesType && matchesDevice;
        }).toList();
        final isLight = Theme.of(context).brightness == Brightness.light;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  final actions = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildViewToggle(context),
                      _headerButton(
                        context: context,
                        label: 'Filters',
                        icon: Icons.filter_list,
                        onTap: () =>
                            setState(() => _showFilters = !_showFilters),
                      ),
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sensors',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: isLight
                                    ? const Color(0xFF0f202d)
                                    : const Color(0xFFd4e4ef),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'View live sensor readings',
                              style: TextStyle(
                                fontSize: 15,
                                color: isLight
                                    ? const Color(0xFF4e6473)
                                    : const Color(0xFF9db7d2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        actions,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sensors',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: isLight
                                    ? const Color(0xFF0f202d)
                                    : const Color(0xFFd4e4ef),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'View live sensor readings',
                              style: TextStyle(
                                fontSize: 15,
                                color: isLight
                                    ? const Color(0xFF4e6473)
                                    : const Color(0xFF9db7d2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions,
                    ],
                  );
                },
              ),
              if (_showFilters) const SizedBox(height: 14),
              if (_showFilters) _buildFilterPanel(context, db, sensors.length),
              const SizedBox(height: 16),
              if (_isCardView)
                _buildCards(context, sensors)
              else
                _buildList(context, sensors),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewToggle(BuildContext context) {
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
          _toggleButton(
            context: context,
            active: _isCardView,
            icon: Icons.grid_view_rounded,
            onTap: () => setState(() => _isCardView = true),
          ),
          _toggleButton(
            context: context,
            active: !_isCardView,
            icon: Icons.view_list_rounded,
            onTap: () => setState(() => _isCardView = false),
          ),
        ],
      ),
    );
  }

  Widget _headerButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFE6EFF3) : const Color(0xFF243E52),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  isLight ? const Color(0xFF18313F) : const Color(0xFFD7E8F6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    isLight ? const Color(0xFF18313F) : const Color(0xFFD7E8F6),
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
    final compact = MediaQuery.of(context).size.width < 1000;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Sensors',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color:
                  isLight ? const Color(0xFF1A303D) : const Color(0xFFD8E8F5),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final small = constraints.maxWidth < 430;
              final searchWidth =
                  (compact || small) ? constraints.maxWidth : 280.0;
              final filterWidth = small ? constraints.maxWidth : 180.0;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: searchWidth,
                    child: _field(
                      context,
                      'Search',
                      TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Sensor ID, Serial, MAC...',
                          prefixIcon: Icon(Icons.search, size: 20),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: filterWidth,
                    child: _selectField(
                      context: context,
                      label: 'Status',
                      value: 'all',
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Statuses')),
                      ],
                      onChanged: (_) {},
                    ),
                  ),
                  SizedBox(
                    width: filterWidth,
                    child: _selectField(
                      context: context,
                      label: 'Sensor Type',
                      value: _typeFilter,
                      items: [
                        const DropdownMenuItem(
                            value: 'all', child: Text('All Types')),
                        ...db.sensorTypes.map((t) =>
                            DropdownMenuItem(value: t.id, child: Text(t.name))),
                      ],
                      onChanged: (v) =>
                          setState(() => _typeFilter = v ?? 'all'),
                    ),
                  ),
                  SizedBox(
                    width: filterWidth,
                    child: _selectField(
                      context: context,
                      label: 'Device',
                      value: _deviceFilter,
                      items: [
                        const DropdownMenuItem(
                            value: 'all', child: Text('All Devices')),
                        ...db.devices.map((d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(d.deviceCode),
                            )),
                      ],
                      onChanged: (v) =>
                          setState(() => _deviceFilter = v ?? 'all'),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: small ? 0 : 26),
                    child: Text(
                      'Showing $filteredCount of ${db.sensors.length} sensors',
                      style: TextStyle(
                        fontSize: 16,
                        color: isLight
                            ? const Color(0xFF48606E)
                            : const Color(0xFF9FB4C6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _field(BuildContext context, String label, Widget child) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isLight ? const Color(0xFF4D6472) : const Color(0xFF9FB4C6),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _selectField({
    required BuildContext context,
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return _field(
      context,
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
    required BuildContext context,
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
          color: active ? const Color(0xFF0f8f92) : Colors.transparent,
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

  Widget _buildCards(BuildContext context, List<dynamic> sensors) {
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
          itemCount: sensors.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final sensor = sensors[index];
            final status = sensor.lastReading > 4.0
                ? 'critical'
                : sensor.lastReading > 2.8
                    ? 'warning'
                    : 'normal';
            final color = status == 'critical'
                ? const Color(0xFFef2e38)
                : status == 'warning'
                    ? const Color(0xFFd39a00)
                    : const Color(0xFF1f9b58);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sensor.serialNumber,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFF162f3a)
                          : const Color(0xFFE2EDF8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${sensor.lastReading.toStringAsFixed(2)}°',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<dynamic> sensors) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: sensors.map((sensor) {
          final status = sensor.lastReading > 4.0
              ? 'critical'
              : sensor.lastReading > 2.8
                  ? 'warning'
                  : 'normal';
          final color = status == 'critical'
              ? const Color(0xFFef2e38)
              : status == 'warning'
                  ? const Color(0xFFd39a00)
                  : const Color(0xFF1f9b58);
          final installedAt =
              '${sensor.installedAt.day}/${sensor.installedAt.month}/${sensor.installedAt.year}';
          final details = <String>[
            '${sensor.id}',
            '${sensor.serialNumber}',
            '${sensor.sensorTypeId}',
            '${sensor.deviceId}',
            '${sensor.lastReading.toStringAsFixed(2)}°',
            installedAt,
            status,
          ];

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    Icon(Icons.sensors, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sensor.serialNumber,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFF1a2f3b)
                                  : const Color(0xFFE2EDF8),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: color.withValues(alpha: 0.32)),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
