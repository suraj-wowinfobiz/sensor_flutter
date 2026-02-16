import 'package:flutter/material.dart';

class EngineerPage extends StatelessWidget {
  const EngineerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Engineer Page')),
      body: Center(
        child: Text(
          'Engineer Page',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
