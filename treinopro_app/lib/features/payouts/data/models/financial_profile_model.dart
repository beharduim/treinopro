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
    };
    return values.toList();
  }

  List<StripeRequirementItem> get outstandingRequirementItems =>
      outstandingRequirements
          .map((code) => StripeRequirementItem.fromCode(code))
          .toList();

  List<String> get outstandingRequirementLabels => outstandingRequirementItems
      .map((requirement) => requirement.displayLabel)
      .toList();

  List<String> get pendingVerificationRequirements =>
      requirements.pendingVerification;

  bool get hasPendingRequirements => outstandingRequirements.isNotEmpty;

  bool get hasPendingVerification => pendingVerificationRequirements.isNotEmpty;

  bool get isReadyForPayout =>
      onboardingCompleted &&
      detailsSubmitted &&
      payoutsEnabled &&
      !hasPendingRequirements &&
      !hasPendingVerification;

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
    if (hasPendingVerification || !payoutsEnabled) {
      return 'Validação da Stripe em andamento';
    }
    return 'Validação da Stripe em andamento';
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
    if (hasPendingVerification) {
      return 'Recebemos seus dados e a Stripe está finalizando a análise da sua conta. Você não precisa refazer o cadastro; avisaremos quando os saques forem liberados.';
    }
    if (!payoutsEnabled) {
      return 'A Stripe ainda está finalizando a análise da sua conta. Isso pode levar algum tempo, mas você não precisa refazer o cadastro.';
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
    if (!hasPendingRequirements) {
      return 'Verificar status';
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

class StripeRequirementItem {
  final String code;
  final StripeRequirementType type;

  const StripeRequirementItem({required this.code, required this.type});

  factory StripeRequirementItem.fromCode(String code) {
    return StripeRequirementItem(
      code: code,
      type: StripeRequirementType.fromCode(code),
    );
  }

  String get displayLabel => type.displayLabelFor(code);
}

enum StripeRequirementType {
  externalAccount('Conta bancária para recebimento'),
  identityProofOfLiveness('Verificação facial de identidade'),
  identityDocument('Documento de identidade'),
  representativeDocument('Documento do representante'),
  businessProfile('Dados profissionais'),
  address('Endereço'),
  birthDate('Data de nascimento'),
  fullName('Nome completo'),
  phone('Telefone'),
  email('E-mail'),
  taxId('CPF/CNPJ'),
  termsOfService('Aceite dos termos da Stripe'),
  unknown('Informação adicional solicitada pela Stripe');

  final String label;

  const StripeRequirementType(this.label);

  static StripeRequirementType fromCode(String code) {
    final normalized = code.trim().toLowerCase();

    if (normalized == 'external_account') {
      return StripeRequirementType.externalAccount;
    }
    if (normalized.contains('proof_of_liveness')) {
      return StripeRequirementType.identityProofOfLiveness;
    }
    if (normalized == 'representative.document') {
      return StripeRequirementType.representativeDocument;
    }
    if (normalized.contains('verification.document')) {
      if (normalized.startsWith('representative.')) {
        return StripeRequirementType.representativeDocument;
      }
      return StripeRequirementType.identityDocument;
    }
    if (normalized.contains('business_profile')) {
      return StripeRequirementType.businessProfile;
    }
    if (normalized.contains('.address.')) {
      return StripeRequirementType.address;
    }
    if (normalized.contains('.dob.') || normalized.endsWith('.dob')) {
      return StripeRequirementType.birthDate;
    }
    if (normalized.endsWith('.first_name') ||
        normalized.endsWith('.last_name') ||
        normalized.endsWith('.name')) {
      return StripeRequirementType.fullName;
    }
    if (normalized.endsWith('.phone')) {
      return StripeRequirementType.phone;
    }
    if (normalized.endsWith('.email')) {
      return StripeRequirementType.email;
    }
    if (normalized.endsWith('.id_number') ||
        normalized.endsWith('.tax_id') ||
        normalized.endsWith('.tax_id_registrar')) {
      return StripeRequirementType.taxId;
    }
    if (normalized.contains('tos_acceptance')) {
      return StripeRequirementType.termsOfService;
    }

    return StripeRequirementType.unknown;
  }

  String displayLabelFor(String code) {
    if (this != StripeRequirementType.unknown) {
      return label;
    }

    final normalized = code.trim();
    if (normalized.isEmpty) {
      return label;
    }

    return '$label: ${_humanizeUnknownRequirement(normalized)}';
  }

  static String _humanizeUnknownRequirement(String code) {
    final parts = code
        .split('.')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part.replaceAll('_', ' '))
        .toList();

    if (parts.isEmpty) {
      return code;
    }

    return parts.join(' > ');
  }
}
