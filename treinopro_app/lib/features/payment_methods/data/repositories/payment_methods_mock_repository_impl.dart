import '../../../../core/error/failures.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/payment_methods_repository.dart';
import '../datasources/payment_methods_mock_datasource.dart';
import '../models/payment_method_model.dart';

class PaymentMethodsMockRepositoryImpl implements PaymentMethodsRepository {
  final PaymentMethodsMockDataSource mockDataSource;

  PaymentMethodsMockRepositoryImpl({required this.mockDataSource});

  @override
  Future<StudentPaymentSettings> getStudentPaymentMethods() async {
    try {
      final settings = await mockDataSource.getStudentPaymentMethods();
      return settings;
    } catch (e) {
      throw ServerFailure('Erro ao buscar métodos de pagamento: $e');
    }
  }

  @override
  Future<StudentPaymentSettings> updatePaymentMethods({
    required PaymentMethodType preferredMethod,
    bool? enableAutoPayment,
  }) async {
    try {
      final settings = await mockDataSource.updatePaymentMethods(
        preferredMethod: preferredMethod,
        enableAutoPayment: enableAutoPayment,
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
      final card = await mockDataSource.saveCard(
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
      return await mockDataSource.validateCard(
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
      await mockDataSource.removeCard(cardId);
    } catch (e) {
      throw ServerFailure('Erro ao remover cartão: $e');
    }
  }

  @override
  Future<void> setDefaultCard(String cardId) async {
    try {
      await mockDataSource.setDefaultCard(cardId);
    } catch (e) {
      throw ServerFailure('Erro ao definir cartão padrão: $e');
    }
  }
}
