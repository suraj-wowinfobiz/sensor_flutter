import 'package:flutter/material.dart';

class AnimatedAlertItem extends StatelessWidget {
  final String message;
  final String sensorId;
  final String time;
  final String level;
  final VoidCallback onResolve;

  const AnimatedAlertItem({
    super.key,
    required this.message,
    required this.sensorId,
    required this.time,
    required this.level,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (level) {
      case 'critical':
        color = Colors.red;
        break;
      case 'warning':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(Icons.warning_amber_rounded, color: color)),
        title: Text(message),
        subtitle: Text('Sensor $sensorId • $time'),
        trailing:
            TextButton(onPressed: onResolve, child: const Text('Resolve')),
      ),
    );
  }
}
