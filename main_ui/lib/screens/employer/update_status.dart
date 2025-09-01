// lib/screens/employer/update_status.dart
import 'package:flutter/material.dart';

class UpdateStatus extends StatefulWidget {
  const UpdateStatus({super.key});

  @override
  State<UpdateStatus> createState() => _UpdateStatusState();
}

class _UpdateStatusState extends State<UpdateStatus> {
  String status = '';

  void _update() async {
    // POST status
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Status')),
      body: Column(
        children: [
          // Dropdown for status
          ElevatedButton(onPressed: _update, child: const Text('Update')),
        ],
      ),
    );
  }
}