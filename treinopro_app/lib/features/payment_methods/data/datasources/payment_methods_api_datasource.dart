import '../../../../core/error/exceptions.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/entities/payment_method.dart';
import '../models/payment_method_model.dart';

abstract class PaymentMethodsApiDataSource {
  Future<StudentPaymentSettingsModel> getStudentPaymentMethods();
  Future<StudentPaymentSettingsModel> updatePaymentMethods({
    required PaymentMethodType preferredMethod,
    bool? enableAutoPayment,
    String? mpEmail,
    bool? mpAllowSaveCard,
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
  Future<bool> validateMercadoPagoAccount(String email);
}

class PaymentMethodsApiDataSourceImpl implements PaymentMethodsApiDataSource {
  final ApiService apiService;

  PaymentMethodsApiDataSourceImpl({
    required this.apiService,
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
    String? mpEmail,
    bool? mpAllowSaveCard,
  }) async {
    try {
      final body = {
        'preferredMethod': _paymentMethodTypeToString(preferredMethod),
        if (enableAutoPayment != null) 'enableAutoPayment': enableAutoPayment,
        if (mpEmail != null) 'mercadoPagoAccount': {
          'email': mpEmail,
          'allowSaveCard': mpAllowSaveCard ?? true,
        },
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
      final body = {
        'cardNumber': cardNumber,
        'cardHolderName': cardHolderName,
        'expirationDate': '$expiryMonth/$expiryYear',
        'cvv': cvv,
        'cardType': _cardTypeToString(cardType),
      };

      final response = await apiService.dio.post(
        '/payments/student/cards/save',
        data: body,
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
      
      await apiService.dio.put(
        '/payments/student/methods',
        data: body,
      );
    } catch (e) {
      throw ServerException('Erro ao definir cartão padrão: $e');
    }
  }

  @override
  Future<bool> validateMercadoPagoAccount(String email) async {
    try {
      final body = {'email': email};
      
      final response = await apiService.dio.post(
        '/payments/student/methods/validate-mp',
        data: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  String _paymentMethodTypeToString(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
        return 'credit_card';
      case PaymentMethodType.debitCard:
        return 'debit_card';
      case PaymentMethodType.mercadoPago:
        return 'mercado_pago';
      case PaymentMethodType.pix:
        return 'pix';
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