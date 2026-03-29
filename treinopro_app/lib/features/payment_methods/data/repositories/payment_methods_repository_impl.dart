import '../../../../core/error/failures.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/payment_methods_repository.dart';
import '../datasources/payment_methods_api_datasource.dart';

class PaymentMethodsRepositoryImpl implements PaymentMethodsRepository {
  final PaymentMethodsApiDataSource apiDataSource;

  PaymentMethodsRepositoryImpl({
    required this.apiDataSource,
  });

  @override
  Future<StudentPaymentSettings> getStudentPaymentMethods() async {
    try {
      final settings = await apiDataSource.getStudentPaymentMethods();
      return settings;
    } catch (e) {
      throw ServerFailure('Erro ao buscar métodos de pagamento: $e');
    }
  }

  @override
  Future<StudentPaymentSettings> updatePaymentMethods({
    required PaymentMethodType preferredMethod,
    bool? enableAutoPayment,
    String? mpEmail,
    bool? mpAllowSaveCard,
  }) async {
    try {
      final settings = await apiDataSource.updatePaymentMethods(
        preferredMethod: preferredMethod,
        enableAutoPayment: enableAutoPayment,
        mpEmail: mpEmail,
        mpAllowSaveCard: mpAllowSaveCard,
      );
      return settings;
    } catch (e) {
      throw ServerFailure('Erro ao atualizar métodos de pagamento: $e');
    }
  }

  @override
  Future<PaymentMethod> saveCard({
    required String cardNumber,
    required String cardHolderName,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required CardType cardType,
  }) async {
    try {
      final card = await apiDataSource.saveCard(
        cardNumber: cardNumber,
        cardHolderName: cardHolderName,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvv: cvv,
        cardType: cardType,
      );
      return card;
    } catch (e) {
      throw ServerFailure('Erro ao salvar cartão: $e');
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
      return await apiDataSource.validateCard(
        cardNumber: cardNumber,
        cardHolderName: cardHolderName,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvv: cvv,
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> removeCard(String cardId) async {
    try {
      await apiDataSource.removeCard(cardId);
    } catch (e) {
      throw ServerFailure('Erro ao remover cartão: $e');
    }
  }

  @override
  Future<void> setDefaultCard(String cardId) async {
    try {
      await apiDataSource.setDefaultCard(cardId);
    } catch (e) {
      throw ServerFailure('Erro ao definir cartão padrão: $e');
    }
  }

  @override
  Future<bool> validateMercadoPagoAccount(String email) async {
    try {
      return await apiDataSource.validateMercadoPagoAccount(email);
    } catch (e) {
      return false;
    }
  }
}
