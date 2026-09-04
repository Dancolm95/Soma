import 'package:flutter/material.dart';

/// Minimal screen whose only purpose is to prove that the app boots and that
/// build-time environment configuration is wired correctly.
///
/// This is not the final UI; it will be replaced by real features later.
class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key, required this.environmentName});

  final String environmentName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Soma'),
            const SizedBox(height: 8),
            Text('environment: $environmentName'),
          ],
        ),
      ),
    );
  }
}
