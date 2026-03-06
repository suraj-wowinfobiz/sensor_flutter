import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dashboard_api.dart';

final userDashboardStatsApiProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await DashboardApi.getStats();
});
