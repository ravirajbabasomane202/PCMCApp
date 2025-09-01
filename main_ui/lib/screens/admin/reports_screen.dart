import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Later connect with backend: GET /admin/reports
    final kpis = {
      "Resolution Rate": "82%",
      "SLA Compliance": "76%",
      "Pending Aging": "5 days avg"
    };

    return Scaffold(
      appBar: AppBar(title: const Text("Reports & Analytics")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: kpis.entries.map((e) => Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(e.value, style: const TextStyle(fontSize: 16)),
            ),
          )).toList(),
        ),
      ),
    );
  }
}
