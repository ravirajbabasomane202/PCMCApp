// lib/screens/member_head/assign_grievance.dart
import 'package:flutter/material.dart';

class AssignGrievance extends StatefulWidget {
  const AssignGrievance({super.key});

  @override
  State<AssignGrievance> createState() => _AssignGrievanceState();
}

class _AssignGrievanceState extends State<AssignGrievance> {
  // Form for priority, assign to
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Grievance')),
      body: Form(
        child: Column(
          children: [
            // Dropdowns
            ElevatedButton(onPressed: () {}, child: const Text('Accept and Assign')),
          ],
        ),
      ),
    );
  }
}