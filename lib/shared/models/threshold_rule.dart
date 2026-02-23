import 'package:flutter/material.dart';

enum ThresholdGraphTarget {
  analyticsMain,
  dashboardRealtime,
  dashboardThresholdMonitoring,
}

extension ThresholdGraphTargetLabel on ThresholdGraphTarget {
  String get label {
    switch (this) {
      case ThresholdGraphTarget.analyticsMain:
        return 'Analytics Main Graph';
      case ThresholdGraphTarget.dashboardRealtime:
        return 'Dashboard Realtime Graph';
      case ThresholdGraphTarget.dashboardThresholdMonitoring:
        return 'Dashboard Threshold Monitoring';
    }
  }
}

class ThresholdRule {
  const ThresholdRule({
    required this.id,
    required this.label,
    required this.value,
    required this.sound,
    required this.color,
    required this.graphTargets,
  });

  final String id;
  final String label;
  final double value;
  final String sound;
  final Color color;
  final Set<ThresholdGraphTarget> graphTargets;

  String get key => label
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  ThresholdRule copyWith({
    String? id,
    String? label,
    double? value,
    String? sound,
    Color? color,
    Set<ThresholdGraphTarget>? graphTargets,
  }) {
    return ThresholdRule(
      id: id ?? this.id,
      label: label ?? this.label,
      value: value ?? this.value,
      sound: sound ?? this.sound,
      color: color ?? this.color,
      graphTargets: graphTargets ?? this.graphTargets,
    );
  }
}
