import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/alerts_api.dart';
import '../api/analytics_api.dart';
import '../api/audit_logs_api.dart';
import '../api/dashboard_api.dart';
import '../api/reports_api.dart';
import '../models/alert.dart';

final superAdminAlertsApiProvider = FutureProvider<List<Alert>>((ref) async {
  return AlertsApi.getAlerts();
});

final superAdminDashboardStatsApiProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return DashboardApi.getStats();
});

final superAdminDashboardOverviewApiProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return DashboardApi.getOverview();
});

final superAdminDashboardRecentAlertsApiProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return DashboardApi.getRecentAlerts();
});

final superAdminAnalyticsOverviewApiProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return AnalyticsApi.getOverview();
});

final superAdminAnalyticsRecentEventsApiProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return AnalyticsApi.getRecentEvents();
});

final superAdminReportsApiProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ReportsApi.getReports();
});

final superAdminAuditLogsApiProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return AuditLogsApi.getAuditLogs();
});
