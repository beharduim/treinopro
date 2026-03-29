import '../entities/payment_method.dart';

/// Repositório para métodos de pagamento
abstract class PaymentMethodsRepository {
  /// Obter métodos de pagamento do aluno
  Future<StudentPaymentSettings> getStudentPaymentMethods();

  /// Atualizar métodos de pagamento do aluno
  Future<StudentPaymentSettings> updatePaymentMethods({
    required PaymentMethodType preferredMethod,
    bool? enableAutoPayment,
    String? mpEmail,
    bool? mpAllowSaveCard,
  });

  /// Salvar cartão de crédito/débito
  Future<PaymentMethod> saveCard({
    required String cardNumber,
    required String cardHolderName,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required CardType cardType,
  });

  /// Validar cartão
  Future<bool> validateCard({
    required String cardNumber,
    required String cardHolderName,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
  });

  /// Remover cartão
  Future<void> removeCard(String cardId);

  /// Definir cartão como padrão
  Future<void> setDefaultCard(String cardId);

  /// Validar conta do Mercado Pago
  Future<bool> validateMercadoPagoAccount(String email);
}
