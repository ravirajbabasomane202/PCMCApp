import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:main_ui/services/api_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    print('FCM Token: $token');

    // Send token to backend
    await ApiService.post('/notifications/register', {'fcm_token': token});

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
    });

    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
  }

  static Future<void> _backgroundHandler(RemoteMessage message) async {
    print('Background message: ${message.notification?.title}');
  }
}
