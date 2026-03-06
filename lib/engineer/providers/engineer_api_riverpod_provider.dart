import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';

final engineerDashboardStatsApiProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return DashboardApi.getStats();
});
