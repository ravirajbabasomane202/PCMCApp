import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class Constants {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000";
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "http://10.0.2.2:5000"; // Android emulator
        // return "https://pcmcapp.onrender.com"; 
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return "http://localhost:5000";
    }
  }
}
