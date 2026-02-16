import 'package:equatable/equatable.dart';

import '../../domain/repositories/database_repository.dart';

class GetDashboardStats {
  final DatabaseRepository repository;

  GetDashboardStats(this.repository);

  Future<DashboardStats> call() async {
    final orgs = await repository.getOrganizations();
    final sensors = await repository.getSensors();
    final alerts = await repository.getActiveAlerts();
    return DashboardStats(
      organizationsCount: orgs.length,
      sensorsCount: sensors.length,
      activeAlertsCount: alerts.length,
      sitesCount: orgs.length * 2,
    );
  }
}

class DashboardStats extends Equatable {
  final int organizationsCount;
  final int sensorsCount;
  final int activeAlertsCount;
  final int sitesCount;

  const DashboardStats({
    required this.organizationsCount,
    required this.sensorsCount,
    required this.activeAlertsCount,
    required this.sitesCount,
  });

  @override
  List<Object?> get props =>
      [organizationsCount, sensorsCount, activeAlertsCount, sitesCount];
}
