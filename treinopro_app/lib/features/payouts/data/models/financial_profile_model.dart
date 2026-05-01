class FinancialProfileModel {
  final String preferredMethod;
  final bool canReceivePayments;
  final StripeConnectAccountModel? stripeAccount;

  const FinancialProfileModel({
    required this.preferredMethod,
    required this.canReceivePayments,
    required this.stripeAccount,
  });

  factory FinancialProfileModel.fromJson(Map<String, dynamic> json) {
    return FinancialProfileModel(
      preferredMethod: json['preferredMethod']?.toString() ?? 'bank_transfer',
      canReceivePayments: _parseBool(json['canReceivePayments']),
      stripeAccount: json['stripeAccount'] is Map<String, dynamic>
          ? StripeConnectAccountModel.fromJson(
              json['stripeAccount'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  bool get hasStripeAccount => stripeAccount?.accountId.isNotEmpty == true;

  bool get requiresStripeOnboarding =>
      stripeAccount == null || !stripeAccount!.isReadyForPayout;

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return false;
  }
}

class StripeConnectAccountModel {
  final String accountId;
  final bool onboardingCompleted;
  final bool chargesEnabled;
  final bool payoutsEnabled;
  final bool detailsSubmitted;
  final StripeRequirementStatusModel requirements;

  const StripeConnectAccountModel({
    required this.accountId,
    required this.onboardingCompleted,
    required this.chargesEnabled,
    required this.payoutsEnabled,
    required this.detailsSubmitted,
    required this.requirements,
  });

  factory StripeConnectAccountModel.fromJson(Map<String, dynamic> json) {
    return StripeConnectAccountModel(
      accountId: json['accountId']?.toString() ?? '',
      onboardingCompleted: _parseBool(json['onboardingCompleted']),
      chargesEnabled: _parseBool(json['chargesEnabled']),
      payoutsEnabled: _parseBool(json['payoutsEnabled']),
      detailsSubmitted: _parseBool(json['detailsSubmitted']),
      requirements: StripeRequirementStatusModel.fromJson(
        (json['requirements'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  List<String> get outstandingRequirements {
    final values = <String>{
      ...requirements.currentlyDue,
      ...requirements.pastDue,
      ...requirements.pendingVerification,
    };
    return values.toList();
  }

  bool get hasPendingRequirements => outstandingRequirements.isNotEmpty;

  bool get isReadyForPayout =>
      onboardingCompleted &&
      detailsSubmitted &&
      payoutsEnabled &&
      !hasPendingRequirements;

  String get statusTitle {
    if (isReadyForPayout) {
      return 'Recebimento liberado';
    }
    if (accountId.isEmpty) {
      return 'Recebimento não iniciado';
    }
    if (hasPendingRequirements) {
      return 'Onboarding pendente';
    }
    return 'Aguardando validação';
  }

  String get statusDescription {
    if (isReadyForPayout) {
      return 'Sua conta está apta para receber saques.';
    }
    if (accountId.isEmpty) {
      return 'A plataforma cria sua conta automaticamente quando você iniciar a configuração.';
    }
    if (hasPendingRequirements) {
      final count = outstandingRequirements.length;
      return 'Faltam $count requisito${count == 1 ? '' : 's'} para liberar seus saques.';
    }
    if (!payoutsEnabled) {
      return 'Sua conta ainda está sendo validada pelo Stripe.';
    }
    return 'Revise seus dados para concluir a configuração financeira.';
  }

  String get actionLabel {
    if (accountId.isEmpty) {
      return 'Começar configuração';
    }
    if (isReadyForPayout) {
      return 'Revisar dados';
    }
    return 'Continuar onboarding';
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return false;
  }
}

class StripeRequirementStatusModel {
  final List<String> currentlyDue;
  final List<String> eventuallyDue;
  final List<String> pastDue;
  final List<String> pendingVerification;
  final String? disabledReason;

  const StripeRequirementStatusModel({
    required this.currentlyDue,
    required this.eventuallyDue,
    required this.pastDue,
    required this.pendingVerification,
    required this.disabledReason,
  });

  factory StripeRequirementStatusModel.fromJson(Map<String, dynamic> json) {
    return StripeRequirementStatusModel(
      currentlyDue: _parseStringList(json['currentlyDue']),
      eventuallyDue: _parseStringList(json['eventuallyDue']),
      pastDue: _parseStringList(json['pastDue']),
      pendingVerification: _parseStringList(json['pendingVerification']),
      disabledReason: json['disabledReason']?.toString(),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }
}
