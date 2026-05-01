import '../../../../core/error/exceptions.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/entities/payment_method.dart';
import '../models/payment_method_model.dart';
import '../services/stripe_payment_sheet_service.dart';

abstract class PaymentMethodsApiDataSource {
  Future<StudentPaymentSettingsModel> getStudentPaymentMethods();
  Future<StudentPaymentSettingsModel> updatePaymentMethods({
    required PaymentMethodType preferredMethod,
    bool? enableAutoPayment,
  });
  Future<PaymentMethodModel> saveCard({
    required String cardNumber,
    required String cardHolderName,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required CardType cardType,
  });
  Future<bool> validateCard({
    required String cardNumber,
    required String cardHolderName,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
  });
  Future<void> removeCard(String cardId);
  Future<void> setDefaultCard(String cardId);
}

class PaymentMethodsApiDataSourceImpl implements PaymentMethodsApiDataSource {
  final ApiService apiService;
  final StripePaymentSheetService stripePaymentSheetService;

  PaymentMethodsApiDataSourceImpl({
    required this.apiService,
    required this.stripePaymentSheetService,
  });

  @override
  Future<StudentPaymentSettingsModel> getStudentPaymentMethods() async {
    try {
      final response = await apiService.dio.get('/payments/student/methods');
      return StudentPaymentSettingsModel.fromJson(response.data);
    } catch (e) {
      throw ServerException('Erro ao buscar métodos de pagamento: $e');
    }
  }

  @override
  Future<StudentPaymentSettingsModel> updatePaymentMethods({
    required PaymentMethodType preferredMethod,
    bool? enableAutoPayment,
  }) async {
    try {
      final body = {
        'preferredMethod': _paymentMethodTypeToString(preferredMethod),
        if (enableAutoPayment != null) 'enableAutoPayment': enableAutoPayment,
      };

      final response = await apiService.dio.put(
        '/payments/student/methods',
        data: body,
      );

      return StudentPaymentSettingsModel.fromJson(response.data);
    } catch (e) {
      throw ServerException('Erro ao atualizar métodos de pagamento: $e');
    }
  }

  @override
  Future<PaymentMethodModel> saveCard({
    required String cardNumber,
    required String cardHolderName,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required CardType cardType,
  }) async {
    try {
      final setupResponse = await apiService.dio.post(
        '/payments/student/stripe/setup-intent',
      );
      final setupData = setupResponse.data as Map<String, dynamic>;

      final clientSecret = setupData['clientSecret']?.toString() ?? '';
      final customerId = setupData['customerId']?.toString() ?? '';
      final ephemeralKeySecret =
          setupData['ephemeralKeySecret']?.toString() ?? '';
      final publishableKey = setupData['publishableKey']?.toString() ?? '';
      final setupIntentId =
          setupData['setupIntentId']?.toString() ??
          clientSecret.split('_secret_').first;

      await stripePaymentSheetService.presentSetupSheet(
        clientSecret: clientSecret,
        customerId: customerId,
        ephemeralKeySecret: ephemeralKeySecret,
        publishableKey: publishableKey,
      );

      final response = await apiService.dio.post(
        '/payments/student/stripe/setup-intent/confirm',
        data: {
          'setupIntentId': setupIntentId,
          'cardType': _cardTypeToString(cardType),
        },
      );

      return PaymentMethodModel.fromJson(response.data);
    } catch (e) {
      throw ServerException('Erro ao salvar cartão: $e');
    }
  }

  @override
  Future<bool> validateCard({
    required String cardNumber,
    required String cardHolderName,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
  }) async {
    try {
      final body = {
        'cardNumber': cardNumber,
        'cardHolderName': cardHolderName,
        'expiryMonth': expiryMonth,
        'expiryYear': expiryYear,
        'cvv': cvv,
      };

      final response = await apiService.dio.post(
        '/payments/student/cards/validate',
        data: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> removeCard(String cardId) async {
    try {
      await apiService.dio.delete('/payments/student/cards/$cardId');
    } catch (e) {
      throw ServerException('Erro ao remover cartão: $e');
    }
  }

  @override
  Future<void> setDefaultCard(String cardId) async {
    try {
      final body = {'defaultCardId': cardId};

      await apiService.dio.put('/payments/student/methods', data: body);
    } catch (e) {
      throw ServerException('Erro ao definir cartão padrão: $e');
    }
  }

  String _paymentMethodTypeToString(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
        return 'credit_card';
      case PaymentMethodType.debitCard:
        return 'debit_card';
    }
  }

  String _cardTypeToString(CardType type) {
    switch (type) {
      case CardType.credit:
        return 'credit';
      case CardType.debit:
        return 'debit';
    }
  }
}
