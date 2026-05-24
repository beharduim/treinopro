import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_service.dart';
import 'stripe_connect_appearance.dart';

class StripeConnectOnboardingService {
  static const MethodChannel _channel = MethodChannel(
    'com.treinopro.oficial/stripe_connect',
  );

  final ApiService _apiService;

  StripeConnectOnboardingService({required ApiService apiService})
    : _apiService = apiService;

  Future<void> presentEmbeddedOnboarding({String locale = 'pt-BR'}) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw UnsupportedError(
        'O onboarding embutido do Stripe está disponível apenas em iOS e Android.',
      );
    }

    final accessToken = _apiService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Sessão inválida. Faça login novamente para continuar.');
    }

    final publishableKey = AppConfig.stripePublishableKey;
    if (publishableKey.isEmpty) {
      throw Exception(
        'STRIPE_PUBLISHABLE_KEY não configurada no app. Ajuste o .env antes de continuar.',
      );
    }

    final appearance = StripeConnectAppearance.toNativeMap()
      ..['locale'] = locale;

    await _channel.invokeMethod('presentEmbeddedOnboarding', {
      'publishableKey': publishableKey,
      'baseUrl': AppConfig.apiBaseUrl,
      'accessToken': accessToken,
      'locale': locale,
      'appearance': appearance,
    });
  }
}
