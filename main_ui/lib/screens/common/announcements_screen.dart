import 'package:flutter/material.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Later connect with backend: GET /admin/announcements
    final announcements = [
      {"title": "Emergency Notice", "message": "Water supply disruption in area.", "type": "emergency"},
      {"title": "General Info", "message": "Ward office timings updated.", "type": "general"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Announcements")),
      body: ListView.builder(
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final ann = announcements[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: Icon(
                ann['type'] == "emergency" ? Icons.warning : Icons.info,
                color: ann['type'] == "emergency" ? Colors.red : Colors.blue,
              ),
              title: Text(ann['title']!),
              subtitle: Text(ann['message']!),
            ),
          );
        },
      ),
    );
  }
}
