import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Later connect with backend: GET /notifications
    final notifications = [
      {
        "title": "Grievance Update", 
        "body": "Your complaint #123 resolved.", 
        "time": "2 hours ago",
        "type": "success"
      },
      {
        "title": "Reminder", 
        "body": "Submit feedback for grievance #101.", 
        "time": "1 day ago",
        "type": "info"
      },
      {
        "title": "New Message", 
        "body": "You have a new message from support team.", 
        "time": "3 days ago",
        "type": "message"
      },
      {
        "title": "System Update", 
        "body": "New features added to the app. Update now!", 
        "time": "1 week ago",
        "type": "update"
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFf8fbff),
      appBar: AppBar(
        title: const Text(
          "Notifications", // This should be localized, e.g., localizations.notifications
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFF8FBFF),
        elevation: 0,
        foregroundColor: Colors.blue,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No notifications yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We'll notify you when something arrives",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final type = notif['type'] as String;
                
                // Different icons based on notification type
                IconData icon;
                Color iconColor;
                
                switch (type) {
                  case "success":
                    icon = Icons.check_circle_outline;
                    iconColor = Colors.green;
                    break;
                  case "info":
                    icon = Icons.info_outline;
                    iconColor = Colors.blue;
                    break;
                  case "message":
                    icon = Icons.email_outlined;
                    iconColor = Colors.purple;
                    break;
                  case "update":
                    icon = Icons.system_update_outlined;
                    iconColor = Colors.orange;
                    break;
                  default:
                    icon = Icons.notifications_outlined;
                    iconColor = Colors.blue;
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Card(
                    color: const Color(0xFFecf2fe),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: iconColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notif['title']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif['body']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  notif['time']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}