import 'package:flutter/foundation.dart';

class ApiConfig {
  // Can be configured at build or run time via:
  // flutter run --dart-define=API_BASE_URL=https://your-api-domain.com/api/v1
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android Emulator loopback default.
        // NOTE FOR PHYSICAL ANDROID DEVICES:
        // Option 1 (USB Debugging): Run `adb reverse tcp:5000 tcp:5000` and pass
        //   --dart-define=API_BASE_URL=http://localhost:5000/api/v1
        // Option 2 (Wi-Fi LAN): Pass your PC's local IP address, e.g.
        //   --dart-define=API_BASE_URL=http://192.168.1.XX:5000/api/v1
        return 'http://10.0.2.2:5000/api/v1';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:5000/api/v1';
    }
  }

  static String get socketUrl {
    return baseUrl.replaceAll('/api/v1', '');
  }
}

