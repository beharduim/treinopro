import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/websocket_service.dart';
import '../../data/services/proposals_api_service.dart';
import '../../../../core/di/dependency_injection.dart';
// Para atualizar o card da Home em tempo real ao cancelar
import '../../../home/presentation/bloc/home_bloc.dart' as home_bloc;
import '../../../home/presentation/bloc/home_event.dart' as home_events;

/// Estados do modal de proposta
enum ProposalModalState {
  initial,
  searching,
  matched,
  completed,
  cancelled,
  confirming_cancel,
  confirming_cancel_session,
}

/// Estados do bloc de busca de proposta
abstract class ProposalSearchState extends Equatable {
  const ProposalSearchState();

  @override
  List<Object?> get props => [];

  ProposalModalState get modalState;
}

/// Estado inicial - sem busca ativa
class ProposalSearchInitial extends ProposalSearchState {
  @override
  ProposalModalState get modalState => ProposalModalState.initial;
}

/// Estado de busca ativa
class ProposalSearchActive extends ProposalSearchState {
  final String location;
  final DateTime startTime;
  final Duration elapsedTime;
  final DateTime? trainingDate;
  final String? trainingTime;
  final String? proposalId;

  const ProposalSearchActive({
    required this.location,
    required this.startTime,
    required this.elapsedTime,
    this.trainingDate,
    this.trainingTime,
    this.proposalId,
  });

  @override
  List<Object?> get props => [
    location,
    startTime,
    elapsedTime,
    trainingDate,
    trainingTime,
    proposalId,
  ];

  @override
  ProposalModalState get modalState => ProposalModalState.searching;

  ProposalSearchActive copyWith({
    String? location,
    DateTime? startTime,
    Duration? elapsedTime,
    DateTime? trainingDate,
    String? trainingTime,
    String? proposalId,
  }) {
    return ProposalSearchActive(
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      trainingDate: trainingDate ?? this.trainingDate,
      trainingTime: trainingTime ?? this.trainingTime,
      proposalId: proposalId ?? this.proposalId,
    );
  }
}

/// Estado de match encontrado (personal aceitou)
class ProposalSearchMatched extends ProposalSearchState {
  final String location;
  final Duration totalTime;
  final String personalName;
  final String personalPhoto;
  final double personalRating;
  final String personalResponseTime;
  final DateTime? trainingDate;
  final String? trainingTime;
  final String? proposalId;
  final String? classId; // Adicionado para navegação ao chat
  final String modality;

  const ProposalSearchMatched({
    required this.location,
    required this.totalTime,
    required this.personalName,
    required this.personalPhoto,
    required this.personalRating,
    required this.personalResponseTime,
    required this.modality,
    this.trainingDate,
    this.trainingTime,
    this.proposalId,
    this.classId, // Adicionado para navegação ao chat
  });

  @override
  List<Object?> get props => [
    location,
    totalTime,
    personalName,
    personalPhoto,
    personalRating,
    personalResponseTime,
    modality,
    trainingDate,
    trainingTime,
    proposalId,
    classId, // Adicionado para navegação ao chat
  ];

  @override
  ProposalModalState get modalState => ProposalModalState.matched;
}

/// Estado de busca finalizada (encontrou profissional)
class ProposalSearchCompleted extends ProposalSearchState {
  final String location;
  final Duration totalTime;

  const ProposalSearchCompleted({
    required this.location,
    required this.totalTime,
  });

  @override
  List<Object?> get props => [location, totalTime];

  @override
  ProposalModalState get modalState => ProposalModalState.completed;
}

/// Eventos do bloc de busca de proposta
abstract class ProposalSearchEvent extends Equatable {
  const ProposalSearchEvent();

  @override
  List<Object?> get props => [];
}

/// Iniciar busca por profissional
class StartProposalSearch extends ProposalSearchEvent {
  final String location;
  final DateTime? trainingDate;
  final String? trainingTime;
  final String? proposalId;

  StartProposalSearch({
    required this.location,
    this.trainingDate,
    this.trainingTime,
    this.proposalId,
  });

  @override
  List<Object?> get props => [location, trainingDate, trainingTime, proposalId];
}

/// Atualizar tempo decorrido
class UpdateSearchTime extends ProposalSearchEvent {
  final Duration elapsedTime;

  const UpdateSearchTime({required this.elapsedTime});

  @override
  List<Object?> get props => [elapsedTime];
}

/// Match encontrado (personal aceitou)
class MatchFound extends ProposalSearchEvent {
  final String personalName;
  final String personalPhoto;
  final double personalRating;
  final String personalResponseTime;

  const MatchFound({
    required this.personalName,
    required this.personalPhoto,
    required this.personalRating,
    required this.personalResponseTime,
  });

  @override
  List<Object?> get props => [
    personalName,
    personalPhoto,
    personalRating,
    personalResponseTime,
  ];
}

/// Finalizar busca (encontrou profissional)
class CompleteProposalSearch extends ProposalSearchEvent {
  CompleteProposalSearch();
}

/// Cancelar busca
class CancelProposalSearch extends ProposalSearchEvent {
  final String? proposalId;

  const CancelProposalSearch({this.proposalId});

  @override
  List<Object?> get props => [proposalId];
}

/// Mostrar confirmação de cancelamento
class ShowCancelConfirmation extends ProposalSearchEvent {
  const ShowCancelConfirmation();
}

/// Voltar da confirmação de cancelamento
class BackFromCancelConfirmation extends ProposalSearchEvent {
  const BackFromCancelConfirmation();
}

/// Mostrar confirmação de cancelamento de sessão (após match)
class ShowSessionCancelConfirmation extends ProposalSearchEvent {
  const ShowSessionCancelConfirmation();
}

/// Voltar da confirmação de cancelamento de sessão
class BackFromSessionCancelConfirmation extends ProposalSearchEvent {
  const BackFromSessionCancelConfirmation();
}

/// Cancelar sessão (após match)
class CancelSession extends ProposalSearchEvent {
  const CancelSession();
}

/// Evento para resetar o estado do bloc
class ResetProposalSearch extends ProposalSearchEvent {
  const ResetProposalSearch();
}

/// Evento para atualizar classId quando aula for criada
class UpdateClassId extends ProposalSearchEvent {
  final String classId;

  const UpdateClassId({required this.classId});

  @override
  List<Object?> get props => [classId];
}

/// Estado de busca cancelada
class ProposalSearchCancelled extends ProposalSearchState {
  final String location;
  final Duration totalTime;

  const ProposalSearchCancelled({
    required this.location,
    required this.totalTime,
  });

  @override
  List<Object?> get props => [location, totalTime];

  @override
  ProposalModalState get modalState => ProposalModalState.cancelled;
}

/// Evento para match encontrado via WebSocket
class WebSocketMatchFound extends ProposalSearchEvent {
  final String personalName;
  final String personalPhoto;
  final double personalRating;
  final String personalResponseTime;
  final String proposalId;
  final String modality;
  final String? classId; // ✅ ADICIONADO: classId para navegação ao chat

  const WebSocketMatchFound({
    required this.personalName,
    required this.personalPhoto,
    required this.personalRating,
    required this.personalResponseTime,
    required this.proposalId,
    required this.modality,
    this.classId, // ✅ ADICIONADO: classId opcional
  });

  @override
  List<Object?> get props => [
    personalName,
    personalPhoto,
    personalRating,
    personalResponseTime,
    proposalId,
    modality,
    classId, // ✅ ADICIONADO
  ];
}

/// Estado de confirmação de cancelamento
class ProposalSearchConfirmingCancel extends ProposalSearchState {
  final String location;
  final Duration elapsedTime;
  final DateTime? trainingDate;
  final String? trainingTime;
  final String? proposalId;

  const ProposalSearchConfirmingCancel({
    required this.location,
    required this.elapsedTime,
    this.trainingDate,
    this.trainingTime,
    this.proposalId,
  });

  @override
  List<Object?> get props => [
    location,
    elapsedTime,
    trainingDate,
    trainingTime,
    proposalId,
  ];

  @override
  ProposalModalState get modalState => ProposalModalState.confirming_cancel;
}

/// Estado de confirmação de cancelamento de sessão (após match)
class ProposalSearchConfirmingSessionCancel extends ProposalSearchState {
  final String personalName;
  final String personalImageUrl;
  final double rating;
  final String location;
  final DateTime? trainingDate;
  final String? trainingTime;
  final String? proposalId;

  const ProposalSearchConfirmingSessionCancel({
    required this.personalName,
    required this.personalImageUrl,
    required this.rating,
    required this.location,
    this.trainingDate,
    this.trainingTime,
    this.proposalId,
  });

  @override
  List<Object?> get props => [
    personalName,
    personalImageUrl,
    rating,
    location,
    trainingDate,
    trainingTime,
    proposalId,
  ];

  @override
  ProposalModalState get modalState =>
      ProposalModalState.confirming_cancel_session;
}

/// Bloc para gerenciar o estado da busca de proposta
class ProposalSearchBloc
    extends Bloc<ProposalSearchEvent, ProposalSearchState> {
  Timer? _timer;
  Timer? _matchTimer;
  final ProposalsApiService _proposalsApiService = sl<ProposalsApiService>();

  ProposalSearchBloc() : super(ProposalSearchInitial()) {
    on<StartProposalSearch>(_onStartSearch);
    on<UpdateSearchTime>(_onUpdateTime);
    on<MatchFound>(_onMatchFound);
    on<CompleteProposalSearch>(_onCompleteSearch);
    on<CancelProposalSearch>(_onCancelSearch);
    on<ShowCancelConfirmation>(_onShowCancelConfirmation);
    on<BackFromCancelConfirmation>(_onBackFromCancelConfirmation);
    on<ShowSessionCancelConfirmation>(_onShowSessionCancelConfirmation);
    on<BackFromSessionCancelConfirmation>(_onBackFromSessionCancelConfirmation);
    on<CancelSession>(_onCancelSession);
    on<ResetProposalSearch>(_onResetSearch);
    on<WebSocketMatchFound>(_onWebSocketMatchFound);
    on<UpdateClassId>(_onUpdateClassId);
  }

  void _onStartSearch(
    StartProposalSearch event,
    Emitter<ProposalSearchState> emit,
  ) {
    final startTime = DateTime.now();

    emit(
      ProposalSearchActive(
        location: event.location,
        startTime: startTime,
        elapsedTime: Duration.zero,
        trainingDate: event.trainingDate,
        trainingTime: event.trainingTime,
        proposalId: event.proposalId,
      ),
    );

    // Iniciar timer para atualizar o tempo a cada segundo
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsedTime = DateTime.now().difference(startTime);
      add(UpdateSearchTime(elapsedTime: elapsedTime));
    });

    // Conectar ao WebSocket para escutar matches reais
    _connectWebSocket();
  }

  void _onUpdateTime(
    UpdateSearchTime event,
    Emitter<ProposalSearchState> emit,
  ) {
    if (state is ProposalSearchActive) {
      final currentState = state as ProposalSearchActive;

      // Verificar se atingiu o limite de 3 minutos (180 segundos)
      if (event.elapsedTime.inSeconds >= 180) {
        _timer?.cancel();
        print(
          '⏰ [PROPOSAL_SEARCH] Timer de 3 minutos expirado - emitindo evento WebSocket',
        );
        print(
          '⏰ [PROPOSAL_SEARCH] Tempo decorrido: ${event.elapsedTime.inSeconds} segundos',
        );
        print('⏰ [PROPOSAL_SEARCH] ProposalId: ${currentState.proposalId}');

        // Emitir evento WebSocket para notificar o backend
        _emitSearchTimeoutEvent(currentState.proposalId);

        // Mudar para estado inicial (modal fechará)
        print('⏰ [PROPOSAL_SEARCH] Emitindo ProposalSearchInitial()');
        emit(ProposalSearchInitial());
        return;
      }

      emit(currentState.copyWith(elapsedTime: event.elapsedTime));
    }
  }

  /// Emite evento WebSocket quando timer de busca expira
  void _emitSearchTimeoutEvent(String? proposalId) {
    if (proposalId == null) {
      print(
        '⚠️ [PROPOSAL_SEARCH] ProposalId é null, não é possível emitir evento de timeout',
      );
      return;
    }

    try {
      final ws = sl<WebSocketService>();
      if (ws.isConnected) {
        ws.emit('proposal_search_timeout', {
          'proposalId': proposalId,
          'reason': 'Timer de busca expirado (3 minutos)',
          'timestamp': DateTime.now().toIso8601String(),
        });
        print(
          '📡 [PROPOSAL_SEARCH] Evento proposal_search_timeout emitido para proposta $proposalId',
        );
      } else {
        print(
          '❌ [PROPOSAL_SEARCH] WebSocket não conectado, não é possível emitir evento',
        );
      }
    } catch (error) {
      print('❌ [PROPOSAL_SEARCH] Erro ao emitir evento de timeout: $error');
    }
  }

  void _onMatchFound(MatchFound event, Emitter<ProposalSearchState> emit) {
    if (state is ProposalSearchActive) {
      final currentState = state as ProposalSearchActive;
      _timer?.cancel();
      _matchTimer?.cancel();

      emit(
        ProposalSearchMatched(
          location: currentState.location,
          totalTime: currentState.elapsedTime,
          personalName: event.personalName,
          personalPhoto: event.personalPhoto,
          personalRating: event.personalRating,
          personalResponseTime: event.personalResponseTime,
          modality: 'Personal Training', // Fallback para casos antigos
          trainingDate: currentState.trainingDate,
          trainingTime: currentState.trainingTime,
          proposalId: currentState.proposalId,
          classId: null, // Será preenchido quando a aula for criada
        ),
      );
    }
  }

  void _onWebSocketMatchFound(
    WebSocketMatchFound event,
    Emitter<ProposalSearchState> emit,
  ) {
    print(
      '🎯 [PROPOSAL_SEARCH] WebSocketMatchFound recebido | estado atual: ${state.runtimeType}',
    );
    print(
      '🎯 [PROPOSAL_SEARCH] Dados do evento: personalName=${event.personalName} | personalPhoto=${event.personalPhoto} | personalRating=${event.personalRating} | proposalId=${event.proposalId}',
    );

    if (state is ProposalSearchActive) {
      final currentState = state as ProposalSearchActive;
      print(
        '✅ [PROPOSAL_SEARCH] Estado ativo encontrado, transicionando para matched',
      );
      _timer?.cancel();
      _matchTimer?.cancel();

      emit(
        ProposalSearchMatched(
          location: currentState.location,
          totalTime: currentState.elapsedTime,
          personalName: event.personalName,
          personalPhoto: event.personalPhoto,
          personalRating: event.personalRating,
          personalResponseTime: event.personalResponseTime,
          modality: event.modality,
          trainingDate: currentState.trainingDate,
          trainingTime: currentState.trainingTime,
          proposalId: event.proposalId,
          classId:
              event.classId, // ✅ CORREÇÃO: Usar classId do evento se disponível
        ),
      );

      print(
        '✅ [PROPOSAL_SEARCH] Estado ProposalSearchMatched emitido com sucesso',
      );

      // Notificar HomeBloc sobre o match para sincronizar o card
      try {
        final homeBloc = sl<home_bloc.HomeBloc>();
        homeBloc.add(
          home_events.ProposalMatched({
            'location': currentState.location,
            'date':
                currentState.trainingDate?.toIso8601String() ??
                DateTime.now().toIso8601String(),
            'time': currentState.trainingTime ?? '00:00',
            'personalName': event.personalName,
            'personalImage': event.personalPhoto,
          }),
        );
        print('🔄 [PROPOSAL_SEARCH] Notificando HomeBloc sobre match');
      } catch (e) {
        print('❌ [PROPOSAL_SEARCH] Erro ao notificar HomeBloc: $e');
      }
    } else if (state is ProposalSearchMatched) {
      // Se já estamos em matched, atualizar os dados com informações mais completas
      final currentState = state as ProposalSearchMatched;
      print(
        '🔄 [PROPOSAL_SEARCH] Estado já é matched, atualizando dados com informações do WebSocket',
      );

      // ✅ CORREÇÃO: Sempre usar dados novos se não forem fallbacks genéricos
      final newPersonalName =
          event.personalName.isNotEmpty &&
              event.personalName != 'Personal Trainer' &&
              event.personalName != 'Personal'
          ? event.personalName
          : currentState.personalName;

      final newPersonalResponseTime =
          event.personalResponseTime.isNotEmpty &&
              event.personalResponseTime != 'Rápido'
          ? event.personalResponseTime
          : currentState.personalResponseTime;

      final newPersonalPhoto = event.personalPhoto.isNotEmpty
          ? event.personalPhoto
          : currentState.personalPhoto;
      final newPersonalRating = event.personalRating > 0.0
          ? event.personalRating
          : currentState.personalRating;

      print(
        '🔄 [PROPOSAL_SEARCH] Dados atualizados: name="$newPersonalName" (era "${currentState.personalName}")',
      );
      print(
        '🔄 [PROPOSAL_SEARCH] Dados atualizados: responseTime="$newPersonalResponseTime" (era "${currentState.personalResponseTime}")',
      );
      print(
        '🔄 [PROPOSAL_SEARCH] Dados atualizados: photo="$newPersonalPhoto" (era "${currentState.personalPhoto}")',
      );
      print(
        '🔄 [PROPOSAL_SEARCH] Dados atualizados: rating=$newPersonalRating (era ${currentState.personalRating})',
      );

      emit(
        ProposalSearchMatched(
          location: currentState.location,
          totalTime: currentState.totalTime,
          personalName: newPersonalName,
          personalPhoto: newPersonalPhoto,
          personalRating: newPersonalRating,
          personalResponseTime: newPersonalResponseTime,
          modality: event.modality.isNotEmpty
              ? event.modality
              : currentState.modality,
          trainingDate: currentState.trainingDate,
          trainingTime: currentState.trainingTime,
          proposalId: event.proposalId.isNotEmpty
              ? event.proposalId
              : currentState.proposalId,
          classId: currentState.classId,
        ),
      );

      print(
        '✅ [PROPOSAL_SEARCH] Estado ProposalSearchMatched atualizado com dados do WebSocket',
      );
    } else if (state is ProposalSearchInitial) {
      // ✅ CORREÇÃO: Aceitar match mesmo em estado Initial (modal pode ter sido fechado/resetado)
      print(
        '🔧 [PROPOSAL_SEARCH] Estado é Initial, mas match chegou - criando estado matched do zero',
      );
      _timer?.cancel();
      _matchTimer?.cancel();

      emit(
        ProposalSearchMatched(
          location: 'Localização', // Fallback - será atualizado pelo modal
          totalTime: Duration.zero,
          personalName: event.personalName,
          personalPhoto: event.personalPhoto,
          personalRating: event.personalRating,
          personalResponseTime: event.personalResponseTime,
          modality: event.modality,
          trainingDate: null,
          trainingTime: null,
          proposalId: event.proposalId,
          classId:
              event.classId, // ✅ CORREÇÃO: Usar classId do evento se disponível
        ),
      );

      print('✅ [PROPOSAL_SEARCH] Estado ProposalSearchMatched criado do zero');

      // Notificar HomeBloc sobre o match
      try {
        final homeBloc = sl<home_bloc.HomeBloc>();
        homeBloc.add(
          home_events.ProposalMatched({
            'location': 'Localização',
            'date': DateTime.now().toIso8601String(),
            'time': '00:00',
            'personalName': event.personalName,
            'personalImage': event.personalPhoto,
          }),
        );
        print(
          '🔄 [PROPOSAL_SEARCH] Notificando HomeBloc sobre match (estado Initial)',
        );
      } catch (e) {
        print('❌ [PROPOSAL_SEARCH] Erro ao notificar HomeBloc: $e');
      }
    } else {
      print(
        '⚠️ [PROPOSAL_SEARCH] Estado não esperado (${state.runtimeType}), ignorando WebSocketMatchFound',
      );
    }
  }

  void _connectWebSocket() {
    // Agora usa o RealtimeDataService centralizado
    // O RealtimeDataService já processa eventos de proposal_update e notifica o HomeBloc
    // O ProposalSearchBloc não precisa mais de sua própria conexão WebSocket
    debugPrint('🔍 [PROPOSAL_SEARCH] Usando RealtimeDataService centralizado');
  }

  void _onCompleteSearch(
    CompleteProposalSearch event,
    Emitter<ProposalSearchState> emit,
  ) {
    if (state is ProposalSearchActive) {
      final currentState = state as ProposalSearchActive;
      _timer?.cancel();
      _matchTimer?.cancel();
      emit(
        ProposalSearchCompleted(
          location: currentState.location,
          totalTime: currentState.elapsedTime,
        ),
      );
    }
  }

  void _onCancelSearch(
    CancelProposalSearch event,
    Emitter<ProposalSearchState> emit,
  ) async {
    print('🛑 [PROPOSAL_SEARCH] Cancelando busca...');
    print('🛑 [PROPOSAL_SEARCH] Estado atual: ${state.runtimeType}');

    _timer?.cancel();
    _matchTimer?.cancel();

    String? proposalId = event.proposalId;
    String location = 'Localização';
    Duration totalTime = Duration.zero;

    if (state is ProposalSearchActive) {
      final currentState = state as ProposalSearchActive;
      proposalId ??= currentState.proposalId;
      location = currentState.location;
      totalTime = currentState.elapsedTime;
      print('🛑 [PROPOSAL_SEARCH] Cancelando busca ativa');
    } else if (state is ProposalSearchConfirmingCancel) {
      final currentState = state as ProposalSearchConfirmingCancel;
      proposalId ??= currentState.proposalId;
      location = currentState.location;
      totalTime = currentState.elapsedTime;
      print('🛑 [PROPOSAL_SEARCH] Cancelando busca em confirmação');
    } else if (state is ProposalSearchMatched) {
      final currentState = state as ProposalSearchMatched;
      await _cancelProposalFromState(
        currentState,
        emit,
        proposalId: proposalId ?? currentState.proposalId,
        location: currentState.location,
        totalTime: currentState.totalTime,
      );
      return;
    } else if (state is ProposalSearchConfirmingSessionCancel) {
      final currentState = state as ProposalSearchConfirmingSessionCancel;
      await _cancelProposalFromState(
        currentState,
        emit,
        proposalId: proposalId ?? currentState.proposalId,
        location: currentState.location,
        totalTime: Duration.zero,
      );
      return;
    } else {
      print(
        '⚠️ [PROPOSAL_SEARCH] Estado ${state.runtimeType} — cancelamento direto via HomeBloc',
      );
    }

    if (proposalId == null) {
      print('⚠️ [PROPOSAL_SEARCH] ProposalId não disponível para cancelamento');
    }

    try {
      sl<home_bloc.HomeBloc>().add(
        home_events.ProposalCancelled(proposalId: proposalId),
      );
    } catch (_) {}

    emit(
      ProposalSearchCancelled(
        location: location,
        totalTime: totalTime,
      ),
    );
  }

  Future<void> _cancelProposalFromState(
    ProposalSearchState currentState,
    Emitter<ProposalSearchState> emit, {
    String? proposalId,
    required String location,
    required Duration totalTime,
  }) async {
    _timer?.cancel();
    _matchTimer?.cancel();

    try {
      sl<home_bloc.HomeBloc>().add(
        home_events.ProposalCancelled(proposalId: proposalId),
      );
    } catch (_) {}

    emit(
      ProposalSearchCancelled(
        location: location,
        totalTime: totalTime,
      ),
    );
  }

  void _onShowCancelConfirmation(
    ShowCancelConfirmation event,
    Emitter<ProposalSearchState> emit,
  ) {
    if (state is ProposalSearchActive) {
      final currentState = state as ProposalSearchActive;
      emit(
        ProposalSearchConfirmingCancel(
          location: currentState.location,
          elapsedTime: currentState.elapsedTime,
          trainingDate: currentState.trainingDate,
          trainingTime: currentState.trainingTime,
          proposalId: currentState.proposalId,
        ),
      );
    } else if (state is ProposalSearchMatched) {
      final currentState = state as ProposalSearchMatched;
      emit(
        ProposalSearchConfirmingCancel(
          location: currentState.location,
          elapsedTime: currentState.totalTime,
          trainingDate: currentState.trainingDate,
          trainingTime: currentState.trainingTime,
          proposalId: currentState.proposalId,
        ),
      );
    }
  }

  void _onBackFromCancelConfirmation(
    BackFromCancelConfirmation event,
    Emitter<ProposalSearchState> emit,
  ) {
    if (state is ProposalSearchConfirmingCancel) {
      final currentState = state as ProposalSearchConfirmingCancel;
      final startTime = DateTime.now().subtract(currentState.elapsedTime);

      emit(
        ProposalSearchActive(
          location: currentState.location,
          startTime: startTime,
          elapsedTime: currentState.elapsedTime,
          trainingDate: currentState.trainingDate,
          trainingTime: currentState.trainingTime,
          proposalId: currentState.proposalId,
        ),
      );

      // Reiniciar timer para continuar contando o tempo
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final elapsedTime = DateTime.now().difference(startTime);
        add(UpdateSearchTime(elapsedTime: elapsedTime));
      });
    }
  }

  void _onShowSessionCancelConfirmation(
    ShowSessionCancelConfirmation event,
    Emitter<ProposalSearchState> emit,
  ) {
    if (state is ProposalSearchMatched) {
      final currentState = state as ProposalSearchMatched;
      emit(
        ProposalSearchConfirmingSessionCancel(
          personalName: currentState.personalName,
          personalImageUrl: currentState.personalPhoto,
          rating: currentState.personalRating,
          location: currentState.location,
          trainingDate: currentState.trainingDate,
          trainingTime: currentState.trainingTime,
          proposalId: currentState.proposalId,
        ),
      );
    }
  }

  void _onBackFromSessionCancelConfirmation(
    BackFromSessionCancelConfirmation event,
    Emitter<ProposalSearchState> emit,
  ) {
    if (state is ProposalSearchConfirmingSessionCancel) {
      final currentState = state as ProposalSearchConfirmingSessionCancel;
      emit(
        ProposalSearchMatched(
          location: currentState.location,
          totalTime: const Duration(minutes: 1), // Mock duration
          personalName: currentState.personalName,
          personalPhoto: currentState.personalImageUrl,
          personalRating: currentState.rating,
          personalResponseTime: '2 min',
          modality: 'Personal Training', // Fallback para casos antigos
          trainingDate: currentState.trainingDate,
          trainingTime: currentState.trainingTime,
          proposalId: currentState.proposalId,
        ),
      );
    }
  }

  void _onCancelSession(
    CancelSession event,
    Emitter<ProposalSearchState> emit,
  ) async {
    if (state is ProposalSearchConfirmingSessionCancel) {
      final currentState = state as ProposalSearchConfirmingSessionCancel;
      _timer?.cancel();
      _matchTimer?.cancel();

      print('🛑 [PROPOSAL_SEARCH] Cancelando sessão...');
      print('🛑 [PROPOSAL_SEARCH] ProposalId: ${currentState.proposalId}');

      // Atualizar Home imediatamente para remover card de busca ativa
      try {
        sl<home_bloc.HomeBloc>().add(
          home_events.ProposalCancelled(proposalId: currentState.proposalId),
        );
      } catch (_) {}

      // Cancelar proposta via API se tivermos o ID
      if (currentState.proposalId != null) {
        try {
          await _proposalsApiService.cancelProposal(currentState.proposalId!);
          print('✅ [PROPOSAL_SEARCH] Proposta cancelada via API');
        } catch (e) {
          print('❌ [PROPOSAL_SEARCH] Erro ao cancelar proposta via API: $e');
          // Se a proposta já expirou (404), continuar mesmo assim
          if (e.toString().contains('404') ||
              e.toString().contains('Not Found')) {
            print(
              '⚠️ [PROPOSAL_SEARCH] Proposta provavelmente já expirou - continuando cancelamento',
            );
          } else {
            // Para outros erros, continuar mesmo com erro na API
            print(
              '⚠️ [PROPOSAL_SEARCH] Continuando cancelamento apesar do erro',
            );
          }
        }
      } else {
        print(
          '⚠️ [PROPOSAL_SEARCH] ProposalId não disponível para cancelamento',
        );
      }

      emit(
        ProposalSearchCancelled(
          location: currentState.location,
          totalTime: const Duration(minutes: 1), // Mock duration
        ),
      );
    }
  }

  void _onResetSearch(
    ResetProposalSearch event,
    Emitter<ProposalSearchState> emit,
  ) {
    // Cancela qualquer timer ativo
    _timer?.cancel();
    _matchTimer?.cancel();

    // Retorna ao estado inicial
    emit(ProposalSearchInitial());
  }

  void _onUpdateClassId(
    UpdateClassId event,
    Emitter<ProposalSearchState> emit,
  ) {
    // Se estamos no estado matched, atualizar o classId
    if (state is ProposalSearchMatched) {
      final currentState = state as ProposalSearchMatched;
      emit(
        ProposalSearchMatched(
          location: currentState.location,
          totalTime: currentState.totalTime,
          personalName: currentState.personalName,
          personalPhoto: currentState.personalPhoto,
          personalRating: currentState.personalRating,
          personalResponseTime: currentState.personalResponseTime,
          modality: currentState.modality,
          trainingDate: currentState.trainingDate,
          trainingTime: currentState.trainingTime,
          proposalId: currentState.proposalId,
          classId: event.classId, // Atualizar com o classId real
        ),
      );
      print('✅ [PROPOSAL_SEARCH] ClassId atualizado: ${event.classId}');
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _matchTimer?.cancel();
    return super.close();
  }
}
