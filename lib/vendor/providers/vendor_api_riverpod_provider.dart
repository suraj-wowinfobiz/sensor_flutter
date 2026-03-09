import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';

final vendorDashboardStatsApiProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return DashboardApi.getStats();
});

final vendorDashboardOverviewApiProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return DashboardApi.getOverview();
});

final vendorDashboardRecentAlertsApiProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return DashboardApi.getRecentAlerts();
});
