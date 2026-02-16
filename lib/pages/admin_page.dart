import 'dart:math';

import 'package:flutter/material.dart';

enum _AdminView {
  dashboard,
  users,
  organizations,
  sites,
  zones,
  devices,
  sensors,
  alerts,
  thresholds,
  audit,
  config,
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Random _random = Random();

  bool _darkTheme = false;
  _AdminView _currentView = _AdminView.dashboard;

  late final List<Map<String, dynamic>> _organizations;
  late final List<Map<String, dynamic>> _sites;
  late final List<Map<String, dynamic>> _zones;
  late final List<Map<String, dynamic>> _devices;
  late final List<Map<String, dynamic>> _sensorTypes;
  late final List<Map<String, dynamic>> _sensors;
  late final List<Map<String, dynamic>> _users;
  late final List<Map<String, dynamic>> _thresholdProfiles;
  late final List<Map<String, dynamic>> _alerts;
  late final List<Map<String, dynamic>> _auditLogs;
  late final Map<String, dynamic> _config;

  @override
  void initState() {
    super.initState();
    _seedData();
  }

  void _seedData() {
    String id(int n) => 'id-${n.toString().padLeft(3, '0')}';
    final now = DateTime.now();

    _organizations = [
      {
        'id': id(1),
        'name': 'Smart Building Solutions',
        'email': 'contact@sbs.com',
        'status': 'active',
        'created_at': now,
      },
      {
        'id': id(2),
        'name': 'Industrial Monitoring Inc',
        'email': 'info@imi.com',
        'status': 'active',
        'created_at': now,
      },
      {
        'id': id(3),
        'name': 'Environmental Systems Ltd',
        'email': 'admin@ensys.com',
        'status': 'inactive',
        'created_at': now,
      },
    ];

    _sites = [
      {
        'id': id(11),
        'organization_id': id(1),
        'name': 'HQ Building (NYC)',
        'location': 'New York',
        'created_at': now,
      },
      {
        'id': id(12),
        'organization_id': id(1),
        'name': 'R&D Center (Boston)',
        'location': 'Boston',
        'created_at': now,
      },
      {
        'id': id(13),
        'organization_id': id(2),
        'name': 'Factory A (Detroit)',
        'location': 'Detroit',
        'created_at': now,
      },
    ];

    _zones = [
      {'id': id(21), 'site_id': id(11), 'name': 'Zone A - Structural'},
      {'id': id(22), 'site_id': id(11), 'name': 'Zone B - HVAC'},
      {'id': id(23), 'site_id': id(12), 'name': 'Lab Zone 1'},
      {'id': id(24), 'site_id': id(13), 'name': 'Assembly Zone'},
    ];

    _devices = [
      {
        'id': id(31),
        'site_id': id(11),
        'zone_id': id(21),
        'device_code': 'GATEWAY-001',
        'status': 'active',
      },
      {
        'id': id(32),
        'site_id': id(11),
        'zone_id': id(22),
        'device_code': 'GATEWAY-002',
        'status': 'active',
      },
      {
        'id': id(33),
        'site_id': id(12),
        'zone_id': id(23),
        'device_code': 'GATEWAY-003',
        'status': 'maintenance',
      },
    ];

    _sensorTypes = [
      {'id': id(41), 'name': 'Tilt X/Y'},
      {'id': id(42), 'name': 'Temperature'},
    ];

    _sensors = List<Map<String, dynamic>>.generate(12, (index) {
      final item = index + 1;
      final device = _devices[index % _devices.length];
      return {
        'id': id(100 + item),
        'device_id': device['id'],
        'sensor_type_id': id(41),
        'serial_number': 'TILT-2024-${1000 + item}',
        'last_reading': (1 + _random.nextDouble() * 4).toStringAsFixed(2),
      };
    });

    _users = [
      {
        'id': id(201),
        'name': 'Sarah Connor',
        'role': 'operator',
        'email': 'sarah@example.com',
        'created_at': now,
      },
      {
        'id': id(202),
        'name': 'Mike Ryan',
        'role': 'engineer',
        'email': 'mike@example.com',
        'created_at': now,
      },
      {
        'id': id(203),
        'name': 'Admin User',
        'role': 'admin',
        'email': 'admin@example.com',
        'created_at': now,
      },
    ];

    _thresholdProfiles = [
      {
        'id': id(301),
        'name': 'Standard Tilt',
        'description': 'Default tilt thresholds',
      },
      {
        'id': id(302),
        'name': 'High Sensitivity',
        'description': 'Stricter thresholds',
      },
    ];

    _alerts = [
      {
        'id': id(401),
        'sensor_id': _sensors[0]['id'],
        'alert_level': 'warning',
        'message': 'Tilt above warning threshold',
        'triggered_at': now,
        'resolved_at': null,
      },
      {
        'id': id(402),
        'sensor_id': _sensors[2]['id'],
        'alert_level': 'critical',
        'message': 'Critical tilt detected',
        'triggered_at': now,
        'resolved_at': null,
      },
      {
        'id': id(403),
        'sensor_id': _sensors[5]['id'],
        'alert_level': 'warning',
        'message': 'Unstable readings',
        'triggered_at': now.subtract(const Duration(hours: 1)),
        'resolved_at': now,
      },
    ];

    _auditLogs = List<Map<String, dynamic>>.generate(10, (index) {
      final i = index + 1;
      return {
        'id': id(500 + i),
        'timestamp': now.subtract(Duration(hours: i)),
        'user_id': _users[i % _users.length]['id'],
        'action': ['CREATE', 'UPDATE', 'DELETE', 'LOGIN'][i % 4],
        'resource': ['Organization', 'Site', 'Sensor', 'User'][i % 4],
        'ip': '192.168.1.${100 + i}',
      };
    });

    _config = {
      'global_threshold': 3.0,
      'warning_threshold': 2.6,
      'critical_threshold': 4.2,
      'retention_days': 90,
      'alert_notification': true,
      'backup_enabled': true,
      'backup_frequency': 'daily',
      'api_rate_limit': 1000,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = _darkTheme
        ? const ColorScheme.dark(
            primary: Color(0xFF3290DF),
            surface: Color(0xFF1A3148),
            secondary: Color(0xFF8AAAC9),
          )
        : const ColorScheme.light(
            primary: Color(0xFF1F7BCF),
            surface: Colors.white,
            secondary: Color(0xFF4A6B8A),
          );

    final bgColor =
        _darkTheme ? const Color(0xFF0E1B2A) : const Color(0xFFF4F9FF);
    final softColor =
        _darkTheme ? const Color(0xFF203A54) : const Color(0xFFF0F5FD);
    final borderColor =
        _darkTheme ? const Color(0xFF315A7A) : const Color(0xFFD9E6F5);

    return Theme(
      data: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: bgColor,
        useMaterial3: true,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          backgroundColor: _darkTheme ? const Color(0xFF1A3148) : Colors.white,
          child: _buildMenu(),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1600),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _buildTopNav(softColor, borderColor),
                          const SizedBox(height: 16),
                          _buildWelcomeCard(softColor, borderColor),
                          const SizedBox(height: 16),
                          _buildStatsGrid(softColor, borderColor),
                          const SizedBox(height: 16),
                          _buildCurrentView(softColor, borderColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopNav(Color softColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: softColor,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.menu),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.memory, color: Colors.white),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
              children: [
                const TextSpan(text: 'TILT'),
                TextSpan(
                  text: 'ADMIN',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ),
          const Spacer(),
          ToggleButtons(
            borderRadius: BorderRadius.circular(20),
            isSelected: [_darkTheme == false, _darkTheme],
            onPressed: (index) {
              setState(() {
                _darkTheme = index == 1;
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  Icon(Icons.light_mode),
                  SizedBox(width: 4),
                  Text('Light')
                ]),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  Icon(Icons.dark_mode),
                  SizedBox(width: 4),
                  Text('Dark')
                ]),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: const Row(
              children: [
                Text('Admin User'),
                SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.admin_panel_settings, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    Widget menuItem(String label, IconData icon, _AdminView view) {
      final active = _currentView == view;
      return ListTile(
        leading: Icon(icon),
        title: Text(label),
        selected: active,
        onTap: () {
          setState(() {
            _currentView = view;
          });
          Navigator.of(context).pop();
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        const ListTile(
          leading: Icon(Icons.memory),
          title: Text('Admin Panel',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Main', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        menuItem('Dashboard', Icons.show_chart, _AdminView.dashboard),
        menuItem('Users', Icons.people, _AdminView.users),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Organization',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        menuItem('Organizations', Icons.business, _AdminView.organizations),
        menuItem('Sites', Icons.location_on, _AdminView.sites),
        menuItem('Zones', Icons.layers, _AdminView.zones),
        menuItem('Devices', Icons.dns, _AdminView.devices),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Sensors', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        menuItem('Sensors', Icons.memory, _AdminView.sensors),
        menuItem('Alerts', Icons.notifications, _AdminView.alerts),
        menuItem('Thresholds', Icons.tune, _AdminView.thresholds),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('System', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        menuItem('Audit Logs', Icons.history, _AdminView.audit),
        menuItem('Configuration', Icons.settings, _AdminView.config),
      ],
    );
  }

  Widget _buildWelcomeCard(Color softColor, Color borderColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_titleForView(_currentView),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 18),
                const SizedBox(width: 8),
                Text(_badgeForView(_currentView)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Color softColor, Color borderColor) {
    final activeAlerts = _alerts.where((a) => a['resolved_at'] == null).length;

    Widget statCard(String label, String value, IconData icon) {
      return Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: softColor,
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                Text(label),
              ],
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        statCard('Organizations', '${_organizations.length}', Icons.business),
        statCard('Sites', '${_sites.length}', Icons.location_on),
        statCard('Sensors', '${_sensors.length}', Icons.memory),
        statCard('Active Alerts', '$activeAlerts', Icons.notifications_active),
      ],
    );
  }

  Widget _buildCurrentView(Color softColor, Color borderColor) {
    switch (_currentView) {
      case _AdminView.dashboard:
        return _buildDashboard(softColor, borderColor);
      case _AdminView.users:
        return _buildTableSection(
            'users', _users, const ['name', 'email', 'role', 'created_at']);
      case _AdminView.organizations:
        return _buildTableSection('organizations', _organizations,
            const ['name', 'email', 'status', 'created_at']);
      case _AdminView.sites:
        return _buildTableSection('sites', _sites,
            const ['name', 'location', 'organization_id', 'created_at']);
      case _AdminView.zones:
        return _buildTableSection('zones', _zones, const ['name', 'site_id']);
      case _AdminView.devices:
        return _buildTableSection('devices', _devices,
            const ['device_code', 'site_id', 'zone_id', 'status']);
      case _AdminView.sensors:
        return _buildTableSection('sensors', _sensors, const [
          'serial_number',
          'device_id',
          'sensor_type_id',
          'last_reading'
        ]);
      case _AdminView.alerts:
        return _buildTableSection('alerts', _alerts,
            const ['alert_level', 'message', 'triggered_at', 'resolved_at']);
      case _AdminView.thresholds:
        return _buildTableSection('threshold_profiles', _thresholdProfiles,
            const ['name', 'description']);
      case _AdminView.audit:
        return _buildTableSection('audit_logs', _auditLogs,
            const ['timestamp', 'user_id', 'action', 'resource', 'ip']);
      case _AdminView.config:
        return _buildConfigSection(borderColor, softColor);
    }
  }

  Widget _buildDashboard(Color softColor, Color borderColor) {
    final activeAlerts =
        _alerts.where((a) => a['resolved_at'] == null).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final cardWidth = maxWidth < 980 ? maxWidth : (maxWidth - 12) / 2;

        return Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _chartCard(
                    title: 'Real-time Tilt Readings',
                    subtitle: 'Live',
                    icon: Icons.show_chart,
                    borderColor: borderColor,
                    child: const SizedBox(height: 220, child: _FakeLineChart()),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _chartCard(
                    title: 'Sensor Distribution',
                    subtitle: 'By Zone',
                    icon: Icons.pie_chart,
                    borderColor: borderColor,
                    child:
                        const SizedBox(height: 220, child: _FakeDonutChart()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active),
                      SizedBox(width: 8),
                      Text('Recent Active Alerts',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (activeAlerts.isEmpty)
                    const Text('No active alerts')
                  else
                    ...activeAlerts.take(5).map((alert) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: softColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: alert['alert_level'] == 'critical'
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(alert['message'] as String),
                                  Text(
                                      'Sensor ${(alert['sensor_id'] as String).substring(0, 6)}'),
                                ],
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: () {
                                setState(() {
                                  alert['resolved_at'] = DateTime.now();
                                });
                              },
                              child: const Text('Resolve'),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _chartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    required Color borderColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 290),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(subtitle,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTableSection(
    String key,
    List<Map<String, dynamic>> rows,
    List<String> columns,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                key.replaceAll('_', ' '),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Add New for $key')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                ...columns.map((c) => DataColumn(label: Text(c))),
                const DataColumn(label: Text('Actions')),
              ],
              rows: rows.map((row) {
                return DataRow(
                  cells: [
                    ...columns.map(
                        (col) => DataCell(Text(_formatCell(col, row[col])))),
                    DataCell(
                      Row(
                        children: [
                          TextButton(
                              onPressed: () {}, child: const Text('Edit')),
                          TextButton(
                              onPressed: () {}, child: const Text('Delete')),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSection(Color borderColor, Color softColor) {
    Widget tile(String title, List<String> lines, IconData icon) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: softColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            ...lines.map(Text.new),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('System Configuration',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
              const Spacer(),
              FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Configuration')),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 360,
                child: tile(
                  'Thresholds',
                  [
                    'Global: ${_config['global_threshold']}°',
                    'Warning: ${_config['warning_threshold']}°',
                    'Critical: ${_config['critical_threshold']}°',
                  ],
                  Icons.show_chart,
                ),
              ),
              SizedBox(
                width: 360,
                child: tile(
                  'Data Retention',
                  [
                    'Retention Days: ${_config['retention_days']}',
                    'Backup: ${_config['backup_enabled'] ? 'Enabled' : 'Disabled'}',
                    'Frequency: ${_config['backup_frequency']}',
                  ],
                  Icons.storage,
                ),
              ),
              SizedBox(
                width: 360,
                child: tile(
                  'Notifications',
                  [
                    'Alert Notifications: ${_config['alert_notification'] ? 'On' : 'Off'}',
                  ],
                  Icons.notifications,
                ),
              ),
              SizedBox(
                width: 360,
                child: tile(
                  'API',
                  [
                    'Rate Limit: ${_config['api_rate_limit']} req/min',
                  ],
                  Icons.speed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _titleForView(_AdminView view) {
    switch (view) {
      case _AdminView.dashboard:
        return 'Dashboard';
      case _AdminView.users:
        return 'User Management';
      case _AdminView.organizations:
        return 'Organizations';
      case _AdminView.sites:
        return 'Sites';
      case _AdminView.zones:
        return 'Zones';
      case _AdminView.devices:
        return 'Devices';
      case _AdminView.sensors:
        return 'Sensors';
      case _AdminView.alerts:
        return 'Alerts';
      case _AdminView.thresholds:
        return 'Threshold Profiles';
      case _AdminView.audit:
        return 'Audit Logs';
      case _AdminView.config:
        return 'Configuration';
    }
  }

  String _badgeForView(_AdminView view) {
    switch (view) {
      case _AdminView.dashboard:
        return 'System Overview';
      case _AdminView.users:
        return 'Manage System Users';
      case _AdminView.organizations:
        return 'Manage Organizations';
      case _AdminView.sites:
        return 'Manage Sites';
      case _AdminView.zones:
        return 'Manage Zones';
      case _AdminView.devices:
        return 'Manage Devices';
      case _AdminView.sensors:
        return 'Manage Sensors';
      case _AdminView.alerts:
        return 'Manage Alerts';
      case _AdminView.thresholds:
        return 'Manage Thresholds';
      case _AdminView.audit:
        return 'System Audit Trail';
      case _AdminView.config:
        return 'System Settings';
    }
  }

  String _formatCell(String key, dynamic value) {
    if (value == null) {
      return '-';
    }
    if (value is DateTime) {
      return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    }

    if (key == 'organization_id') {
      return _organizations.firstWhere(
        (o) => o['id'] == value,
        orElse: () => {'name': 'N/A'},
      )['name'] as String;
    }
    if (key == 'site_id') {
      return _sites.firstWhere(
        (s) => s['id'] == value,
        orElse: () => {'name': 'N/A'},
      )['name'] as String;
    }
    if (key == 'zone_id') {
      return _zones.firstWhere(
        (z) => z['id'] == value,
        orElse: () => {'name': 'N/A'},
      )['name'] as String;
    }
    if (key == 'device_id') {
      return _devices.firstWhere(
        (d) => d['id'] == value,
        orElse: () => {'device_code': 'N/A'},
      )['device_code'] as String;
    }
    if (key == 'sensor_type_id') {
      return _sensorTypes.firstWhere(
        (s) => s['id'] == value,
        orElse: () => {'name': 'N/A'},
      )['name'] as String;
    }
    if (key == 'user_id') {
      return _users.firstWhere(
        (u) => u['id'] == value,
        orElse: () => {'name': 'N/A'},
      )['name'] as String;
    }

    return '$value';
  }
}

class _FakeLineChart extends StatelessWidget {
  const _FakeLineChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LinePainter(
        line1: Colors.blue,
        line2: Colors.orange,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _FakeDonutChart extends StatelessWidget {
  const _FakeDonutChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.line1, required this.line2});

  final Color line1;
  final Color line2;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (int i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final p1 = Paint()
      ..color = line1
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final p2 = Paint()
      ..color = line2
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path1 = Path()..moveTo(0, size.height * 0.7);
    final path2 = Path()..moveTo(0, size.height * 0.55);

    for (int i = 1; i <= 23; i++) {
      final x = size.width * i / 23;
      path1.lineTo(x, size.height * (0.35 + 0.2 * sin(i / 3)));
      path2.lineTo(x, size.height * (0.45 + 0.2 * cos(i / 4)));
    }

    canvas.drawPath(path1, p1);
    canvas.drawPath(path2, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.35;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const colors = [
      Color(0xFF1F7BCF),
      Color(0xFFE68A2E),
      Color(0xFF27A36A),
      Color(0xFFD64545),
      Color(0xFF9B59B6),
    ];
    const values = [20.0, 16.0, 25.0, 14.0, 25.0];

    double start = -pi / 2;
    final total = values.reduce((a, b) => a + b);

    for (int i = 0; i < values.length; i++) {
      final sweep = 2 * pi * (values[i] / total);
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 34
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
