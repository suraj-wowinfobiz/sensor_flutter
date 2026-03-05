import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';

final userAdminDashboardStatsApiProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return DashboardApi.getStats();
});

final userAdminDashboardOverviewApiProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return DashboardApi.getOverview();
});

final userAdminDashboardRecentAlertsApiProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return DashboardApi.getRecentAlerts();
});
