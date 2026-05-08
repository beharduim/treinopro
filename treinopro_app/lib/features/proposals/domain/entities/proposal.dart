import 'package:equatable/equatable.dart';

/// Entidade principal da proposta de treino
class Proposal extends Equatable {
  final String? locationId;
  final String? locationName;
  final String? locationAddress;
  final double? locationLat;
  final double? locationLng;
  final DateTime? trainingDate;
  final String? trainingTime;
  final int? durationMinutes;
  final String? modalityId;
  final String? modalityName;
  final double? price;
  final String? additionalNotes;
  final String? paymentMethodId;
  final String? paymentMethodName;
  final dynamic
  selectedPaymentMethod; // PaymentMethod? - usando dynamic para evitar dependência circular
  final String?
  savedCardCvv; // CVV temporário para cartão salvo (transient, não persiste)
  final bool isCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Proposal({
    this.locationId,
    this.locationName,
    this.locationAddress,
    this.locationLat,
    this.locationLng,
    this.trainingDate,
    this.trainingTime,
    this.durationMinutes,
    this.modalityId,
    this.modalityName,
    this.price,
    this.additionalNotes,
    this.paymentMethodId,
    this.paymentMethodName,
    this.selectedPaymentMethod,
    this.savedCardCvv,
    this.isCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  Proposal copyWith({
    String? locationId,
    String? locationName,
    String? locationAddress,
    double? locationLat,
    double? locationLng,
    DateTime? trainingDate,
    String? trainingTime,
    int? durationMinutes,
    String? modalityId,
    String? modalityName,
    double? price,
    String? additionalNotes,
    String? paymentMethodId,
    String? paymentMethodName,
    dynamic selectedPaymentMethod,
    String? savedCardCvv,
    bool clearSavedCardCvv = false,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Proposal(
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      locationAddress: locationAddress ?? this.locationAddress,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      trainingDate: trainingDate ?? this.trainingDate,
      trainingTime: trainingTime ?? this.trainingTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      modalityId: modalityId ?? this.modalityId,
      modalityName: modalityName ?? this.modalityName,
      price: price ?? this.price,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      savedCardCvv: clearSavedCardCvv
          ? null
          : (savedCardCvv ?? this.savedCardCvv),
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validação da Etapa 1: Local, Data e Horário
  bool get isStep1Valid =>
      locationId != null &&
      locationId!.isNotEmpty &&
      trainingDate != null &&
      trainingTime != null &&
      trainingTime!.isNotEmpty;

  /// Validação da Etapa 2: Modalidade
  bool get isStep2Valid => modalityId != null && modalityId!.isNotEmpty;

  /// Validação da Etapa 3: Preço e Método de Pagamento
  bool get isStep3Valid =>
      price != null &&
      price! >= 1.0 &&
      paymentMethodId != null &&
      paymentMethodId!.isNotEmpty;

  /// Validação completa da proposta
  bool get isFullyValid => isStep1Valid && isStep2Valid && isStep3Valid;

  /// Progresso da proposta (0.0 a 1.0)
  double get progress {
    int completedSteps = 0;
    if (isStep1Valid) completedSteps++;
    if (isStep2Valid) completedSteps++;
    if (isStep3Valid) completedSteps++;
    return completedSteps / 3.0;
  }

  /// Próxima etapa a ser preenchida
  int get nextStep {
    if (!isStep1Valid) return 1;
    if (!isStep2Valid) return 2;
    if (!isStep3Valid) return 3;
    return 4; // Todas as etapas completas
  }

  @override
  List<Object?> get props => [
    locationId,
    locationName,
    locationAddress,
    locationLat,
    locationLng,
    trainingDate,
    trainingTime,
    durationMinutes,
    modalityId,
    modalityName,
    price,
    additionalNotes,
    paymentMethodId,
    paymentMethodName,
    selectedPaymentMethod,
    savedCardCvv,
    isCompleted,
    createdAt,
    updatedAt,
  ];
}
