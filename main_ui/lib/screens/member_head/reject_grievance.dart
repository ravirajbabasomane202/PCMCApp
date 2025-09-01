// lib/screens/member_head/reject_grievance.dart
import 'package:flutter/material.dart';

class RejectGrievance extends StatefulWidget {
  const RejectGrievance({super.key});

  @override
  State<RejectGrievance> createState() => _RejectGrievanceState();
}

class _RejectGrievanceState extends State<RejectGrievance> {
  String reason = '';

  void _reject() async {
    // POST reject
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reject Grievance')),
      body: Column(
        children: [
          TextFormField(onChanged: (v) => reason = v, decoration: const InputDecoration(labelText: 'Reason')),
          ElevatedButton(onPressed: _reject, child: const Text('Reject')),
        ],
      ),
    );
  }
}