import '../../super_admin/models/organization.dart';
import '../../super_admin/models/site.dart';
import '../../super_admin/models/threshold_profile.dart';
import '../../super_admin/models/threshold_value.dart';
import '../../super_admin/models/user.dart';
import '../../super_admin/models/zone.dart';
import '../../super_admin/providers/super_admin_backend_provider.dart';
import '../api/organization_api.dart' as org_api;
import '../api/thresholds_api.dart' as thresholds_api;
import '../api/users_api.dart' as users_api;

class VendorBackendProvider extends SuperAdminBackendProvider {
  String _asString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    final parsed = value.toString().trim();
    return parsed.isEmpty ? fallback : parsed;
  }

  DateTime _asDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  double _asDouble(dynamic value, [double fallback = 0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  @override
  Future<void> loadOrganizations() async {
    try {
      final res = await org_api.OrgServiceApi.getAllOrganizations();
      final body = res.body;
      if (body is! List) {
        organizations = [];
      } else {
        organizations = body.map((json) {
          final item = json as Map;
          return Organization(
            id: _asString(item['organizationId']),
            name: _asString(item['name'], 'Organization'),
            email: _asString(item['email']),
            status: _asString(item['status'], 'active').toLowerCase(),
            ownerUserId: _asString(item['ownerUserId']),
            createdAt: _asDate(item['createdAt']),
          );
        }).toList();
      }
    } catch (_) {
      organizations = [];
    }
    notifyListeners();
  }

  @override
  Future<void> loadSites() async {
    try {
      final res = await org_api.OrgServiceApi.getAllSites();
      final body = res.body;
      if (body is! List) {
        sites = [];
      } else {
        final mappedSites = <String, Site>{};
        for (final raw in body) {
          if (raw is! Map) continue;
          final org = raw['organization'];
          final id = _asString(raw['sitesID']);
          if (id.isEmpty) continue;
          mappedSites[id] = Site(
            id: id,
            organizationId: org is Map ? _asString(org['organizationId']) : '',
            name: _asString(raw['name']),
            location: _asString(raw['location']),
            createdAt: _asDate(raw['createdAt']),
          );
        }

        // Some /site responses do not include organization relation.
        // Enrich missing organizationId by querying each organization's sites.
        final hasMissingOrganization = mappedSites.values.any(
          (s) => s.organizationId.trim().isEmpty,
        );
        if (hasMissingOrganization && organizations.isNotEmpty) {
          for (final org in organizations) {
            try {
              final orgSitesRes =
                  await org_api.OrgServiceApi.getOrganizationSites(org.id);
              final orgSitesBody = orgSitesRes.body;
              if (orgSitesBody is! Map) continue;
              final rawSites = orgSitesBody['sites'];
              if (rawSites is! List) continue;
              for (final raw in rawSites) {
                if (raw is! Map) continue;
                final id = _asString(raw['sitesID']);
                if (id.isEmpty) continue;
                final existing = mappedSites[id];
                mappedSites[id] = Site(
                  id: id,
                  organizationId: org.id,
                  name: _asString(raw['name'], existing?.name ?? ''),
                  location:
                      _asString(raw['location'], existing?.location ?? ''),
                  createdAt: _asDate(raw['createdAt'] ?? existing?.createdAt),
                );
              }
            } catch (_) {
              // Keep base sites list even if one org-scoped fetch fails.
            }
          }
        }

        sites = mappedSites.values.toList();
      }
    } catch (_) {
      sites = [];
    }
    notifyListeners();
  }

  @override
  Future<void> loadZones(String siteId) async {
    try {
      final res = await org_api.OrgServiceApi.getZonesBySite(siteId);
      final body = res.body;
      if (body is! List) {
        zones.removeWhere((z) => z.siteId == siteId);
        notifyListeners();
        return;
      }
      final newZones = body.map((json) {
        final item = json as Map;
        final site = item['site'];
        return Zone(
          id: _asString(item['zoneId']),
          siteId: site is Map ? _asString(site['sitesID'], siteId) : siteId,
          name: _asString(item['name']),
        );
      }).toList();
      zones.removeWhere((z) => z.siteId == siteId);
      zones.addAll(newZones);
    } catch (_) {
      zones.removeWhere((z) => z.siteId == siteId);
    }
    notifyListeners();
  }

  @override
  Future<void> loadThresholdProfiles() async {
    try {
      final body = await thresholds_api.ThresholdsApi.getProfiles();
      thresholdProfiles = body.map((json) {
        return ThresholdProfile(
          id: _asString(json['thresholdProfileId'] ?? json['id']),
          name: _asString(json['name'], 'Profile'),
          description: _asString(json['description']),
        );
      }).toList();
    } catch (_) {
      thresholdProfiles = [];
    }
    notifyListeners();
  }

  @override
  Future<void> loadThresholdValues() async {
    try {
      final body = await thresholds_api.ThresholdsApi.getThresholds();
      thresholdValues = body.map((json) {
        return ThresholdValue(
          id: _asString(json['thresholdId'] ?? json['id']),
          sensorParameterId: _asString(
            json['sensorParameterId'] ??
                json['sensorParamterId'] ??
                json['sensor_parameter_id'],
          ),
          thresholdProfileId: _asString(
            json['thresholdProfileId'] ?? json['threshold_profile_id'],
          ),
          minThreshold:
              _asDouble(json['minThresholdValue'] ?? json['min_threshold']),
          maxThreshold:
              _asDouble(json['maxThresholdValue'] ?? json['max_threshold']),
          warningLevel: _asDouble(
            json['warningLevel'] ??
                json['warrningLevel'] ??
                json['warning_level'],
          ),
          criticalLevel:
              _asDouble(json['criticalLevel'] ?? json['critical_level']),
        );
      }).toList();
    } catch (_) {
      thresholdValues = [];
    }
    notifyListeners();
  }

  @override
  Future<void> loadUsers() async {
    try {
      final body = await users_api.UsersApi.getUsers();
      users = body.map((json) {
        return User(
          id: _asString(json['id'] ?? json['userId']),
          name: _asString(json['name'], 'User'),
          role: _asString(json['role'], 'user').toLowerCase(),
          email: _asString(json['email']),
          createdAt: _asDate(json['createdAt'] ?? json['created_at']),
          updatedAt: _asDate(json['updatedAt'] ?? json['updated_at']),
        );
      }).toList();
    } catch (_) {
      users = [];
    }
    notifyListeners();
  }

  @override
  Future<void> create(String view, Map<String, dynamic> data) async {
    switch (view) {
      case 'organizations':
        await org_api.OrgServiceApi.createOrganization(
          data['name'] as String,
          data['email'] as String,
        );
        await loadOrganizations();
        return;
      case 'sites':
        await org_api.OrgServiceApi.createSiteForOrganization(
          data['organization_id'] as String,
          data['name'] as String,
          data['location'] as String,
        );
        await loadSites();
        return;
      case 'zones':
        final siteId = data['site_id'] as String;
        await org_api.OrgServiceApi.createZone(
          siteId,
          data['name'] as String,
        );
        await loadZones(siteId);
        return;
      case 'thresholds':
        await thresholds_api.ThresholdsApi.createProfile(
          name: data['name'] as String,
          description: data['description'] as String,
        );
        await loadThresholdProfiles();
        return;
      case 'threshold_values':
        await thresholds_api.ThresholdsApi.createThreshold(
          minThresholdValue: _asDouble(data['minThresholdValue']),
          sensorParameterId:
              _asString(data['sensorParameterId'] ?? data['sensorParamterId']),
          thresholdProfileId: _asString(data['thresholdProfileId']),
          maxThresholdValue: _asDouble(data['maxThresholdValue']),
          warningLevel:
              _asDouble(data['warningLevel'] ?? data['warrningLevel']),
          criticalLevel: _asDouble(data['criticalLevel']),
          warrningLevel: _asDouble(data['warrningLevel']),
          sensorParamterId: _asString(data['sensorParamterId']),
        );
        await loadThresholdValues();
        return;
      case 'users':
        final role = _asString(data['role'], 'user');
        final organizationId =
            _asString(data['organization_id'] ?? data['organizationId']);
        final maxUsersAllowed = int.tryParse(
          _asString(data['maxUsersAllowed'] ?? data['max_users_allowed'], '20'),
        );
        await users_api.UsersApi.createUser(
          name: _asString(data['name']),
          email: _asString(data['email']),
          role: role,
          organizationId: organizationId,
          password: _asString(data['password'], 'Temp@12345'),
          maxUsersAllowed: maxUsersAllowed,
        );
        await loadUsers();
        return;
      default:
        await super.create(view, data);
    }
  }

  @override
  Future<void> update(String view, String id, Map<String, dynamic> data) async {
    switch (view) {
      case 'organizations':
        await org_api.OrgServiceApi.updateOrganization(
          id,
          data['name'] as String,
          data['email'] as String,
        );
        await loadOrganizations();
        return;
      case 'sites':
        await org_api.OrgServiceApi.updateSite(
          id,
          data['name'] as String,
          data['location'] as String,
          orgId: data['organization_id'] as String,
        );
        await loadSites();
        return;
      case 'zones':
        await org_api.OrgServiceApi.updateZone(
          id,
          data['name'] as String,
          siteId: data['site_id'] as String,
        );
        await loadZones(data['site_id'] as String);
        return;
      case 'thresholds':
        await thresholds_api.ThresholdsApi.updateProfile(
          id: id,
          name: data['name'] as String,
          description: data['description'] as String,
        );
        await loadThresholdProfiles();
        return;
      case 'users':
        await users_api.UsersApi.updateUser(
          id: id,
          name: _asString(data['name']),
          email: _asString(data['email']),
          role: _asString(data['role'], 'user'),
          password: _asString(data['password']),
        );
        await loadUsers();
        return;
      default:
        await super.update(view, id, data);
    }
  }

  @override
  Future<void> delete(String view, String id) async {
    switch (view) {
      case 'organizations':
        await org_api.OrgServiceApi.deleteOrganization(id);
        await loadOrganizations();
        await loadSites();
        return;
      case 'sites':
        await org_api.OrgServiceApi.deleteSite(id);
        await loadSites();
        zones.removeWhere((z) => z.siteId == id);
        notifyListeners();
        return;
      case 'zones':
        await org_api.OrgServiceApi.deleteZone(id);
        zones.removeWhere((item) => item.id == id);
        devices.removeWhere((d) => d.zoneId == id);
        notifyListeners();
        return;
      case 'thresholds':
        await thresholds_api.ThresholdsApi.deleteProfile(id);
        await loadThresholdProfiles();
        return;
      case 'users':
        await users_api.UsersApi.deleteUser(id);
        await loadUsers();
        return;
      default:
        await super.delete(view, id);
    }
  }
}
