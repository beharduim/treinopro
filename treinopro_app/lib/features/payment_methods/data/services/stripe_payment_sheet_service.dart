import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripePaymentSheetService {
  static String? _appliedPublishableKey;

  Future<void> presentSetupSheet({
    required String clientSecret,
    required String customerId,
    required String ephemeralKeySecret,
    required String publishableKey,
  }) async {
    await _applyPublishableKey(publishableKey);
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: 'TreinoPro',
        setupIntentClientSecret: clientSecret,
        customerId: customerId,
        customerEphemeralKeySecret: ephemeralKeySecret,
        allowsDelayedPaymentMethods: false,
        style: ThemeMode.system,
      ),
    );
    await _present();
  }

  Future<void> presentPaymentSheet({
    required String clientSecret,
    required String customerId,
    required String ephemeralKeySecret,
    required String publishableKey,
  }) async {
    await _applyPublishableKey(publishableKey);
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: 'TreinoPro',
        paymentIntentClientSecret: clientSecret,
        customerId: customerId,
        customerEphemeralKeySecret: ephemeralKeySecret,
        allowsDelayedPaymentMethods: false,
        style: ThemeMode.system,
      ),
    );
    await _present();
  }

  Future<void> _applyPublishableKey(String publishableKey) async {
    final normalizedPublishableKey = publishableKey.trim();
    if (normalizedPublishableKey.isEmpty) {
      throw Exception('Chave publica Stripe nao recebida');
    }

    if (_appliedPublishableKey != normalizedPublishableKey) {
      Stripe.publishableKey = normalizedPublishableKey;
      await Stripe.instance.applySettings();
      _appliedPublishableKey = normalizedPublishableKey;
    }
  }

  Future<void> _present() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } on StripeConfigException catch (e) {
      throw Exception(e.message);
    } on StripeException catch (e) {
      final code = e.error.code.toString().toLowerCase();
      if (code.contains('cancel')) {
        throw Exception('Pagamento cancelado');
      }
      throw Exception(e.error.localizedMessage ?? 'Erro ao abrir Stripe');
    }
  }
}
