import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/sensor_model.dart';
import '../providers/database_provider.dart';
import '../widgets/animated/data_table.dart';

class SensorsScreen extends StatelessWidget {
  const SensorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, db, child) {
        return AnimatedDataTable(
          title: 'Sensors',
          icon: Icons.sensors,
          columns: const ['Serial', 'Device ID', 'Type ID', 'Last Reading'],
          data: db.sensors
              .map((s) => [
                    s.serialNumber,
                    s.deviceId,
                    s.sensorTypeId,
                    s.lastReading.toStringAsFixed(2)
                  ])
              .toList(),
          onAdd: () => _showSensorDialog(context, db),
          onEdit: (index) =>
              _showSensorDialog(context, db, sensor: db.sensors[index]),
          onDelete: (index) => db.deleteSensor(db.sensors[index].id),
        );
      },
    );
  }

  Future<void> _showSensorDialog(BuildContext context, DatabaseProvider db,
      {SensorModel? sensor}) async {
    final serialCtrl = TextEditingController(text: sensor?.serialNumber ?? '');
    final deviceCtrl = TextEditingController(text: sensor?.deviceId ?? 'dev-1');
    final typeCtrl =
        TextEditingController(text: sensor?.sensorTypeId ?? 'tilt-x');
    final readingCtrl =
        TextEditingController(text: sensor?.lastReading.toString() ?? '0.0');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sensor == null ? 'Add Sensor' : 'Edit Sensor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: serialCtrl,
                decoration: const InputDecoration(labelText: 'Serial Number')),
            TextField(
                controller: deviceCtrl,
                decoration: const InputDecoration(labelText: 'Device ID')),
            TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(labelText: 'Sensor Type ID')),
            TextField(
                controller: readingCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Last Reading')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final reading = double.tryParse(readingCtrl.text.trim()) ?? 0;
              if (sensor == null) {
                await db.addSensor(
                  SensorModel(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    deviceId: deviceCtrl.text.trim(),
                    sensorTypeId: typeCtrl.text.trim(),
                    serialNumber: serialCtrl.text.trim(),
                    installedAt: DateTime.now(),
                    lastReading: reading,
                  ),
                );
              } else {
                await db.updateSensor(
                  sensor.copyWith(
                    deviceId: deviceCtrl.text.trim(),
                    sensorTypeId: typeCtrl.text.trim(),
                    serialNumber: serialCtrl.text.trim(),
                    lastReading: reading,
                  ),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
