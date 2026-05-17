import 'package:equatable/equatable.dart';
import '../../domain/entities/proposal.dart';
import '../../domain/entities/training_location.dart';
import '../../domain/entities/training_modality.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';
import '../../data/models/proposal_response_dto.dart';

/// Estados do BLoC de propostas
abstract class ProposalsState extends Equatable {
  const ProposalsState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ProposalsInitial extends ProposalsState {
  const ProposalsInitial();
}

/// Estado de carregamento
class ProposalsLoading extends ProposalsState {
  const ProposalsLoading();
}

/// Estado carregado com dados
class ProposalsLoaded extends ProposalsState {
  final Proposal proposal;
  final int currentStep;
  final int totalSteps;
  final List<TrainingLocation> searchedLocations;
  final List<TrainingModality> availableModalities;
  final List<String> availableTimeSlots;
  final List<PaymentMethod> availablePaymentMethods;
  final bool isLoadingLocations;
  final bool isLoadingModalities;
  final bool isLoadingTimeSlots;
  final bool isLoadingPaymentMethods;
  final bool isSubmitting;
  final String? errorMessage;
  final String? errorDetails;

  const ProposalsLoaded({
    required this.proposal,
    this.currentStep = 1,
    this.totalSteps = 4,
    this.searchedLocations = const [],
    this.availableModalities = const [],
    this.availableTimeSlots = const [],
    this.availablePaymentMethods = const [],
    this.isLoadingLocations = false,
    this.isLoadingModalities = false,
    this.isLoadingTimeSlots = false,
    this.isLoadingPaymentMethods = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.errorDetails,
  });

  ProposalsLoaded copyWith({
    Proposal? proposal,
    int? currentStep,
    int? totalSteps,
    List<TrainingLocation>? searchedLocations,
    List<TrainingModality>? availableModalities,
    List<String>? availableTimeSlots,
    List<PaymentMethod>? availablePaymentMethods,
    bool? isLoadingLocations,
    bool? isLoadingModalities,
    bool? isLoadingTimeSlots,
    bool? isLoadingPaymentMethods,
    bool? isSubmitting,
    String? errorMessage,
    String? errorDetails,
    bool clearError = false,
  }) {
    return ProposalsLoaded(
      proposal: proposal ?? this.proposal,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      searchedLocations: searchedLocations ?? this.searchedLocations,
      availableModalities: availableModalities ?? this.availableModalities,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      availablePaymentMethods:
          availablePaymentMethods ?? this.availablePaymentMethods,
      isLoadingLocations: isLoadingLocations ?? this.isLoadingLocations,
      isLoadingModalities: isLoadingModalities ?? this.isLoadingModalities,
      isLoadingTimeSlots: isLoadingTimeSlots ?? this.isLoadingTimeSlots,
      isLoadingPaymentMethods:
          isLoadingPaymentMethods ?? this.isLoadingPaymentMethods,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorDetails: clearError ? null : (errorDetails ?? this.errorDetails),
    );
  }

  /// Verificar se a etapa atual é válida
  bool get isCurrentStepValid {
    switch (currentStep) {
      case 1:
        return proposal.isStep1Valid;
      case 2:
        return proposal.isStep2Valid;
      case 3:
        return proposal.isStep3Valid;
      case 4: // Etapa de revisão sempre válida se chegou até aqui
        return proposal.isFullyValid;
      default:
        return false;
    }
  }

  /// Verificar se pode avançar para próxima etapa
  bool get canGoToNextStep => isCurrentStepValid && currentStep < totalSteps;

  /// Verificar se pode voltar para etapa anterior
  bool get canGoToPreviousStep => currentStep > 1;

  /// Verificar se pode submeter a proposta
  bool get canSubmit => proposal.isFullyValid && currentStep == totalSteps;

  @override
  List<Object?> get props => [
    proposal,
    currentStep,
    totalSteps,
    searchedLocations,
    availableModalities,
    availableTimeSlots,
    availablePaymentMethods,
    isLoadingLocations,
    isLoadingModalities,
    isLoadingTimeSlots,
    isLoadingPaymentMethods,
    isSubmitting,
    errorMessage,
    errorDetails,
  ];
}

/// Estado de erro
class ProposalsError extends ProposalsState {
  final String message;
  final String? details;

  const ProposalsError({required this.message, this.details});

  @override
  List<Object?> get props => [message, details];
}

/// Estado de sucesso após submeter proposta
class ProposalsSubmitted extends ProposalsState {
  final Proposal submittedProposal;
  final String? proposalId; // ID da resposta da API

  const ProposalsSubmitted({required this.submittedProposal, this.proposalId});

  @override
  List<Object?> get props => [submittedProposal, proposalId];
}

/// Estado de pagamento pendente (redirecionamento para checkout)
class ProposalsPaymentPending extends ProposalsState {
  final Proposal submittedProposal;
  final String proposalId;
  final PaymentData payment;

  const ProposalsPaymentPending({
    required this.submittedProposal,
    required this.proposalId,
    required this.payment,
  });

  @override
  List<Object> get props => [submittedProposal, proposalId, payment];
}

// ===== ESTADOS PARA LISTAGEM DE PROPOSTAS (PERSONAL TRAINER) =====

/// Estado de carregamento das propostas disponíveis
class ProposalsAvailableLoading extends ProposalsState {
  const ProposalsAvailableLoading();
}

/// Estado com propostas disponíveis carregadas
class ProposalsAvailableLoaded extends ProposalsState {
  final List<ProposalResponseDto> proposals;
  final int total;
  final int page;
  final int limit;
  final String? selectedStatus;
  final String? selectedModality;
  final String? selectedDateFrom;
  final String? selectedDateTo;
  final bool isWebSocketConnected;
  final String? error;

  const ProposalsAvailableLoaded({
    required this.proposals,
    required this.total,
    required this.page,
    required this.limit,
    this.selectedStatus,
    this.selectedModality,
    this.selectedDateFrom,
    this.selectedDateTo,
    this.isWebSocketConnected = false,
    this.error,
  });

  @override
  List<Object?> get props => [
    proposals,
    total,
    page,
    limit,
    selectedStatus,
    selectedModality,
    selectedDateFrom,
    selectedDateTo,
    isWebSocketConnected,
    error,
  ];

  ProposalsAvailableLoaded copyWith({
    List<ProposalResponseDto>? proposals,
    int? total,
    int? page,
    int? limit,
    String? selectedStatus,
    String? selectedModality,
    String? selectedDateFrom,
    String? selectedDateTo,
    bool? isWebSocketConnected,
    String? error,
  }) {
    return ProposalsAvailableLoaded(
      proposals: proposals ?? this.proposals,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedModality: selectedModality ?? this.selectedModality,
      selectedDateFrom: selectedDateFrom ?? this.selectedDateFrom,
      selectedDateTo: selectedDateTo ?? this.selectedDateTo,
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
      error: error ?? this.error,
    );
  }
}

/// Estado de erro ao carregar propostas disponíveis
class ProposalsAvailableError extends ProposalsState {
  final String message;
  final List<ProposalResponseDto>? proposals;

  const ProposalsAvailableError({required this.message, this.proposals});

  @override
  List<Object?> get props => [message, proposals];
}

/// Estado de operação em andamento (aceitar proposta)
class ProposalsOperationInProgress extends ProposalsState {
  final List<ProposalResponseDto> proposals;
  final String operation;
  final bool isWebSocketConnected;

  const ProposalsOperationInProgress({
    required this.proposals,
    required this.operation,
    this.isWebSocketConnected = false,
  });

  @override
  List<Object> get props => [proposals, operation, isWebSocketConnected];
}

/// Estado de operação concluída com sucesso
class ProposalsOperationSuccess extends ProposalsState {
  final List<ProposalResponseDto> proposals;
  final String message;
  final bool isWebSocketConnected;

  const ProposalsOperationSuccess({
    required this.proposals,
    required this.message,
    this.isWebSocketConnected = false,
  });

  @override
  List<Object> get props => [proposals, message, isWebSocketConnected];
}

/// Estado de operação falhou
class ProposalsOperationFailure extends ProposalsState {
  final List<ProposalResponseDto> proposals;
  final String error;
  final bool isWebSocketConnected;

  const ProposalsOperationFailure({
    required this.proposals,
    required this.error,
    this.isWebSocketConnected = false,
  });

  @override
  List<Object> get props => [proposals, error, isWebSocketConnected];
}

/// Estado de nova proposta criada - para mostrar modal automático
class ProposalsNewProposalCreated extends ProposalsState {
  final ProposalResponseDto newProposal;
  final List<ProposalResponseDto> proposals;
  final bool isWebSocketConnected;

  const ProposalsNewProposalCreated({
    required this.newProposal,
    required this.proposals,
    this.isWebSocketConnected = false,
  });

  @override
  List<Object> get props => [newProposal, proposals, isWebSocketConnected];
}
