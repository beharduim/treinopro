import 'package:equatable/equatable.dart';

/// Enum para tipos de métodos de pagamento
enum PaymentMethodType { creditCard, debitCard }

/// Enum para bandeiras de cartão
enum CardBrand {
  visa,
  mastercard,
  americanExpress,
  elo,
  hipercard,
  diners,
  discover,
  jcb,
  aura,
  unknown,
}

/// Enum para tipo de cartão
enum CardType { credit, debit }

/// Entidade para método de pagamento
class PaymentMethod extends Equatable {
  final String id;
  final PaymentMethodType type;
  final String? cardNumber;
  final String? cardHolderName;
  final String? expiryMonth;
  final String? expiryYear;
  final String? cvv;
  final CardBrand? cardBrand;
  final CardType? cardType;
  final bool isVerified;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentMethod({
    required this.id,
    required this.type,
    this.cardNumber,
    this.cardHolderName,
    this.expiryMonth,
    this.expiryYear,
    this.cvv,
    this.cardBrand,
    this.cardType,
    this.isVerified = false,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    cardNumber,
    cardHolderName,
    expiryMonth,
    expiryYear,
    cvv,
    cardBrand,
    cardType,
    isVerified,
    isDefault,
    createdAt,
    updatedAt,
  ];

  PaymentMethod copyWith({
    String? id,
    PaymentMethodType? type,
    String? cardNumber,
    String? cardHolderName,
    String? expiryMonth,
    String? expiryYear,
    String? cvv,
    CardBrand? cardBrand,
    CardType? cardType,
    bool? isVerified,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cvv: cvv ?? this.cvv,
      cardBrand: cardBrand ?? this.cardBrand,
      cardType: cardType ?? this.cardType,
      isVerified: isVerified ?? this.isVerified,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Entidade para configurações de pagamento do aluno
class StudentPaymentSettings extends Equatable {
  final String id;
  final PaymentMethodType preferredMethod;
  final bool enableAutoPayment;
  final String? defaultCardId;
  final bool canMakePayments;
  final bool hasValidPaymentMethod;
  final List<PaymentMethod> savedCards;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentPaymentSettings({
    required this.id,
    required this.preferredMethod,
    required this.enableAutoPayment,
    this.defaultCardId,
    required this.canMakePayments,
    required this.hasValidPaymentMethod,
    required this.savedCards,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    preferredMethod,
    enableAutoPayment,
    defaultCardId,
    canMakePayments,
    hasValidPaymentMethod,
    savedCards,
    createdAt,
    updatedAt,
  ];
}
