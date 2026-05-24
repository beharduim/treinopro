import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String _releaseApiBaseUrl = 'https://api.treinopro.com';
  static const String _debugApiBaseUrl = 'http://localhost:3000';
  static const String _apiBaseUrlFromDefine = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    final configuredUrl = _apiBaseUrlFromDefine.isNotEmpty
        ? _apiBaseUrlFromDefine
        : (dotenv.env['API_BASE_URL'] ?? defaultApiBaseUrl);
    return _normalizeApiBaseUrl(configuredUrl);
  }

  static String get defaultApiBaseUrl =>
      kDebugMode ? _debugApiBaseUrl : _releaseApiBaseUrl;

  static String get stripePublishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

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
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ [APP_CONFIG] .env não carregado, usando fallback: $defaultApiBaseUrl',
        );
      }
    }
  }
}
