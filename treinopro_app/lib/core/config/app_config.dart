import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl {
    final configuredUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
    return _normalizeApiBaseUrl(configuredUrl);
  }

  static String get jwtSecret => dotenv.env['JWT_SECRET'] ?? '';
  static String get jwtExpiresIn => dotenv.env['JWT_EXPIRES_IN'] ?? '24h';
  static String get jwtRefreshExpiresIn =>
      dotenv.env['JWT_REFRESH_EXPIRES_IN'] ?? '7d';

  static String _normalizeApiBaseUrl(String url) {
    try {
      if (kIsWeb) {
        return url;
      }

      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      final isLoopback = host == 'localhost' || host == '127.0.0.1';
      final androidLoopbackHost = dotenv.env['ANDROID_LOOPBACK_HOST'];

      // Ajuste opcional para Android (ex.: emulador usa 10.0.2.2).
      if (defaultTargetPlatform == TargetPlatform.android &&
          isLoopback &&
          androidLoopbackHost != null &&
          androidLoopbackHost.isNotEmpty) {
        return uri.replace(host: androidLoopbackHost).toString();
      }
    } catch (_) {
      return url;
    }

    return url;
  }

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }
}
