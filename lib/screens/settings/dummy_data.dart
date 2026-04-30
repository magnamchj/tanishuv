import 'package:flutter/material.dart';

class DummyDataGenerator extends StatelessWidget {
  const DummyDataGenerator({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin / Dummy Tools')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // In a real MVP, this would add mocked documents to Firestore
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Firebase Mock Data generation triggered.'))
            );
          },
          child: const Text('Generate Dummy Users & Events'),
        ),
      ),
    );
  }
}
