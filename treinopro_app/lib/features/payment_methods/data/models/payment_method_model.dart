import '../../domain/entities/payment_method.dart';

/// Modelo para método de pagamento
class PaymentMethodModel extends PaymentMethod {
  const PaymentMethodModel({
    required super.id,
    required super.type,
    super.cardNumber,
    super.cardHolderName,
    super.expiryMonth,
    super.expiryYear,
    super.cvv,
    super.cardBrand,
    super.cardType,
    super.isVerified = false,
    super.isDefault = false,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    // Debug: imprimir dados recebidos
    print('🔍 PaymentMethodModel.fromJson - Dados recebidos:');
    print('  - id: ${json['id']}');
    print('  - lastFourDigits: ${json['lastFourDigits']}');
    print('  - cardBrand: ${json['cardBrand']}');
    print('  - cardType: ${json['cardType']}');
    print('  - cardHolderName: ${json['cardHolderName']}');
    print('  - expirationMonth: ${json['expirationMonth']}');
    print('  - expirationYear: ${json['expirationYear']}');
    print('  - isDefault: ${json['isDefault']}');

    return PaymentMethodModel(
      id: json['id'] as String? ?? '',
      type: _parsePaymentMethodType(json['type'] as String? ?? 'credit_card'),
      cardNumber: json['lastFourDigits'] != null
          ? '**** **** **** ${json['lastFourDigits']}'
          : null,
      cardHolderName: json['cardHolderName'] as String?,
      expiryMonth: json['expirationMonth'] as String?,
      expiryYear: json['expirationYear'] as String?,
      cvv: json['cvv'] as String?,
      cardBrand: json['cardBrand'] != null
          ? _parseCardBrand(json['cardBrand'] as String)
          : null,
      cardType: json['cardType'] != null
          ? _parseCardType(json['cardType'] as String)
          : null,
      isVerified: json['isVerified'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': _paymentMethodTypeToString(type),
      if (cardNumber != null) 'cardNumber': cardNumber,
      if (cardHolderName != null) 'cardHolderName': cardHolderName,
      if (expiryMonth != null) 'expiryMonth': expiryMonth,
      if (expiryYear != null) 'expiryYear': expiryYear,
      if (cvv != null) 'cvv': cvv,
      if (cardBrand != null) 'cardBrand': _cardBrandToString(cardBrand!),
      if (cardType != null) 'cardType': _cardTypeToString(cardType!),
      'isVerified': isVerified,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static PaymentMethodType _parsePaymentMethodType(String type) {
    switch (type) {
      case 'credit_card':
        return PaymentMethodType.creditCard;
      case 'debit_card':
        return PaymentMethodType.debitCard;
      default:
        throw ArgumentError('Tipo de método de pagamento inválido: $type');
    }
  }

  static String _paymentMethodTypeToString(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
        return 'credit_card';
      case PaymentMethodType.debitCard:
        return 'debit_card';
    }
  }

  static CardBrand _parseCardBrand(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return CardBrand.visa;
      case 'mastercard':
        return CardBrand.mastercard;
      case 'american_express':
      case 'amex':
        return CardBrand.americanExpress;
      case 'elo':
        return CardBrand.elo;
      case 'hipercard':
        return CardBrand.hipercard;
      case 'diners':
        return CardBrand.diners;
      case 'discover':
        return CardBrand.discover;
      case 'jcb':
        return CardBrand.jcb;
      case 'aura':
        return CardBrand.aura;
      default:
        return CardBrand.unknown;
    }
  }

  static String _cardBrandToString(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return 'visa';
      case CardBrand.mastercard:
        return 'mastercard';
      case CardBrand.americanExpress:
        return 'american_express';
      case CardBrand.elo:
        return 'elo';
      case CardBrand.hipercard:
        return 'hipercard';
      case CardBrand.diners:
        return 'diners';
      case CardBrand.discover:
        return 'discover';
      case CardBrand.jcb:
        return 'jcb';
      case CardBrand.aura:
        return 'aura';
      case CardBrand.unknown:
        return 'unknown';
    }
  }

  static CardType _parseCardType(String type) {
    switch (type) {
      case 'credit':
        return CardType.credit;
      case 'debit':
        return CardType.debit;
      default:
        throw ArgumentError('Tipo de cartão inválido: $type');
    }
  }

  static String _cardTypeToString(CardType type) {
    switch (type) {
      case CardType.credit:
        return 'credit';
      case CardType.debit:
        return 'debit';
    }
  }
}

/// Modelo para configurações de pagamento do aluno
class StudentPaymentSettingsModel extends StudentPaymentSettings {
  const StudentPaymentSettingsModel({
    required super.id,
    required super.preferredMethod,
    required super.enableAutoPayment,
    super.defaultCardId,
    required super.canMakePayments,
    required super.hasValidPaymentMethod,
    required super.savedCards,
    required super.createdAt,
    required super.updatedAt,
  });

  factory StudentPaymentSettingsModel.fromJson(Map<String, dynamic> json) {
    return StudentPaymentSettingsModel(
      id: json['id'] as String? ?? '',
      preferredMethod: PaymentMethodModel._parsePaymentMethodType(
        json['preferredMethod'] as String? ?? 'credit_card',
      ),
      enableAutoPayment: (json['enableAutoPayment'] as bool?) ?? false,
      defaultCardId: json['defaultCardId'] as String?,
      canMakePayments: (json['canMakePayments'] as bool?) ?? false,
      hasValidPaymentMethod: (json['hasValidPaymentMethod'] as bool?) ?? false,
      savedCards:
          (json['savedCards'] as List<dynamic>?)
              ?.map(
                (card) =>
                    PaymentMethodModel.fromJson(card as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'preferredMethod': PaymentMethodModel._paymentMethodTypeToString(
        preferredMethod,
      ),
      'enableAutoPayment': enableAutoPayment,
      if (defaultCardId != null) 'defaultCardId': defaultCardId,
      'canMakePayments': canMakePayments,
      'hasValidPaymentMethod': hasValidPaymentMethod,
      'savedCards': savedCards
          .map((card) => (card as PaymentMethodModel).toJson())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
