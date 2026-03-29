import '../../domain/entities/payment_method.dart';
import '../models/payment_method_model.dart';

/// Mock datasource para testes e desenvolvimento
class PaymentMethodsMockDataSource {
  Future<StudentPaymentSettingsModel> getStudentPaymentMethods() async {
    // Simular delay de rede
    await Future.delayed(const Duration(seconds: 1));
    
    // Retornar dados mock
    return StudentPaymentSettingsModel.fromJson({
      'id': 'mock-payment-settings-1',
      'preferredMethod': 'credit_card',
      'enableAutoPayment': false,
      'defaultCardId': null,
      'mpEmail': null,
      'mpIsVerified': false,
      'mpAllowSaveCard': true,
      'canMakePayments': true,
      'hasValidPaymentMethod': false,
      'savedCards': [],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<StudentPaymentSettingsModel> updatePaymentMethods({
    required PaymentMethodType preferredMethod,
    bool? enableAutoPayment,
    String? mpEmail,
    bool? mpAllowSaveCard,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    return StudentPaymentSettingsModel.fromJson({
      'id': 'mock-payment-settings-1',
      'preferredMethod': preferredMethod.toString().split('.').last,
      'enableAutoPayment': enableAutoPayment ?? false,
      'defaultCardId': null,
      'mpEmail': mpEmail,
      'mpIsVerified': mpEmail != null,
      'mpAllowSaveCard': mpAllowSaveCard ?? true,
      'canMakePayments': true,
      'hasValidPaymentMethod': true,
      'savedCards': [],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<PaymentMethodModel> saveCard({
    required String cardNumber,
    required String cardHolderName,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required CardType cardType,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    return PaymentMethodModel.fromJson({
      'id': 'mock-card-${DateTime.now().millisecondsSinceEpoch}',
      'type': cardType == CardType.credit ? 'credit_card' : 'debit_card',
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cvv': cvv,
      'cardBrand': _detectCardBrand(cardNumber),
      'cardType': cardType.toString().split('.').last,
      'mpEmail': null,
      'isVerified': true,
      'isDefault': false,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> validateCard({
    required String cardNumber,
    required String cardHolderName,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Validação simples para mock
    return cardNumber.length >= 13 && 
           cardNumber.length <= 19 && 
           cardHolderName.isNotEmpty &&
           expiryMonth.isNotEmpty &&
           expiryYear.isNotEmpty &&
           cvv.length >= 3;
  }

  Future<void> removeCard(String cardId) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock - sempre sucesso
  }

  Future<void> setDefaultCard(String cardId) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock - sempre sucesso
  }

  Future<bool> validateMercadoPagoAccount(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Validação simples de email para mock
    return email.contains('@') && email.contains('.');
  }

  String _detectCardBrand(String cardNumber) {
    if (cardNumber.startsWith('4')) return 'visa';
    if (cardNumber.startsWith('5') || cardNumber.startsWith('2')) return 'mastercard';
    if (cardNumber.startsWith('3')) return 'american_express';
    if (cardNumber.startsWith('6')) return 'elo';
    return 'unknown';
  }
}
