import 'package:equatable/equatable.dart';
import '../../domain/entities/payment_method.dart';

/// Eventos para o BLoC de métodos de pagamento
abstract class PaymentMethodsEvent extends Equatable {
  const PaymentMethodsEvent();

  @override
  List<Object?> get props => [];
}

/// Carregar métodos de pagamento do aluno
class LoadPaymentMethods extends PaymentMethodsEvent {
  const LoadPaymentMethods();
}

/// Atualizar método preferido
class UpdatePreferredMethod extends PaymentMethodsEvent {
  final PaymentMethodType method;

  const UpdatePreferredMethod(this.method);

  @override
  List<Object> get props => [method];
}

/// Atualizar configurações de pagamento
class UpdatePaymentSettings extends PaymentMethodsEvent {
  final PaymentMethodType preferredMethod;
  final bool? enableAutoPayment;

  const UpdatePaymentSettings({
    required this.preferredMethod,
    this.enableAutoPayment,
  });

  @override
  List<Object?> get props => [preferredMethod, enableAutoPayment];
}

/// Salvar cartão
class SaveCard extends PaymentMethodsEvent {
  final String cardNumber;
  final String cardHolderName;
  final String expiryMonth;
  final String expiryYear;
  final String cvv;
  final CardType cardType;

  const SaveCard({
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    required this.cardType,
  });

  @override
  List<Object> get props => [
    cardNumber,
    cardHolderName,
    expiryMonth,
    expiryYear,
    cvv,
    cardType,
  ];
}

/// Validar cartão
class ValidateCard extends PaymentMethodsEvent {
  final String cardNumber;
  final String cardHolderName;
  final String expiryMonth;
  final String expiryYear;
  final String cvv;

  const ValidateCard({
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
  });

  @override
  List<Object> get props => [
    cardNumber,
    cardHolderName,
    expiryMonth,
    expiryYear,
    cvv,
  ];
}

/// Remover cartão
class RemoveCard extends PaymentMethodsEvent {
  final String cardId;

  const RemoveCard(this.cardId);

  @override
  List<Object> get props => [cardId];
}

/// Definir cartão como padrão
class SetDefaultCard extends PaymentMethodsEvent {
  final String cardId;

  const SetDefaultCard(this.cardId);

  @override
  List<Object> get props => [cardId];
}

/// Limpar erros
class ClearErrors extends PaymentMethodsEvent {
  const ClearErrors();
}
