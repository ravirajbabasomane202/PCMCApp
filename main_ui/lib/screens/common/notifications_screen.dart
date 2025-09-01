import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Later connect with backend: GET /notifications
    final notifications = [
      {"title": "Grievance Update", "body": "Your complaint #123 resolved."},
      {"title": "Reminder", "body": "Submit feedback for grievance #101."},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(notif['title']!),
              subtitle: Text(notif['body']!),
            ),
          );
        },
      ),
    );
  }
}
