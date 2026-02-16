class Config {
  double globalThreshold;
  double warningThreshold;
  double criticalThreshold;
  int retentionDays;
  bool alertNotification;
  bool backupEnabled;
  String backupFrequency;
  int apiRateLimit;

  Config({
    required this.globalThreshold,
    required this.warningThreshold,
    required this.criticalThreshold,
    required this.retentionDays,
    required this.alertNotification,
    required this.backupEnabled,
    required this.backupFrequency,
    required this.apiRateLimit,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      globalThreshold: (json['global_threshold'] as num).toDouble(),
      warningThreshold: (json['warning_threshold'] as num).toDouble(),
      criticalThreshold: (json['critical_threshold'] as num).toDouble(),
      retentionDays: json['retention_days'] as int,
      alertNotification: json['alert_notification'] as bool,
      backupEnabled: json['backup_enabled'] as bool,
      backupFrequency: json['backup_frequency'] as String,
      apiRateLimit: json['api_rate_limit'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'global_threshold': globalThreshold,
      'warning_threshold': warningThreshold,
      'critical_threshold': criticalThreshold,
      'retention_days': retentionDays,
      'alert_notification': alertNotification,
      'backup_enabled': backupEnabled,
      'backup_frequency': backupFrequency,
      'api_rate_limit': apiRateLimit,
    };
  }

  Config copyWith({
    double? globalThreshold,
    double? warningThreshold,
    double? criticalThreshold,
    int? retentionDays,
    bool? alertNotification,
    bool? backupEnabled,
    String? backupFrequency,
    int? apiRateLimit,
  }) {
    return Config(
      globalThreshold: globalThreshold ?? this.globalThreshold,
      warningThreshold: warningThreshold ?? this.warningThreshold,
      criticalThreshold: criticalThreshold ?? this.criticalThreshold,
      retentionDays: retentionDays ?? this.retentionDays,
      alertNotification: alertNotification ?? this.alertNotification,
      backupEnabled: backupEnabled ?? this.backupEnabled,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      apiRateLimit: apiRateLimit ?? this.apiRateLimit,
    );
  }
}
