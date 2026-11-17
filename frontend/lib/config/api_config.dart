import 'package:flutter/foundation.dart';

/// Base URL REST API CodeIgniter 4.
///
/// Bisa di-override saat run:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    // Emulator Android mengakses localhost host lewat 10.0.2.2
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  static const Duration timeout = Duration(seconds: 10);
}
