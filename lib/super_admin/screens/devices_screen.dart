import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'dart:convert';

import '../api/device_api.dart';
import '../models/device.dart';
import '../providers/super_admin_backend_provider.dart';
import '../providers/super_admin_riverpod_provider.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  bool _showFilters = false;
  bool _isListView = false;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _webhookFilter = 'all';
  String _organizationFilter = 'all';
  String _siteFilter = 'all';
  String _zoneFilter = 'all';
  String _locationFilter = 'all';
  int _refreshKey = 0;

  String _isoUtcNow() => DateTime.now().toUtc().toIso8601String();

  bool _isValidIsoUtc(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    // Expected shape: 2026-02-28T06:15:10.092Z
    final isoUtcPattern =
        RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$');
    if (!isoUtcPattern.hasMatch(trimmed)) return false;
    return DateTime.tryParse(trimmed) != null;
  }

  Future<void> _showErrorDialog(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Something went wrong'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text('Are you sure you want to delete this device?'),
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

  String _asString(dynamic value, [String fallback = '']) {
    final parsed = value?.toString().trim() ?? '';
    return parsed.isEmpty ? fallback : parsed;
  }

  Map<String, dynamic> _normalizeDeviceResponse(Map<String, dynamic> source) {
    final nested = source['data'];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return nested.cast<String, dynamic>();
    if (nested is String && nested.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(nested);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {
        // Fallback to top-level payload.
      }
    }
    return source;
  }

  @override
  void initState() {
    super.initState();
    // Don't invalidate in initState - let provider load naturally
  }

  Future<void> _showDeviceModal({Device? device}) async {
    final db =
        provider.Provider.of<SuperAdminBackendProvider>(context, listen: false);
    await db.loadOrganizations();
    await db.loadSites();
    if (!mounted) return;

    final isLight = Theme.of(context).brightness == Brightness.light;
    final subColor =
        isLight ? const Color(0xFF5A6F7D) : const Color(0xFFAEC4D7);
    final defaultOrganizationId =
        db.organizations.isNotEmpty ? db.organizations.first.id : '';

    // Create controllers
    final serialNumberCtrl = TextEditingController();
    final firmwareVersionCtrl = TextEditingController();
    final macAddressCtrl = TextEditingController();
    final ipUrlCtrl = TextEditingController();
    final channelsCountCtrl = TextEditingController();
    final webhookUrlCtrl = TextEditingController();
    final latitudeCtrl = TextEditingController();
    final longitudeCtrl = TextEditingController();
    final lastHeartBeatCtrl = TextEditingController();

    // Local variables for dialog state
    String editingId = '';
    String organizationId = '';
    String siteId = '';
    String zoneId = '';

    if (device != null) {
      editingId = device.id;
      final fetched = await DeviceApi.getDeviceById(device.id);
      if (!mounted) return;
      final details = _normalizeDeviceResponse(fetched);

      // Update controllers with API data
      organizationId = _asString(details['organizationId']);
      siteId = _asString(details['siteId'], device.siteId);
      zoneId = _asString(details['zoneId'], device.zoneId);
      serialNumberCtrl.text = _asString(details['serialNumber']);
      firmwareVersionCtrl.text = _asString(details['firmwareVersion']);
      macAddressCtrl.text = _asString(details['macAddress']);
      ipUrlCtrl.text = _asString(details['ipAddress']);
      channelsCountCtrl.text = _asString(details['numberOfChannels'], '0');
      webhookUrlCtrl.text = _asString(details['webHookUrl']);
      latitudeCtrl.text = _asString(details['lat']);
      longitudeCtrl.text = _asString(details['log']);
      lastHeartBeatCtrl.text = _asString(details['lastHeartBeat']);

      if (organizationId.isEmpty) {
        organizationId = db.sites
                .where((s) => s.id == siteId)
                .map((s) => s.organizationId)
                .firstOrNull ??
            defaultOrganizationId;
      }
      if (siteId.isNotEmpty &&
          db.zones.where((z) => z.siteId == siteId).isEmpty) {
        await db.loadZones(siteId);
      }
      if (lastHeartBeatCtrl.text.isEmpty) {
        lastHeartBeatCtrl.text = _isoUtcNow();
      }
    } else {
      lastHeartBeatCtrl.text = _isoUtcNow();
    }
    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Device Form',
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (context, animation, secondaryAnimation) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final isDialogLight = theme.brightness == Brightness.light;
          final cornerRadius = BorderRadius.circular(22);
          final organizationSites = db.sites
              .where((s) => s.organizationId == organizationId)
              .toList();
          final siteZones = db.zones.where((z) => z.siteId == siteId).toList();
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: cornerRadius,
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
                                  editingId.isEmpty
                                      ? 'Add New Device'
                                      : 'Edit Device',
                                  style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Configure device parameters and network settings',
                                  style:
                                      TextStyle(fontSize: 14, color: subColor),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _dialogTextFieldWithController(
                        label: 'Last Heartbeat (ISO-8601)',
                        controller: lastHeartBeatCtrl,
                      ),
                      const SizedBox(height: 14),
                      _dialogTextFieldWithController(
                        label: 'Serial Number',
                        controller: serialNumberCtrl,
                      ),
                      const SizedBox(height: 12),
                      _dialogTextFieldWithController(
                        label: 'Firmware Version',
                        controller: firmwareVersionCtrl,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _dialogTextFieldWithController(
                              label: 'MAC Address',
                              controller: macAddressCtrl,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _dialogTextFieldWithController(
                              label: 'IP Address / URL',
                              controller: ipUrlCtrl,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _dialogTextFieldWithController(
                        label: 'Number of Channels',
                        controller: channelsCountCtrl,
                      ),
                      const SizedBox(height: 12),
                      _dialogTextFieldWithController(
                        label: 'Webhook URL',
                        controller: webhookUrlCtrl,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _dialogDropdown(
                              label: 'Organization *',
                              value: organizationId.isEmpty
                                  ? null
                                  : organizationId,
                              hint: 'Select organization',
                              items: db.organizations
                                  .map((org) => DropdownMenuItem<String>(
                                        value: org.id,
                                        child: Text(org.name),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  organizationId = value ?? '';
                                  siteId = '';
                                  zoneId = '';
                                });
                              },
                            ),
                          ),
                          if (organizationId.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dialogDropdown(
                                label: 'Site *',
                                value: siteId.isEmpty ? null : siteId,
                                hint: 'Select site',
                                items: organizationSites
                                    .map((site) => DropdownMenuItem<String>(
                                          value: site.id,
                                          child: Text(site.name),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    siteId = value ?? '';
                                    zoneId = '';
                                  });
                                  if (siteId.isEmpty) return;
                                  db.loadZones(siteId).then((_) {
                                    if (!mounted) return;
                                    setDialogState(() {});
                                  });
                                },
                              ),
                            ),
                          ],
                          if (siteId.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dialogDropdown(
                                label: 'Zone *',
                                value: zoneId.isEmpty ? null : zoneId,
                                hint: 'Select zone',
                                items: siteZones
                                    .map((zone) => DropdownMenuItem<String>(
                                          value: zone.id,
                                          child: Text(zone.name),
                                        ))
                                    .toList(),
                                onChanged: (value) =>
                                    setDialogState(() => zoneId = value ?? ''),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 560;
                          final title = Text(
                            'GPS Coordinates',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                          final action = OutlinedButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                latitudeCtrl.text = '37.7749';
                                longitudeCtrl.text = '-122.4194';
                              });
                            },
                            icon: const Icon(Icons.my_location, size: 16),
                            label: const Text(
                              'Get Location',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                title,
                                const SizedBox(height: 8),
                                action,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: title),
                              const SizedBox(width: 10),
                              action,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _dialogTextFieldWithController(
                              label: 'Latitude',
                              controller: latitudeCtrl,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _dialogTextFieldWithController(
                              label: 'Longitude',
                              controller: longitudeCtrl,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final backend = provider.Provider.of<
                                    SuperAdminBackendProvider>(
                                  context,
                                  listen: false,
                                );
                                const status = 'active';
                                if (organizationId.isEmpty ||
                                    siteId.isEmpty ||
                                    zoneId.isEmpty) {
                                  if (context.mounted) {
                                    _showErrorDialog(
                                      context,
                                      'Select organization, site, and zone',
                                    );
                                  }
                                  return;
                                }
                                if (serialNumberCtrl.text.trim().isEmpty ||
                                    firmwareVersionCtrl.text.trim().isEmpty ||
                                    macAddressCtrl.text.trim().isEmpty ||
                                    ipUrlCtrl.text.trim().isEmpty ||
                                    channelsCountCtrl.text.trim().isEmpty ||
                                    webhookUrlCtrl.text.trim().isEmpty ||
                                    latitudeCtrl.text.trim().isEmpty ||
                                    longitudeCtrl.text.trim().isEmpty ||
                                    lastHeartBeatCtrl.text.trim().isEmpty) {
                                  if (context.mounted) {
                                    _showErrorDialog(
                                      context,
                                      'Fill all device fields before saving',
                                    );
                                  }
                                  return;
                                }
                                if (int.tryParse(
                                            channelsCountCtrl.text.trim()) ==
                                        null ||
                                    double.tryParse(latitudeCtrl.text.trim()) ==
                                        null ||
                                    double.tryParse(
                                            longitudeCtrl.text.trim()) ==
                                        null) {
                                  if (context.mounted) {
                                    _showErrorDialog(
                                      context,
                                      'Channels must be integer, latitude/longitude must be valid numbers',
                                    );
                                  }
                                  return;
                                }
                                if (!_isValidIsoUtc(lastHeartBeatCtrl.text)) {
                                  if (context.mounted) {
                                    _showErrorDialog(
                                      context,
                                      'Last Heartbeat must be ISO UTC format like 2026-02-28T06:15:10.092Z',
                                    );
                                  }
                                  return;
                                }
                                try {
                                  if (editingId.isEmpty) {
                                    await backend.create('devices', {
                                      'serial_number':
                                          serialNumberCtrl.text.trim(),
                                      'firmware_version':
                                          firmwareVersionCtrl.text.trim(),
                                      'organization_id': organizationId,
                                      'site_id': siteId,
                                      'zone_id': zoneId,
                                      'mac_address': macAddressCtrl.text.trim(),
                                      'ip_address': ipUrlCtrl.text.trim(),
                                      'number_of_channels':
                                          channelsCountCtrl.text.trim(),
                                      'web_hook_url':
                                          webhookUrlCtrl.text.trim(),
                                      'lat': latitudeCtrl.text.trim(),
                                      'log': longitudeCtrl.text.trim(),
                                      'last_heart_beat':
                                          lastHeartBeatCtrl.text.trim(),
                                      'status': status,
                                    });
                                  } else {
                                    await backend.update(
                                      'devices',
                                      editingId,
                                      {
                                        'serial_number':
                                            serialNumberCtrl.text.trim(),
                                        'firmware_version':
                                            firmwareVersionCtrl.text.trim(),
                                        'organization_id': organizationId,
                                        'site_id': siteId,
                                        'zone_id': zoneId,
                                        'mac_address':
                                            macAddressCtrl.text.trim(),
                                        'ip_address': ipUrlCtrl.text.trim(),
                                        'number_of_channels':
                                            channelsCountCtrl.text.trim(),
                                        'web_hook_url':
                                            webhookUrlCtrl.text.trim(),
                                        'lat': latitudeCtrl.text.trim(),
                                        'log': longitudeCtrl.text.trim(),
                                        'last_heart_beat':
                                            lastHeartBeatCtrl.text.trim(),
                                        'status': status,
                                      },
                                    );
                                  }
                                  setState(() => _refreshKey++);
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e) {
                                  if (context.mounted) {
                                    _showErrorDialog(
                                      context,
                                      'Failed to save device: $e',
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                editingId.isEmpty
                                    ? 'Add Device'
                                    : 'Save Device',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  Widget _dialogTextFieldWithController({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFF7FAFC)
                : const Color(0xFF1A3347),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialogTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    final controller = TextEditingController(text: value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFF7FAFC)
                : const Color(0xFF1A3347),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialogDropdown({
    required String label,
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          iconSize: 18,
          style: const TextStyle(fontSize: 12.5),
          hint: Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5),
          ),
          selectedItemBuilder: (context) => items
              .map(
                (item) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _dropdownItemLabel(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              )
              .toList(),
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFF7FAFC)
                : const Color(0xFF1A3347),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _dropdownItemLabel(DropdownMenuItem<String> item) {
    final child = item.child;
    if (child is Text) return child.data ?? (item.value ?? '');
    return item.value ?? '';
  }

  String _date(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _togglePower(SuperAdminBackendProvider db, Device device) async {
    final next = device.status == 'active' ? 'inactive' : 'active';
    final organizationId = db.sites
            .where((s) => s.id == device.siteId)
            .map((s) => s.organizationId)
            .firstOrNull ??
        '';
    await db.update('devices', device.id, {
      'device_code': device.deviceCode,
      'serial_number': device.serialNumber,
      'firmware_version': device.firmwareVersion,
      'organization_id': organizationId,
      'site_id': device.siteId,
      'zone_id': device.zoneId,
      'mac_address': device.macAddress,
      'ip_address': device.ipAddress,
      'number_of_channels': device.numberOfChannels.toString(),
      'web_hook_url': device.webHookUrl,
      'lat': device.lat.toString(),
      'log': device.log.toString(),
      'last_heart_beat': DateTime.now().toUtc().toIso8601String(),
      'status': next,
    });
  }

  bool _matchesFilters(SuperAdminBackendProvider db, Device device) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isNotEmpty) {
      final matchesQuery = device.deviceCode.toLowerCase().contains(query) ||
          device.serialNumber.toLowerCase().contains(query) ||
          device.macAddress.toLowerCase().contains(query) ||
          device.ipAddress.toLowerCase().contains(query);
      if (!matchesQuery) return false;
    }

    if (_statusFilter != 'all' && device.status != _statusFilter) {
      return false;
    }

    if (_webhookFilter != 'all') {
      final hasWebhook = device.webHookUrl.isNotEmpty;
      if (_webhookFilter == 'configured' && !hasWebhook) return false;
      if (_webhookFilter == 'not_configured' && hasWebhook) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesProvider(_refreshKey));

    return devicesAsync.when(
      data: (_) => _buildContent(context),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading devices: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(devicesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return provider.Consumer<SuperAdminBackendProvider>(
      builder: (context, db, child) {
        final allDevices = db.devices;
        final devices =
            allDevices.where((d) => _matchesFilters(db, d)).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              if (_showFilters) ...[
                const SizedBox(height: 18),
                _buildFiltersPanel(context, devices.length, allDevices.length),
              ],
              const SizedBox(height: 18),
              _isListView
                  ? _buildList(context, db, devices)
                  : _buildGrid(context, db, devices),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 12,
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Management',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF0f202d)
                    : const Color(0xFFd4e4ef),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Configure and monitor sensor devices',
              style: TextStyle(
                fontSize: 15,
                color:
                    isLight ? const Color(0xFF4e6473) : const Color(0xFF9db7d2),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _headerButton(
              label: 'Filters',
              icon: Icons.filter_list,
              onTap: () => setState(() => _showFilters = !_showFilters),
            ),
            _headerButton(
              label: _isListView ? 'Cards' : 'List',
              icon: _isListView
                  ? Icons.grid_view_rounded
                  : Icons.view_list_rounded,
              onTap: () => setState(() => _isListView = !_isListView),
            ),
            _headerButton(
              label: 'Export',
              icon: Icons.upload_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export started')),
                );
              },
            ),
            _headerButton(
              label: 'Add',
              icon: Icons.add,
              primary: true,
              onTap: () => _showDeviceModal(),
            ),
          ],
        ),
      ],
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
                size: 19,
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

  Widget _buildFiltersPanel(
      BuildContext context, int filteredCount, int totalCount) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Devices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color:
                  isLight ? const Color(0xFF243946) : const Color(0xFFD7E8F6),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: 290,
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: _filterFieldDecoration(
                    label: 'Search',
                    hint: 'Device ID, Serial, MAC, IP...',
                    icon: Icons.search,
                  ),
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: _filterFieldDecoration(label: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                        value: 'inactive', child: Text('Inactive')),
                    DropdownMenuItem(
                        value: 'maintenance', child: Text('Maintenance')),
                    DropdownMenuItem(value: 'retired', child: Text('Retired')),
                  ],
                  onChanged: (value) =>
                      setState(() => _statusFilter = value ?? 'all'),
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  value: _webhookFilter,
                  decoration: _filterFieldDecoration(label: 'Webhook'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(
                        value: 'configured', child: Text('Configured')),
                    DropdownMenuItem(
                        value: 'not_configured', child: Text('Not Configured')),
                  ],
                  onChanged: (value) =>
                      setState(() => _webhookFilter = value ?? 'all'),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFe6eff3)
                      : const Color(0xFF253F52),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Showing $filteredCount of $totalCount devices',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isLight
                        ? const Color(0xFF324956)
                        : const Color(0xFFD7E8F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          const SizedBox(height: 12),
          Text(
            'LOCATION HIERARCHY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color:
                  isLight ? const Color(0xFF60717c) : const Color(0xFFBBD0E0),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _hierarchyDropdown(
                label: 'Organization',
                value: _organizationFilter,
                onChanged: (value) =>
                    setState(() => _organizationFilter = value ?? 'all'),
              ),
              _hierarchyDropdown(
                label: 'Site',
                value: _siteFilter,
                onChanged: (value) =>
                    setState(() => _siteFilter = value ?? 'all'),
              ),
              _hierarchyDropdown(
                label: 'Zone',
                value: _zoneFilter,
                onChanged: (value) =>
                    setState(() => _zoneFilter = value ?? 'all'),
              ),
              _hierarchyDropdown(
                label: 'Location',
                value: _locationFilter,
                onChanged: (value) =>
                    setState(() => _locationFilter = value ?? 'all'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hierarchyDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _filterFieldDecoration(label: label),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('All')),
        ],
        onChanged: onChanged,
      ),
    );
  }

  InputDecoration _filterFieldDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      isDense: true,
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFF4F8FA)
          : const Color(0xFF1E3A52),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.4,
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, SuperAdminBackendProvider db,
      List<Device> devices) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1100
            ? 2
            : width >= 700
                ? 2
                : 1;
        final ratio = width >= 1300
            ? 1.65
            : width >= 1000
                ? 1.4
                : width >= 700
                    ? 1.1
                    : 0.95;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: devices.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: ratio,
          ),
          itemBuilder: (context, index) {
            final device = devices[index];
            final siteName = db.sites
                .where((s) => s.id == device.siteId)
                .map((s) => s.name)
                .firstOrNull;
            final zoneName = db.zones
                .where((z) => z.id == device.zoneId)
                .map((z) => z.name)
                .firstOrNull;
            final channels = device.numberOfChannels > 0
                ? device.numberOfChannels
                : db.sensors.where((s) => s.deviceId == device.id).length;
            final location = siteName ?? 'Location not set';

            return _DeviceCard(
              title: device.deviceCode,
              serial: device.serialNumber,
              status: device.status,
              mac: device.macAddress,
              ip: device.ipAddress,
              channels: channels,
              lastSeen: device.lastHeartBeat.isNotEmpty
                  ? device.lastHeartBeat
                  : _date(device.installedAt),
              location: location,
              zone: zoneName ?? 'Unknown',
              onEdit: () => _showDeviceModal(device: device),
              onPower: () => _togglePower(db, device),
              onDelete: () async {
                final confirm = await _confirmDelete(context);
                if (!confirm || !context.mounted) return;
                try {
                  await db.delete('devices', device.id);
                  setState(() => _refreshKey++);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete device: $e')),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildList(BuildContext context, SuperAdminBackendProvider db,
      List<Device> devices) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: devices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final device = devices[index];
        final siteName = db.sites
            .where((s) => s.id == device.siteId)
            .map((s) => s.name)
            .firstOrNull;
        final zoneName = db.zones
            .where((z) => z.id == device.zoneId)
            .map((z) => z.name)
            .firstOrNull;
        final channels = device.numberOfChannels > 0
            ? device.numberOfChannels
            : db.sensors.where((s) => s.deviceId == device.id).length;
        final location = siteName ?? 'Location not set';
        final statusColor = device.status == 'active'
            ? const Color(0xFF0ca15f)
            : const Color(0xFF8397a3);
        final lastSeen = device.lastHeartBeat.isNotEmpty
            ? device.lastHeartBeat
            : _date(device.installedAt);
        final metaLine =
            '${device.macAddress} • ${device.ipAddress} • $channels • $lastSeen • $location • ${zoneName ?? 'Unknown'}';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.memory,
                      size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${device.deviceCode} • ${device.serialNumber}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFF152733)
                            : const Color(0xFFD7E8F6),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      device.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                metaLine,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF4a6170)
                      : const Color(0xFFBBD0E0),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showDeviceModal(device: device),
                    icon: const Icon(Icons.edit_outlined),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () => _togglePower(db, device),
                    icon: const Icon(Icons.power_settings_new),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () async {
                      final confirm = await _confirmDelete(context);
                      if (!confirm || !context.mounted) return;
                      try {
                        await db.delete('devices', device.id);
                        setState(() => _refreshKey++);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete device: $e'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final String title;
  final String serial;
  final String status;
  final String mac;
  final String ip;
  final int channels;
  final String lastSeen;
  final String location;
  final String zone;
  final VoidCallback onEdit;
  final VoidCallback onPower;
  final VoidCallback onDelete;

  const _DeviceCard({
    required this.title,
    required this.serial,
    required this.status,
    required this.mac,
    required this.ip,
    required this.channels,
    required this.lastSeen,
    required this.location,
    required this.zone,
    required this.onEdit,
    required this.onPower,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isActive = status == 'active';
    final isOffline = status == 'inactive' || status == 'retired';
    final statusColor =
        isActive ? const Color(0xFF0ca15f) : const Color(0xFF8397a3);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFdbe7ed)
                      : const Color(0xFF2B4659),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.memory,
                    color: Theme.of(context).colorScheme.primary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isLight
                            ? const Color(0xFF152733)
                            : const Color(0xFFD7E8F6),
                      ),
                    ),
                    Text(
                      serial,
                      style: TextStyle(
                        fontSize: 14,
                        color: isLight
                            ? const Color(0xFF60717c)
                            : const Color(0xFFBBD0E0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _meta(context, 'MAC Address', mac)),
              const SizedBox(width: 10),
              Expanded(child: _meta(context, 'IP Address', ip)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _meta(context, 'Channels', '$channels')),
              const SizedBox(width: 10),
              Expanded(child: _meta(context, 'Last Seen', lastSeen)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isLight ? const Color(0xFFe9f0f4) : const Color(0xFF253F52),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isLight
                          ? const Color(0xFF2c404d)
                          : const Color(0xFFD7E8F6),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi,
                      size: 18,
                      color: isOffline ? Colors.grey : const Color(0xFF0ca15f)),
                  const SizedBox(width: 6),
                  Text(
                    isOffline ? 'Disconnected' : 'WiFi Connected',
                    style: TextStyle(
                      fontSize: 13,
                      color: isOffline
                          ? const Color(0xFF7f8f98)
                          : const Color(0xFF0ca15f),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFe8edf1)
                      : const Color(0xFF253F52),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Text(
                  zone,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isLight
                        ? const Color(0xFF243946)
                        : const Color(0xFFD7E8F6),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _iconButton(context, icon: Icons.edit_outlined, onTap: onEdit),
              const SizedBox(width: 8),
              _iconButton(context,
                  icon: Icons.power_settings_new, onTap: onPower),
              const SizedBox(width: 8),
              _iconButton(
                context,
                icon: Icons.delete_outline,
                onTap: onDelete,
                iconColor: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(BuildContext context, String label, String value) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isLight ? const Color(0xFF60717c) : const Color(0xFFBBD0E0),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            color: isLight ? const Color(0xFF152733) : const Color(0xFFD7E8F6),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _iconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF2f4654),
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFe6eff3) : const Color(0xFF243E52),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor == const Color(0xFF2f4654) && !isLight
              ? const Color(0xFFD7E8F6)
              : iconColor,
        ),
      ),
    );
  }
}
