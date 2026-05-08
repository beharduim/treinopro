import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/websocket_service.dart';
import '../../domain/entities/proposal.dart';
import '../../domain/usecases/save_proposal.dart';
import '../../domain/usecases/get_proposal.dart';
import '../../domain/usecases/search_locations.dart';
import '../../domain/usecases/get_modalities.dart';
import '../../domain/usecases/submit_proposal.dart';
import '../../domain/usecases/create_proposal.dart';
import '../../domain/repositories/proposals_repository.dart';
import '../../data/services/personal_proposals_api_service.dart';
import '../../data/services/popular_locations_service.dart';
import '../../data/models/proposal_response_dto.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';
import '../../../payment_methods/domain/repositories/payment_methods_repository.dart';
import 'proposals_event.dart';
import 'proposals_state.dart';

/// BLoC para gerenciamento de estado das propostas
class ProposalsBloc extends Bloc<ProposalsEvent, ProposalsState> {
  final SaveProposal _saveProposal;
  final GetProposal _getProposal;
  final SearchLocations _searchLocations;
  final GetModalities _getModalities;
  final CreateProposal _createProposal;
  final ProposalsRepository _repository;
  final PaymentMethodsRepository _paymentMethodsRepository;
  final PersonalProposalsApiService _personalProposalsApi =
      sl<PersonalProposalsApiService>();
  final WebSocketService _ws = sl<WebSocketService>();

  Timer? _searchTimer;

  // Estado interno para propostas disponíveis
  List<ProposalResponseDto> _availableProposals = [];
  String? _selectedStatus;
  String? _selectedModality;
  String? _selectedDateFrom;
  String? _selectedDateTo;

  // Subscriptions
  StreamSubscription<bool>? _connSub;

  // ✅ CORREÇÃO: Flag para rastrear desconexão e recarregar quando reconectar
  bool _wasDisconnected = false;

  ProposalsBloc({
    required SaveProposal saveProposal,
    required GetProposal getProposal,
    required SearchLocations searchLocations,
    required GetModalities getModalities,
    required SubmitProposal submitProposal,
    required CreateProposal createProposal,
    required ProposalsRepository repository,
    required PaymentMethodsRepository paymentMethodsRepository,
  }) : _saveProposal = saveProposal,
       _getProposal = getProposal,
       _searchLocations = searchLocations,
       _getModalities = getModalities,
       _createProposal = createProposal,
       _repository = repository,
       _paymentMethodsRepository = paymentMethodsRepository,
       super(const ProposalsInitial()) {
    on<ProposalsInitialize>(_onInitialize);
    on<ProposalsLoadSaved>(_onLoadSaved);
    on<ProposalsNavigateToStep>(_onNavigateToStep);
    on<ProposalsUpdateLocation>(_onUpdateLocation);
    on<ProposalsUpdateDate>(_onUpdateDate);
    on<ProposalsUpdateModality>(_onUpdateModality);
    on<ProposalsUpdateTime>(_onUpdateTime);
    on<ProposalsUpdateDuration>(_onUpdateDuration);
    on<ProposalsUpdatePrice>(_onUpdatePrice);
    on<ProposalsUpdateNotes>(_onUpdateNotes);
    on<ProposalsUpdatePaymentMethod>(_onUpdatePaymentMethod);
    on<ProposalsSetSavedCardCvv>(_onSetSavedCardCvv);
    on<ProposalsLoadPaymentMethods>(_onLoadPaymentMethods);
    on<ProposalsSearchLocations>(_onSearchLocations);
    on<ProposalsSearchLocationsDebounced>(_onSearchLocationsDebounced);
    on<ProposalsLoadModalities>(_onLoadModalities);
    on<ProposalsLoadAvailableTimes>(_onLoadAvailableTimes);
    on<ProposalsSave>(_onSave);
    on<ProposalsSubmit>(_onSubmit);
    on<ProposalsClear>(_onClear);
    on<ProposalsNextStep>(_onNextStep);
    on<ProposalsPreviousStep>(_onPreviousStep);

    // ===== HANDLERS PARA LISTAGEM DE PROPOSTAS (PERSONAL TRAINER) =====
    on<ProposalsLoadAvailable>(_onLoadAvailable);
    on<ProposalsUpdateFilters>(_onUpdateFilters);
    on<ProposalsAcceptProposal>(_onAcceptProposal);
    on<ProposalsUpdateFromWebSocket>(_onUpdateFromWebSocket);
    on<ProposalsConnectWebSocket>(_onConnectWebSocket);
    on<ProposalsDisconnectWebSocket>(_onDisconnectWebSocket);
    on<ProposalsRefresh>(_onRefresh);
  }

  void _sortAvailableProposals() {
    _availableProposals.sort((a, b) {
      final dateCmp = a.trainingDate.compareTo(b.trainingDate);
      if (dateCmp != 0) return dateCmp;
      final timeCmp = a.trainingTime.compareTo(b.trainingTime);
      if (timeCmp != 0) return timeCmp;
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    _connSub?.cancel();
    return super.close();
  }

  Future<void> _onInitialize(
    ProposalsInitialize event,
    Emitter<ProposalsState> emit,
  ) async {
    // Emite imediatamente a etapa 1 para exibir a página sem loading
    emit(
      const ProposalsLoaded(
        proposal: Proposal(createdAt: null),
        currentStep: 1,
        availableModalities: [],
      ),
    );

    try {
      // Em paralelo, carregar dados e atualizar estado
      final savedProposal = await _getProposal();
      final modalities = await _getModalities();
      final proposal = savedProposal ?? const Proposal(createdAt: null);
      final initialStep = proposal.nextStep > 3 ? 3 : proposal.nextStep;

      final loaded = state;
      if (loaded is ProposalsLoaded) {
        emit(
          loaded.copyWith(
            proposal: proposal,
            currentStep: initialStep,
            availableModalities: modalities,
          ),
        );
      }

      // Carregar localizações mockadas por padrão
      add(const ProposalsSearchLocations(''));

      // Se há uma data selecionada, carregar horários
      if (proposal.trainingDate != null) {
        add(ProposalsLoadAvailableTimes(proposal.trainingDate!));
      }
    } catch (e) {
      emit(
        ProposalsError(
          message: 'Erro ao inicializar proposta',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadSaved(
    ProposalsLoadSaved event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    try {
      final savedProposal = await _getProposal();
      if (savedProposal != null) {
        final currentState = state as ProposalsLoaded;
        emit(currentState.copyWith(proposal: savedProposal));
      }
    } catch (e) {
      emit(
        ProposalsError(
          message: 'Erro ao carregar proposta salva',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> _onNavigateToStep(
    ProposalsNavigateToStep event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;

    if (event.step >= 1 && event.step <= currentState.totalSteps) {
      emit(currentState.copyWith(currentStep: event.step));
    }
  }

  Future<void> _onUpdateLocation(
    ProposalsUpdateLocation event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;
    final updatedProposal = currentState.proposal.copyWith(
      locationId: event.location.id,
      locationName: event.location.name,
      locationAddress: event.location.address,
      locationLat: event.location.latitude, // ✅ Salvar coordenadas
      locationLng: event.location.longitude, // ✅ Salvar coordenadas
    );

    emit(currentState.copyWith(proposal: updatedProposal));

    // Registrar uso do local para popularidade
    await PopularLocationsService.addLocationUsage(event.location);

    // Salvar automaticamente
    await _saveProposal(updatedProposal);
  }

  Future<void> _onUpdateDate(
    ProposalsUpdateDate event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;
    final updatedProposal = currentState.proposal.copyWith(
      trainingDate: event.date,
      trainingTime: null, // Limpar horário ao mudar data
    );

    emit(
      currentState.copyWith(
        proposal: updatedProposal,
        availableTimeSlots: [], // Limpar horários antigos
      ),
    );

    // Salvar automaticamente
    await _saveProposal(updatedProposal);

    // Carregar novos horários disponíveis
    add(ProposalsLoadAvailableTimes(event.date));
  }

  Future<void> _onUpdateModality(
    ProposalsUpdateModality event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;
    final updatedProposal = currentState.proposal.copyWith(
      modalityId: event.modality.id,
      modalityName: event.modality.name,
      price:
          event.modality.suggestedPrice, // Sugerir preço baseado na modalidade
    );

    emit(currentState.copyWith(proposal: updatedProposal));

    // Salvar automaticamente
    await _saveProposal(updatedProposal);
  }

  Future<void> _onUpdateTime(
    ProposalsUpdateTime event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;
    final updatedProposal = currentState.proposal.copyWith(
      trainingTime: event.time,
    );

    emit(currentState.copyWith(proposal: updatedProposal));

    // Salvar automaticamente
    await _saveProposal(updatedProposal);
  }

  Future<void> _onUpdateDuration(
    ProposalsUpdateDuration event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;
    final updatedProposal = currentState.proposal.copyWith(
      durationMinutes: event.durationMinutes,
    );

    emit(currentState.copyWith(proposal: updatedProposal));

    // Salvar automaticamente
    await _saveProposal(updatedProposal);
  }

  Future<void> _onUpdatePrice(
    ProposalsUpdatePrice event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;
    final updatedProposal = currentState.proposal.copyWith(price: event.price);

    emit(currentState.copyWith(proposal: updatedProposal));

    // Salvar automaticamente
    await _saveProposal(updatedProposal);
  }

  Future<void> _onUpdateNotes(
    ProposalsUpdateNotes event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;
    final updatedProposal = currentState.proposal.copyWith(
      additionalNotes: event.notes.isEmpty ? null : event.notes,
    );

    emit(currentState.copyWith(proposal: updatedProposal));

    // Salvar automaticamente
    await _saveProposal(updatedProposal);
  }

  Future<void> _onSearchLocations(
    ProposalsSearchLocations event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;

    // Cancelar busca anterior se existir
    _searchTimer?.cancel();

    // Para queries vazias, mostrar locais populares imediatamente
    if (event.query.isEmpty) {
      try {
        final locations = await _searchLocations(event.query);
        emit(
          currentState.copyWith(
            searchedLocations: locations,
            isLoadingLocations: false,
          ),
        );
      } catch (e) {
        emit(currentState.copyWith(isLoadingLocations: false));
      }
      return;
    }

    // Definir loading para queries não vazias
    emit(currentState.copyWith(isLoadingLocations: true));

    // Debounce da busca para queries com texto
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      // Usar add() em vez de emit() para evitar o erro de evento já completado
      add(ProposalsSearchLocationsDebounced(event.query));
    });
  }

  Future<void> _onSearchLocationsDebounced(
    ProposalsSearchLocationsDebounced event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;

    try {
      final locations = await _searchLocations(event.query);
      emit(
        currentState.copyWith(
          searchedLocations: locations,
          isLoadingLocations: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingLocations: false));
      emit(
        ProposalsError(message: 'Erro ao buscar locais', details: e.toString()),
      );
    }
  }

  Future<void> _onLoadModalities(
    ProposalsLoadModalities event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;
    emit(currentState.copyWith(isLoadingModalities: true));

    try {
      final modalities = await _getModalities();
      print('DEBUG: Modalidades carregadas: ${modalities.length}'); // Debug
      print(
        'DEBUG: Primeira modalidade: ${modalities.isNotEmpty ? modalities.first.name : "Nenhuma"}',
      ); // Debug

      emit(
        currentState.copyWith(
          availableModalities: modalities,
          isLoadingModalities: false,
        ),
      );
    } catch (e) {
      print('DEBUG: Erro ao carregar modalidades: $e'); // Debug
      emit(currentState.copyWith(isLoadingModalities: false));
      emit(
        ProposalsError(
          message: 'Erro ao carregar modalidades',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadAvailableTimes(
    ProposalsLoadAvailableTimes event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;
    emit(currentState.copyWith(isLoadingTimeSlots: true));

    try {
      final timeSlots = await _repository.getAvailableTimeSlots(event.date);
      emit(
        currentState.copyWith(
          availableTimeSlots: timeSlots,
          isLoadingTimeSlots: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingTimeSlots: false));
      emit(
        ProposalsError(
          message: 'Erro ao carregar horários disponíveis',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSave(
    ProposalsSave event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;

    try {
      await _saveProposal(currentState.proposal);
    } catch (e) {
      emit(
        ProposalsError(
          message: 'Erro ao salvar proposta',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSubmit(
    ProposalsSubmit event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;
    emit(currentState.copyWith(isSubmitting: true));

    try {
      // Debug: Verificar dados da proposta antes de criar DTO

      // Criar proposta via API
      final response = await _createProposal(currentState.proposal);

      // Verificar se o pagamento foi processado automaticamente
      final paymentStatus = (response.paymentStatus ?? '').toLowerCase();
      final paymentMethod = (response.payment?.method ?? '').toLowerCase();

      if (paymentStatus == 'approved' ||
          paymentStatus == 'authorized' ||
          paymentStatus == 'captured') {
        // Pagamento autorizado/aprovado (custódia quando authorized)
        emit(
          ProposalsSubmitted(
            submittedProposal: currentState.proposal,
            proposalId: response.id,
          ),
        );
      } else if (paymentStatus == 'pending' || paymentStatus == 'in_process') {
        if (paymentMethod == 'pix' && response.payment != null) {
          emit(
            ProposalsPaymentPending(
              submittedProposal: currentState.proposal,
              proposalId: response.id,
              payment: response.payment!,
            ),
          );
          return;
        }

        emit(
          ProposalsError(
            message: 'Pagamento pendente. Confirme o pagamento para continuar.',
          ),
        );
      } else {
        // Outros casos - mostrar erro
        print(
          '❌ [PROPOSALS BLOC] Status de pagamento não reconhecido: ${response.paymentStatus}',
        );
        emit(
          ProposalsError(
            message: 'Erro no processamento do pagamento. Tente novamente.',
            details: 'Status do pagamento: ${response.paymentStatus}',
          ),
        );
      }
    } catch (e) {
      emit(currentState.copyWith(isSubmitting: false));
      emit(
        ProposalsError(
          message: 'Erro ao enviar proposta',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> _onClear(
    ProposalsClear event,
    Emitter<ProposalsState> emit,
  ) async {
    try {
      await _repository.clearProposal();

      // Carregar modalidades para uma nova proposta
      final modalities = await _getModalities();
      print(
        'DEBUG: Modalidades carregadas ao limpar proposta: ${modalities.length}',
      ); // Debug

      emit(
        ProposalsLoaded(
          proposal: const Proposal(),
          currentStep: 1,
          availableModalities: modalities, // Incluir modalidades
        ),
      );
    } catch (e) {
      emit(
        ProposalsError(
          message: 'Erro ao limpar proposta',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> _onNextStep(
    ProposalsNextStep event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;

    if (currentState.canGoToNextStep) {
      emit(currentState.copyWith(currentStep: currentState.currentStep + 1));
    }
  }

  Future<void> _onPreviousStep(
    ProposalsPreviousStep event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;

    if (currentState.canGoToPreviousStep) {
      emit(currentState.copyWith(currentStep: currentState.currentStep - 1));
    }
  }

  Future<void> _onUpdatePaymentMethod(
    ProposalsUpdatePaymentMethod event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;

    final currentState = state as ProposalsLoaded;

    final selectedMethod = currentState.availablePaymentMethods.firstWhere(
      (method) => method.id == event.paymentMethodId,
    );

    final updatedProposal = currentState.proposal.copyWith(
      paymentMethodId: event.paymentMethodId,
      paymentMethodName: event.paymentMethodName,
      selectedPaymentMethod: selectedMethod,
      // Limpar qualquer dado temporário de pagamento ao trocar de método/cartão.
      clearSavedCardCvv: true,
    );

    print('💳 [PROPOSALS BLOC] Método de pagamento selecionado:');
    print('  - ID: ${selectedMethod.id}');
    print('  - Type: ${selectedMethod.type}');

    emit(currentState.copyWith(proposal: updatedProposal));
  }

  Future<void> _onSetSavedCardCvv(
    ProposalsSetSavedCardCvv event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsLoaded) return;
    final currentState = state as ProposalsLoaded;
    final updatedProposal = currentState.proposal.copyWith(
      savedCardCvv: event.cvv,
    );
    emit(currentState.copyWith(proposal: updatedProposal));
  }

  Future<void> _onLoadPaymentMethods(
    ProposalsLoadPaymentMethods event,
    Emitter<ProposalsState> emit,
  ) async {
    // Se não estiver no estado correto, aguardar um pouco e tentar novamente
    if (state is! ProposalsLoaded) {
      print(
        '⚠️ [PROPOSALS_BLOC] Tentando carregar métodos de pagamento antes do estado estar pronto',
      );
      // Aguardar um pouco e tentar novamente
      await Future.delayed(const Duration(milliseconds: 100));
      if (state is! ProposalsLoaded) {
        print(
          '❌ [PROPOSALS_BLOC] Estado ainda não está pronto, ignorando carregamento de métodos de pagamento',
        );
        return;
      }
    }

    final currentState = state as ProposalsLoaded;
    final stripeCardMethod = _buildStripeCardPaymentMethod();
    final pixMethod = _buildPixPaymentMethod();
    final existingMethods = currentState.availablePaymentMethods
        .where(
          (method) =>
              method.id != stripeCardMethod.id && method.id != pixMethod.id,
        )
        .toList();
    final provisionalMethods = <PaymentMethod>[
      stripeCardMethod,
      pixMethod,
      ...existingMethods,
    ];

    Proposal proposalWithDefaultMethod = currentState.proposal;
    if (proposalWithDefaultMethod.paymentMethodId == null ||
        proposalWithDefaultMethod.paymentMethodId!.isEmpty) {
      proposalWithDefaultMethod = proposalWithDefaultMethod.copyWith(
        paymentMethodId: stripeCardMethod.id,
        paymentMethodName: _getPaymentMethodDisplayName(stripeCardMethod),
        selectedPaymentMethod: stripeCardMethod,
      );
    }

    try {
      print('💳 [PROPOSALS_BLOC] Carregando métodos de pagamento...');
      // Exibe a opção de cartão imediatamente para evitar bloqueio visual em caso de API lenta.
      emit(
        currentState.copyWith(
          proposal: proposalWithDefaultMethod,
          availablePaymentMethods: provisionalMethods,
          isLoadingPaymentMethods: true,
        ),
      );

      // Carregar cartões salvos via API
      final paymentSettings = await _paymentMethodsRepository
          .getStudentPaymentMethods()
          .timeout(const Duration(seconds: 15));
      final savedCards = paymentSettings.savedCards;
      final savedCardsWithoutDup = savedCards
          .where((method) => method.id != stripeCardMethod.id)
          .toList();

      final allMethods = <PaymentMethod>[
        ...savedCardsWithoutDup,
        stripeCardMethod,
        pixMethod,
      ];

      final latestState = state is ProposalsLoaded
          ? state as ProposalsLoaded
          : currentState;
      final selectedMethodId = latestState.proposal.paymentMethodId;
      PaymentMethod? selectedMethod;
      if (selectedMethodId != null) {
        for (final method in allMethods) {
          if (method.id == selectedMethodId) {
            selectedMethod = method;
            break;
          }
        }
      }
      final shouldPreferSavedCard =
          savedCardsWithoutDup.isNotEmpty &&
          (selectedMethodId == null ||
              selectedMethodId.isEmpty ||
              selectedMethodId == stripeCardMethod.id);
      PaymentMethod? defaultSavedCard;
      for (final method in savedCardsWithoutDup) {
        if (method.isDefault) {
          defaultSavedCard = method;
          break;
        }
      }
      final resolvedSelectedMethod = shouldPreferSavedCard
          ? (defaultSavedCard ?? savedCardsWithoutDup.first)
          : (selectedMethod ?? stripeCardMethod);
      final updatedProposal = latestState.proposal.copyWith(
        paymentMethodId: resolvedSelectedMethod.id,
        paymentMethodName: _getPaymentMethodDisplayName(resolvedSelectedMethod),
        selectedPaymentMethod: resolvedSelectedMethod,
      );

      print(
        '💳 [PROPOSALS_BLOC] Métodos disponíveis: ${allMethods.length} (${savedCards.length} cartões salvos)',
      );

      emit(
        latestState.copyWith(
          proposal: updatedProposal,
          availablePaymentMethods: allMethods,
          isLoadingPaymentMethods: false,
        ),
      );
    } on TimeoutException catch (_) {
      print(
        '⚠️ [PROPOSALS_BLOC] Timeout ao carregar métodos de pagamento. Exibindo fallback de cartão.',
      );
      final latestState = state is ProposalsLoaded
          ? state as ProposalsLoaded
          : currentState;
      emit(
        latestState.copyWith(
          proposal: proposalWithDefaultMethod,
          availablePaymentMethods: [stripeCardMethod, pixMethod],
          isLoadingPaymentMethods: false,
        ),
      );
    } catch (e) {
      print('❌ [PROPOSALS_BLOC] Erro ao carregar métodos de pagamento: $e');
      // Mesmo com erro na API, a opção de cartão ainda deve aparecer.
      final latestState = state is ProposalsLoaded
          ? state as ProposalsLoaded
          : currentState;
      emit(
        latestState.copyWith(
          proposal: proposalWithDefaultMethod,
          availablePaymentMethods: [stripeCardMethod, pixMethod],
          isLoadingPaymentMethods: false,
        ),
      );
    }
  }

  PaymentMethod _buildStripeCardPaymentMethod() {
    final now = DateTime.now();
    return PaymentMethod(
      id: 'stripe_payment_sheet',
      type: PaymentMethodType.creditCard,
      isVerified: true,
      isDefault: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  PaymentMethod _buildPixPaymentMethod() {
    final now = DateTime.now();
    return PaymentMethod(
      id: 'pix',
      type: PaymentMethodType.pix,
      isVerified: true,
      isDefault: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  String _getPaymentMethodDisplayName(PaymentMethod method) {
    if (method.id == 'stripe_payment_sheet') {
      return 'Cartão de crédito';
    }
    if (method.id == 'pix') {
      return 'PIX';
    }

    switch (method.type) {
      case PaymentMethodType.creditCard:
        return 'Cartão de crédito';
      case PaymentMethodType.debitCard:
        return 'Cartão de débito';
      case PaymentMethodType.pix:
        return 'PIX';
    }
  }

  // ===== HANDLERS PARA LISTAGEM DE PROPOSTAS (PERSONAL TRAINER) =====

  Future<void> _onLoadAvailable(
    ProposalsLoadAvailable event,
    Emitter<ProposalsState> emit,
  ) async {
    emit(const ProposalsAvailableLoading());

    try {
      final response = await _personalProposalsApi.getProposals(
        page: event.page,
        limit: event.limit,
        status: event.status,
        modality: event.modality,
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
      );

      // ===== Filtro por localização/raio (client-side) =====
      final List<dynamic> rawList =
          (response['proposals'] as List? ?? <dynamic>[]);

      // 1) Recuperar centro/raio preferidos (persistidos na Home) ou usar GPS
      double radiusKm = 47.0; // mesmo padrão da Home
      double? centerLat;
      double? centerLng;
      String? preferredCity; // fallback por cidade

      try {
        final prefs = sl<SharedPreferences>();
        radiusKm = (prefs.getDouble('personal_radius_km') ?? 47.0).clamp(
          0.0,
          80.0,
        );
        centerLat = prefs.getDouble('personal_location_lat');
        centerLng = prefs.getDouble('personal_location_lng');
        final savedAddress = prefs.getString('personal_location_address');
        if (savedAddress != null && savedAddress.isNotEmpty) {
          preferredCity = _extractCityFromAddress(savedAddress);
        }
      } catch (_) {}

      if (centerLat == null || centerLng == null) {
        try {
          final loc = await LocationService.instance.getLocationWithFallback();
          if (loc != null) {
            centerLat = loc.latitude;
            centerLng = loc.longitude;
          }
        } catch (_) {}
      }

      // 2) Aplicar filtro
      final List<dynamic> filteredRaw = rawList.where((raw) {
        try {
          final map = raw as Map<String, dynamic>;
          final targetPersonalId = (map['targetPersonalId'] ?? '')
              .toString()
              .trim();
          final isRecontract = map['isRecontract'] == true;

          // Recontratação direcionada não deve ser escondida por filtro local de raio.
          if (isRecontract || targetPersonalId.isNotEmpty) {
            return true;
          }

          final String locAddress = (map['locationAddress'] ?? '').toString();
          final String locName = (map['locationName'] ?? '').toString();

          // 2.a) Se temos centro + coordenadas da proposta → filtro por raio
          final coords = _extractProposalLatLng(map);
          if (centerLat != null &&
              centerLng != null &&
              coords.lat != null &&
              coords.lng != null) {
            return GeoUtils.isWithinRadiusKm(
              centerLat: centerLat,
              centerLng: centerLng,
              targetLat: coords.lat!,
              targetLng: coords.lng!,
              radiusKm: radiusKm,
            );
          }

          // 2.b) Fallback: filtrar por cidade presente no endereço/nome
          if (preferredCity != null && preferredCity.isNotEmpty) {
            final cityLower = preferredCity.toLowerCase();
            return locAddress.toLowerCase().contains(cityLower) ||
                locName.toLowerCase().contains(cityLower);
          }

          // 2.c) Sem dados suficientes → manter item
          return true;
        } catch (_) {
          return true;
        }
      }).toList();

      final proposals = filteredRaw
          .map(
            (json) =>
                ProposalResponseDto.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      // Ordenar propostas por data (mais próxima primeiro - hoje para futuro)
      proposals.sort((a, b) {
        // Primeiro por data de treino
        final dateCmp = a.trainingDate.compareTo(b.trainingDate);
        if (dateCmp != 0) return dateCmp;

        // Desempate por horário
        final timeCmp = a.trainingTime.compareTo(b.trainingTime);
        if (timeCmp != 0) return timeCmp;

        // Último desempate por data de criação
        return a.createdAt.compareTo(b.createdAt);
      });

      _availableProposals = proposals;
      _sortAvailableProposals();
      _selectedStatus = event.status;
      _selectedModality = event.modality;
      _selectedDateFrom = event.dateFrom;
      _selectedDateTo = event.dateTo;

      emit(
        ProposalsAvailableLoaded(
          proposals: proposals,
          total: response['total'] ?? 0,
          page: response['page'] ?? 1,
          limit: response['limit'] ?? 50,
          selectedStatus: _selectedStatus,
          selectedModality: _selectedModality,
          selectedDateFrom: _selectedDateFrom,
          selectedDateTo: _selectedDateTo,
          isWebSocketConnected: _ws.isConnected,
        ),
      );
    } catch (e) {
      emit(
        ProposalsAvailableError(
          message: e.toString(),
          proposals: _availableProposals,
        ),
      );
    }
  }

  Future<void> _onUpdateFilters(
    ProposalsUpdateFilters event,
    Emitter<ProposalsState> emit,
  ) async {
    _selectedStatus = event.status;
    _selectedModality = event.modality;
    _selectedDateFrom = event.dateFrom;
    _selectedDateTo = event.dateTo;

    // Recarregar propostas com novos filtros
    add(const ProposalsLoadAvailable());
  }

  Future<void> _onAcceptProposal(
    ProposalsAcceptProposal event,
    Emitter<ProposalsState> emit,
  ) async {
    if (state is! ProposalsAvailableLoaded) return;

    final currentState = state as ProposalsAvailableLoaded;

    emit(
      ProposalsOperationInProgress(
        proposals: currentState.proposals,
        operation: 'accept_proposal',
        isWebSocketConnected: _ws.isConnected,
      ),
    );

    try {
      // Aceitar a proposta (validação de conflito será feita no backend)
      await _personalProposalsApi.acceptProposal(event.proposalId);

      // Remover proposta aceita da lista
      final updatedProposals = currentState.proposals
          .where((p) => p.id != event.proposalId)
          .toList();

      _availableProposals = updatedProposals;

      emit(
        ProposalsOperationSuccess(
          proposals: updatedProposals,
          message: 'Proposta aceita com sucesso!',
          isWebSocketConnected: _ws.isConnected,
        ),
      );

      // Atualizar estado após sucesso
      emit(
        ProposalsAvailableLoaded(
          proposals: updatedProposals,
          total: currentState.total - 1,
          page: currentState.page,
          limit: currentState.limit,
          selectedStatus: currentState.selectedStatus,
          selectedModality: currentState.selectedModality,
          selectedDateFrom: currentState.selectedDateFrom,
          selectedDateTo: currentState.selectedDateTo,
          isWebSocketConnected: _ws.isConnected,
        ),
      );
    } catch (e) {
      // Extrair mensagem de erro limpa
      String errorMessage = e.toString();

      // Tratar mensagens específicas
      if (errorMessage.contains('Conflito de horário')) {
        errorMessage = 'Você já tem uma aula agendada para esse horário';
      } else if (errorMessage.contains('Erro ao aceitar proposta:')) {
        // Extrair apenas a mensagem após o prefixo
        final match = RegExp(
          r'Erro ao aceitar proposta: (.+)',
        ).firstMatch(errorMessage);
        if (match != null) {
          errorMessage = match.group(1) ?? 'Erro ao aceitar proposta';
        } else {
          errorMessage = errorMessage.replaceAll('Exception: ', '').trim();
        }
      } else if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceAll('Exception:', '').trim();
      } else if (errorMessage.contains('Erro interno do servidor')) {
        errorMessage = 'Erro interno do servidor. Tente novamente.';
      }

      // Remover prefixos comuns de erro
      errorMessage = errorMessage
          .replaceAll('Exception: ', '')
          .replaceAll('Error: ', '')
          .trim();

      emit(
        ProposalsOperationFailure(
          proposals: currentState.proposals,
          error: errorMessage,
          isWebSocketConnected: _ws.isConnected,
        ),
      );

      // Voltar para o estado loaded após mostrar o erro
      emit(
        ProposalsAvailableLoaded(
          proposals: currentState.proposals,
          total: currentState.total,
          page: currentState.page,
          limit: currentState.limit,
          selectedStatus: currentState.selectedStatus,
          selectedModality: currentState.selectedModality,
          selectedDateFrom: currentState.selectedDateFrom,
          selectedDateTo: currentState.selectedDateTo,
          isWebSocketConnected: _ws.isConnected,
        ),
      );
    }
  }

  Future<void> _onUpdateFromWebSocket(
    ProposalsUpdateFromWebSocket event,
    Emitter<ProposalsState> emit,
  ) async {
    try {
      final action = event.data['action'] as String?;
      final proposalJson = event.data['proposal'] as Map<String, dynamic>?;
      final proposalId = event.data['proposalId'] as String?;

      print('🔍 [PROPOSALS_BLOC] WebSocket event received:');
      print('   - Action: $action');
      print('   - Proposal JSON: $proposalJson');
      print('   - Proposal ID: $proposalId');
      print('   - Full data: ${event.data}');

      // Para eventos de remoção, usar apenas o ID
      if (action == 'proposal_expired' ||
          action == 'proposal_cancelled' ||
          action == 'proposal_matched' ||
          action == 'proposal_accepted') {
        final idToRemove = proposalId ?? proposalJson?['id'] as String?;
        if (idToRemove != null) {
          final beforeCount = _availableProposals.length;
          _availableProposals.removeWhere((p) => p.id == idToRemove);
          _emitWithCurrentState(emit);
          print(
            '➖ [PROPOSALS_BLOC] Proposal removed from list (action=$action): ${beforeCount} -> ${_availableProposals.length} (ID: $idToRemove)',
          );
          return;
        }
      }

      // Para outros eventos, tentar parsing completo
      if (proposalJson == null) {
        print('⚠️ [PROPOSALS_BLOC] Proposal JSON is null, ignoring event');
        return;
      }

      final updatedProposal = ProposalResponseDto.fromJson(proposalJson);
      print('✅ [PROPOSALS_BLOC] Proposal parsed: ${updatedProposal.id}');

      switch (action) {
        case 'proposal_created':
          // Adicionar nova proposta se for pendente
          if (updatedProposal.status == 'pending') {
            _availableProposals.add(updatedProposal);
            _sortAvailableProposals();

            // Emitir estado informativo (sem UI modal) e em seguida atualizar a lista conforme o estado atual
            emit(
              ProposalsNewProposalCreated(
                newProposal: updatedProposal,
                proposals: List<ProposalResponseDto>.from(_availableProposals),
                isWebSocketConnected: _ws.isConnected,
              ),
            );

            // Em seguida manter a UI consistente com o estado atual
            _emitWithCurrentState(emit);
            print('➕ [PROPOSALS_BLOC] Proposal added to list');
          }
          break;
        case 'proposal_updated':
          // Atualizar proposta existente
          final index = _availableProposals.indexWhere(
            (p) => p.id == updatedProposal.id,
          );
          if (index != -1) {
            _availableProposals[index] = updatedProposal;
            _sortAvailableProposals();
            _emitWithCurrentState(emit);
            print('🔄 [PROPOSALS_BLOC] Proposal updated in list');
          }
          break;
        default:
          print('❓ [PROPOSALS_BLOC] Unknown action: $action');
      }
    } catch (e) {
      print('❌ [PROPOSALS_BLOC] Error processing WebSocket event: $e');
      // Ignora erros pontuais de parse
    }
  }

  void _emitWithCurrentState(Emitter<ProposalsState> emit) {
    final current = state;
    if (current is ProposalsAvailableLoaded) {
      emit(
        current.copyWith(
          proposals: List<ProposalResponseDto>.from(_availableProposals),
        ),
      );
      return;
    }
    if (current is ProposalsOperationInProgress) {
      emit(
        ProposalsOperationInProgress(
          proposals: List<ProposalResponseDto>.from(_availableProposals),
          operation: current.operation,
          isWebSocketConnected: _ws.isConnected,
        ),
      );
      return;
    }
    if (current is ProposalsOperationFailure) {
      emit(
        ProposalsOperationFailure(
          proposals: List<ProposalResponseDto>.from(_availableProposals),
          error: current.error,
          isWebSocketConnected: _ws.isConnected,
        ),
      );
      return;
    }
    // Fallback para um estado carregado padrão
    emit(
      ProposalsAvailableLoaded(
        proposals: List<ProposalResponseDto>.from(_availableProposals),
        total: _availableProposals.length,
        page: 1,
        limit: 50,
        selectedStatus: _selectedStatus,
        selectedModality: _selectedModality,
        selectedDateFrom: _selectedDateFrom,
        selectedDateTo: _selectedDateTo,
        isWebSocketConnected: _ws.isConnected,
      ),
    );
  }

  Future<void> _onConnectWebSocket(
    ProposalsConnectWebSocket event,
    Emitter<ProposalsState> emit,
  ) async {
    // Agora usa o RealtimeDataService centralizado
    // O RealtimeDataService já processa eventos de proposal_update e proposal_expired
    // O ProposalsBloc não precisa mais de sua própria conexão WebSocket
    print('📝 [PROPOSALS_BLOC] Usando RealtimeDataService centralizado');

    // Apenas monitorar status de conexão para UI
    _connSub?.cancel();
    _connSub = _ws.connectionStream.listen((connected) {
      if (!isClosed && !emit.isDone) {
        final current = state;
        if (current is ProposalsAvailableLoaded) {
          emit(current.copyWith(isWebSocketConnected: connected));
        }
      }

      // ✅ CORREÇÃO: Quando reconecta após desconexão, recarregar propostas
      if (connected && _wasDisconnected) {
        print(
          '🔄 [PROPOSALS_BLOC] WebSocket reconectado após desconexão - recarregando propostas...',
        );
        _wasDisconnected = false;
        // Aguardar um momento para garantir que a conexão está estável
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!isClosed) {
            add(const ProposalsLoadAvailable());
          }
        });
      } else if (!connected) {
        _wasDisconnected = true;
        print('⚠️ [PROPOSALS_BLOC] WebSocket desconectado');
      }
    });
  }

  Future<void> _onDisconnectWebSocket(
    ProposalsDisconnectWebSocket event,
    Emitter<ProposalsState> emit,
  ) async {
    // Apenas cancelar monitoramento de conexão
    await _connSub?.cancel();

    final current = state;
    if (current is ProposalsAvailableLoaded) {
      emit(current.copyWith(isWebSocketConnected: false));
    }
  }

  Future<void> _onRefresh(
    ProposalsRefresh event,
    Emitter<ProposalsState> emit,
  ) async {
    add(const ProposalsLoadAvailable());
  }
}

/// Extrai latitude/longitude de um JSON de proposta (compatível com diferentes formatos)
({double? lat, double? lng}) _extractProposalLatLng(Map<String, dynamic> map) {
  double? lat;
  double? lng;

  // Chaves planas comuns
  lat = double.tryParse((map['locationLat'] ?? map['lat'] ?? '').toString());
  lng = double.tryParse((map['locationLng'] ?? map['lng'] ?? '').toString());

  // Objeto location aninhado
  final loc = map['location'] as Map<String, dynamic>?;
  if ((lat == null || lng == null) && loc != null) {
    lat = double.tryParse((loc['latitude'] ?? loc['lat'] ?? '').toString());
    lng = double.tryParse((loc['longitude'] ?? loc['lng'] ?? '').toString());
  }

  return (lat: lat, lng: lng);
}

/// Extrai a cidade de um endereço textual comum no Brasil
String _extractCityFromAddress(String address) {
  final cleaned = address.trim();
  if (cleaned.isEmpty) return '';

  // Tentar padrão: "Rua, Bairro - Cidade - UF"
  final dashParts = cleaned.split('-').map((s) => s.trim()).toList();
  if (dashParts.length >= 2) {
    final last = dashParts.last;
    // Se último é UF (2 letras), cidade deve ser o penúltimo (pode conter vírgula)
    if (RegExp(r'^[A-Z]{2}$').hasMatch(last)) {
      final penultimate = dashParts[dashParts.length - 2];
      final penComma = penultimate.split(',');
      return penComma.last.trim();
    }
    // Caso contrário, usar último segmento (após vírgula se houver)
    final lastComma = last.split(',');
    return lastComma.last.trim();
  }

  // Fallback: usar parte após a última vírgula
  final commaParts = cleaned.split(',').map((s) => s.trim()).toList();
  if (commaParts.isNotEmpty) {
    return commaParts.last;
  }
  return cleaned;
}
