import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/complete_health_questionnaire_usecase.dart';
import '../../domain/usecases/get_home_state_usecase.dart';
import '../../domain/usecases/update_weekly_mission_progress_usecase.dart';
import '../../domain/entities/home_state.dart' show HomeState, WorkoutCardState;
import '../../domain/repositories/home_repository.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../data/services/auth_service.dart' as local_auth;
import 'home_event.dart';
import 'home_state.dart';

/// BLoC para gerenciar o estado da home
class HomeBloc extends Bloc<HomeEvent, HomeBlocState> {
  final GetHomeStateUseCase getHomeStateUseCase;
  final UpdateWeeklyMissionProgressUseCase updateWeeklyMissionProgressUseCase;
  final CompleteHealthQuestionnaireUseCase completeHealthQuestionnaireUseCase;
  final HomeRepository homeRepository;

  // Flag para evitar chamadas repetidas
  // Timer para expiração da busca (3min)
  Timer? _proposalSearchTimer;

  HomeBloc({
    required this.getHomeStateUseCase,
    required this.updateWeeklyMissionProgressUseCase,
    required this.completeHealthQuestionnaireUseCase,
    required this.homeRepository,
  }) : super(const HomeInitial()) {
    // Eventos existentes
    on<InitializeHome>(_onInitializeHome);
    on<UpdateWeeklyMissionProgress>(_onUpdateWeeklyMissionProgress);
    on<CompleteHealthQuestionnaire>(_onCompleteHealthQuestionnaire);
    on<NavigateToHealthQuestionnaire>(_onNavigateToHealthQuestionnaire);
    on<NavigateToUserProfile>(_onNavigateToUserProfile);
    on<NavigateToWorkouts>(_onNavigateToWorkouts);
    on<NavigateToAchievements>(_onNavigateToAchievements);

    // Eventos do card dinâmico
    on<StartProposalSearch>(_onStartProposalSearch);
    on<StopProposalSearch>(_onStopProposalSearch);
    on<ProposalSearchExpired>(_onProposalSearchExpired);
    on<ProposalMatched>(_onProposalMatched);
    on<ProposalCancelled>(_onProposalCancelled);
    on<ClassScheduled>(_onClassScheduled);
    on<ClassCancelled>(_onClassCancelled);
    on<UpdateWorkoutCard>(_onUpdateWorkoutCard);
    on<LoadWorkoutCardData>(_onLoadWorkoutCardData);

    // Evento de reset (logout)
    on<ResetHome>(_onResetHome);
  }

  Future<void> _onInitializeHome(
    InitializeHome event,
    Emitter<HomeBlocState> emit,
  ) async {
    try {
      print('🏠 [HOME_BLOC] ===== InitializeHome RECEBIDO =====');
      print(
        '🏠 [HOME_BLOC] Estado atual antes de inicializar: ${state.runtimeType}',
      );

      emit(const HomeLoading());
      print('🏠 [HOME_BLOC] Estado mudado para HomeLoading');

      print('🏠 [HOME_BLOC] Chamando getHomeStateUseCase...');
      final homeState = await getHomeStateUseCase();
      print(
        '🏠 [HOME_BLOC] getHomeStateUseCase retornou: userId=${homeState.userId}',
      );

      emit(HomeLoaded(homeState));
      print('🏠 [HOME_BLOC] Estado mudado para HomeLoaded');

      print('🏠 [HOME_BLOC] Disparando LoadWorkoutCardData');
      // Carregar dados do card dinâmico após inicializar a home
      if (!isClosed) {
        add(const LoadWorkoutCardData());
        print('🏠 [HOME_BLOC] LoadWorkoutCardData adicionado');
      }
    } catch (e, stackTrace) {
      print('❌ [HOME_BLOC] Erro ao inicializar: $e');
      print('❌ [HOME_BLOC] Stack trace: $stackTrace');
      
      // Só tentar renovar token se for erro de autenticação (401)
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        print('🔄 [HOME_BLOC] Erro de autenticação detectado, tentando renovar token...');
        try {
          final apiService = sl<ApiService>();
          final refreshSuccess = await apiService.refreshToken();
          
          if (refreshSuccess) {
            print('✅ [HOME_BLOC] Token renovado, tentando carregar novamente...');
            try {
              final homeState = await getHomeStateUseCase();
              emit(HomeLoaded(homeState));
              print('✅ [HOME_BLOC] Home carregada após renovação de token');
              
              if (!isClosed) {
                add(const LoadWorkoutCardData());
              }
              return;
            } catch (retryError) {
              print('❌ [HOME_BLOC] Erro ao carregar após renovação de token: $retryError');
              // Se falhar após renovação, é erro real - deslogar
              throw retryError;
            }
          } else {
            print('❌ [HOME_BLOC] Falha ao renovar token - deslogando usuário');
            throw e; // Re-throw para forçar logout
          }
        } catch (refreshError) {
          print('❌ [HOME_BLOC] Erro ao tentar renovar token: $refreshError');
          // Se falhar ao renovar, forçar logout
          emit(HomeError(e.toString()));
          return;
        }
      }
      
      // Para outros erros, tentar carregar com dados vazios
      print('⚠️ [HOME_BLOC] Erro não relacionado à autenticação, carregando dados vazios');
      final homeState = HomeState(
        userId: '',
        userName: '',
        userLevel: 'Novato',
        userXp: 0,
        isSearchingActive: false,
        workoutCardState: WorkoutCardState.noWorkout,
      );
      
      emit(HomeLoaded(homeState));
      print('🏠 [HOME_BLOC] Estado carregado com dados vazios após erro');
    }
  }

  Future<void> _onUpdateWeeklyMissionProgress(
    UpdateWeeklyMissionProgress event,
    Emitter<HomeBlocState> emit,
  ) async {
    try {
      await updateWeeklyMissionProgressUseCase(event.progress);
      final currentState = state;
      if (currentState is HomeLoaded) {
        final updatedState = currentState.homeState.copyWith(
          weeklyMissionProgress: event.progress,
        );
        emit(HomeLoaded(updatedState));
      }
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onCompleteHealthQuestionnaire(
    CompleteHealthQuestionnaire event,
    Emitter<HomeBlocState> emit,
  ) async {
    try {
      await completeHealthQuestionnaireUseCase();

      // Atualizar o estado da home para refletir que o questionário foi completado
      final currentState = state;
      if (currentState is HomeLoaded) {
        final updatedState = currentState.homeState.copyWith(
          hasHealthQuestionnaire: false,
        );
        emit(HomeLoaded(updatedState));
      }
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  void _onNavigateToHealthQuestionnaire(
    NavigateToHealthQuestionnaire event,
    Emitter<HomeBlocState> emit,
  ) {
    // A navegação será feita diretamente pelo botão, não precisa implementar aqui
  }

  void _onNavigateToUserProfile(
    NavigateToUserProfile event,
    Emitter<HomeBlocState> emit,
  ) {
    // TODO: Implementar navegação para o perfil do usuário
  }

  void _onNavigateToWorkouts(
    NavigateToWorkouts event,
    Emitter<HomeBlocState> emit,
  ) {
    // TODO: Implementar navegação para os treinos
  }

  void _onNavigateToAchievements(
    NavigateToAchievements event,
    Emitter<HomeBlocState> emit,
  ) {
    // TODO: Implementar navegação para as conquistas
  }

  // ===== HANDLERS DO CARD DINÂMICO =====

  /// Inicia busca de profissional (modal ativo)
  Future<void> _onStartProposalSearch(
    StartProposalSearch event,
    Emitter<HomeBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      // TEMPORARIAMENTE mostrar busca ativa (independente do estado anterior)
      emit(
        HomeLoaded(
          currentState.homeState.copyWith(
            workoutCardState: WorkoutCardState.searchingProfessional,
            workoutCardLocation: event.location,
            workoutCardDate: event.trainingDate,
            workoutCardTime: event.trainingTime,
            isSearchingActive: true,
            workoutCardData: {'startTime': DateTime.now().toIso8601String()},
          ),
        ),
      );

      // Iniciar/Resetar timer de 3 minutos
      _proposalSearchTimer?.cancel();
      _proposalSearchTimer = Timer(const Duration(minutes: 3), () {
        if (!isClosed) add(const ProposalSearchExpired());
      });
    }
  }

  /// Para busca de profissional
  Future<void> _onStopProposalSearch(
    StopProposalSearch event,
    Emitter<HomeBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      // Fechou o modal, mas a busca continua ativa durante a janela de 3 minutos
      // Mantemos isSearchingActive = true e apenas pedimos para o card refletir o estado de busca
      if (!isClosed) add(const UpdateWorkoutCard());
    }
  }

  /// Busca expirou (3 minutos)
  Future<void> _onProposalSearchExpired(
    ProposalSearchExpired event,
    Emitter<HomeBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      // Cancelar timer local se ainda ativo
      _proposalSearchTimer?.cancel();
      _proposalSearchTimer = null;

      // Limpar isSearchingActive - a proposta agora é "pending" no backend
      emit(
        HomeLoaded(currentState.homeState.copyWith(isSearchingActive: false)),
      );

      print(
        '⏰ [PROPOSAL_SEARCH_EXPIRED] isSearchingActive definido como false',
      );

      // Recalcular qual card mostrar - LoadWorkoutCardData será chamado pelo RealtimeDataService
      if (!isClosed) add(const UpdateWorkoutCard());
    }
  }

  /// Proposta foi aceita por profissional
  Future<void> _onProposalMatched(
    ProposalMatched event,
    Emitter<HomeBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      print(
        '🤝 [HOME_BLOC] ProposalMatched recebido - armazenando dados do personal',
      );
      print('🤝 [HOME_BLOC] Dados do personal recebidos: ${event.matchData}');

      // Encerrar timer local de busca
      _proposalSearchTimer?.cancel();
      _proposalSearchTimer = null;

      // ✅ CORREÇÃO: Armazenar dados do personal no workoutCardData para renderização imediata
      final personalData = {
        'personalName': event.matchData['personalName'] ?? 'Personal Trainer',
        'personalImage': event.matchData['personalImage'] ?? '',
        'personalRating': event.matchData['personalRating'] ?? 0.0,
        'personalTimeOnPlatform':
            event.matchData['personalTimeOnPlatform'] ?? 'Rápido',
        'location': event.matchData['location'] ?? 'Localização',
        'date': event.matchData['date'] ?? DateTime.now().toIso8601String(),
        'time': event.matchData['time'] ?? '00:00',
      };

      print('🤝 [HOME_BLOC] Dados do personal armazenados: $personalData');

      // Match encontrado: encerra busca e armazena dados do personal
      emit(
        HomeLoaded(
          currentState.homeState.copyWith(
            isSearchingActive: false,
            workoutCardData: personalData,
          ),
        ),
      );

      print(
        '🤝 [HOME_BLOC] isSearchingActive definido como false, dados do personal armazenados',
      );

      // Recalcular qual card mostrar
      if (!isClosed) add(const UpdateWorkoutCard());
    }
  }

  /// Cancela proposta
  Future<void> _onProposalCancelled(
    ProposalCancelled event,
    Emitter<HomeBlocState> emit,
  ) async {
    print('🗑️ [HOME_BLOC] ===== ProposalCancelled RECEBIDO =====');
    print('🗑️ [HOME_BLOC] ProposalId: ${event.proposalId}');

    final currentState = state;
    print('🗑️ [HOME_BLOC] Estado atual: ${currentState.runtimeType}');

    if (currentState is! HomeLoaded) {
      print('⚠️ [HOME_BLOC] Estado não é HomeLoaded, ignorando');
      return;
    }

    try {
      print(
        '🗑️ [HOME_BLOC] Propostas antes do cancelamento: ${currentState.homeState.pendingProposals.length}',
      );

      // Encerrar timer de busca ao cancelar
      _proposalSearchTimer?.cancel();
      _proposalSearchTimer = null;

      if (event.proposalId != null) {
        print('🗑️ [HOME_BLOC] Cancelando proposta via API...');
        // Cancelar proposta específica via API
        await homeRepository.cancelProposal(event.proposalId!);
        print('🗑️ [HOME_BLOC] Proposta cancelada via API com sucesso');
      }

      // Atualizar estado local removendo a proposta cancelada
      List<Map<String, dynamic>> updatedProposals =
          currentState.homeState.pendingProposals;

      if (event.proposalId != null) {
        updatedProposals = updatedProposals
            .where((proposal) => proposal['id'] != event.proposalId)
            .toList();
      } else {
        updatedProposals = [];
      }

      print(
        '🗑️ [HOME_BLOC] Propostas após o cancelamento: ${updatedProposals.length}',
      );
      print('🗑️ [HOME_BLOC] Emitindo novo estado...');

      emit(
        HomeLoaded(
          currentState.homeState.copyWith(
            isSearchingActive: false, // IMPORTANTE: Parar busca ativa
            pendingProposals: updatedProposals,
          ),
        ),
      );

      print('🗑️ [HOME_BLOC] Novo estado emitido com sucesso');
      print('🗑️ [HOME_BLOC] Disparando UpdateWorkoutCard...');

      // Recalcular qual card mostrar
      if (!isClosed) add(const UpdateWorkoutCard());
    } catch (e) {
      print('❌ DEBUG: Erro ao cancelar proposta: $e');
      // Em caso de erro, apenas atualizar estado local
      List<Map<String, dynamic>> updatedProposals =
          currentState.homeState.pendingProposals;

      if (event.proposalId != null) {
        updatedProposals = updatedProposals
            .where((proposal) => proposal['id'] != event.proposalId)
            .toList();
      } else {
        updatedProposals = [];
      }

      emit(
        HomeLoaded(
          currentState.homeState.copyWith(
            isSearchingActive:
                false, // IMPORTANTE: Parar busca ativa mesmo em caso de erro
            pendingProposals: updatedProposals,
          ),
        ),
      );

      if (!isClosed) add(const UpdateWorkoutCard());
    }
  }

  /// Agenda aula
  Future<void> _onClassScheduled(
    ClassScheduled event,
    Emitter<HomeBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      final updatedClasses = [
        ...currentState.homeState.scheduledClasses,
        event.classData,
      ];

      emit(
        HomeLoaded(
          currentState.homeState.copyWith(scheduledClasses: updatedClasses),
        ),
      );

      // Recalcular qual card mostrar
      if (!isClosed) add(const UpdateWorkoutCard());
    }
  }

  /// Cancela aula
  Future<void> _onClassCancelled(
    ClassCancelled event,
    Emitter<HomeBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    try {
      // Cancelar aula via API
      await homeRepository.cancelClass(event.classId);

      // Atualizar estado local removendo a aula cancelada
      final updatedClasses = currentState.homeState.scheduledClasses
          .where((cls) => cls['id'] != event.classId)
          .toList();

      emit(
        HomeLoaded(
          currentState.homeState.copyWith(scheduledClasses: updatedClasses),
        ),
      );

      // Recalcular qual card mostrar
      if (!isClosed) add(const UpdateWorkoutCard());
    } catch (e) {
      print('❌ DEBUG: Erro ao cancelar aula: $e');
      // Em caso de erro, apenas atualizar estado local
      final updatedClasses = currentState.homeState.scheduledClasses
          .where((cls) => cls['id'] != event.classId)
          .toList();

      emit(
        HomeLoaded(
          currentState.homeState.copyWith(scheduledClasses: updatedClasses),
        ),
      );

      if (!isClosed) add(const UpdateWorkoutCard());
    }
  }

  /// Recalcula qual card mostrar baseado na lógica de prioridades
  Future<void> _onUpdateWorkoutCard(
    UpdateWorkoutCard event,
    Emitter<HomeBlocState> emit,
  ) async {
    print('🔄 [UPDATE_WORKOUT_CARD] ===== UpdateWorkoutCard RECEBIDO =====');

    final currentState = state;
    print('🔄 [UPDATE_WORKOUT_CARD] Estado atual: ${currentState.runtimeType}');

    if (currentState is HomeLoaded) {
      final homeState = currentState.homeState;

      print(
        '🔄 [UPDATE_WORKOUT_CARD] isSearchingActive: ${homeState.isSearchingActive}',
      );
      print(
        '🔄 [UPDATE_WORKOUT_CARD] pendingProposals: ${homeState.pendingProposals.length}',
      );
      print(
        '🔄 [UPDATE_WORKOUT_CARD] scheduledClasses: ${homeState.scheduledClasses.length}',
      );
      print(
        '🔄 [UPDATE_WORKOUT_CARD] workoutCardState atual: ${homeState.workoutCardState}',
      );

      // Se está buscando ativamente, mostrar o card de busca (mesmo com modal fechado)
      if (homeState.isSearchingActive) {
        print('🔄 [UPDATE_WORKOUT_CARD] Mantendo card de busca ativa');
        emit(
          HomeLoaded(
            homeState.copyWith(
              workoutCardState: WorkoutCardState.searchingProfessional,
              // location/date/time já preenchidos em StartProposalSearch
            ),
          ),
        );
        return;
      }

      // Calcular qual card mostrar baseado na prioridade
      print('🔄 [UPDATE_WORKOUT_CARD] Calculando qual card mostrar...');
      final cardInfo = _calculateWorkoutCard(homeState);

      print('🔄 [UPDATE_WORKOUT_CARD] Card calculado: ${cardInfo['state']}');
      print('🔄 [UPDATE_WORKOUT_CARD] Card location: ${cardInfo['location']}');
      print('🔄 [UPDATE_WORKOUT_CARD] Card date: ${cardInfo['date']}');
      print('🔄 [UPDATE_WORKOUT_CARD] Card time: ${cardInfo['time']}');

      // Converter date string para DateTime se necessário
      DateTime? cardDate;
      if (cardInfo['date'] is String) {
        cardDate = DateTime.parse(cardInfo['date'] as String);
      } else if (cardInfo['date'] is DateTime) {
        cardDate = cardInfo['date'] as DateTime;
      }

      print(
        '🔄 [UPDATE_WORKOUT_CARD] Emitindo novo estado com card: ${cardInfo['state']}',
      );

      emit(
        HomeLoaded(
          homeState.copyWith(
            workoutCardState: cardInfo['state'],
            workoutCardLocation: cardInfo['location'],
            workoutCardDate: cardDate,
            workoutCardTime: cardInfo['time'],
            workoutCardData: cardInfo['data'],
          ),
        ),
      );

      print('🔄 [UPDATE_WORKOUT_CARD] Novo estado emitido com sucesso');
    } else {
      print('⚠️ [UPDATE_WORKOUT_CARD] Estado não é HomeLoaded, ignorando');
    }
  }

  /// Carrega dados do card (aulas e propostas)
  Future<void> _onLoadWorkoutCardData(
    LoadWorkoutCardData event,
    Emitter<HomeBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) {
      print('⚠️ [LOAD_CARD] Estado não é HomeLoaded, ignorando');
      return;
    }

    try {
      // Obter ID do usuário real (UUID)
      String? userId = currentState.homeState.userId;
      if (userId == null || userId.isEmpty || userId == 'mock-user-id') {
        try {
          userId = sl<local_auth.AuthService>().currentUserId;
          print('🔐 [LOAD_CARD] userId obtido do AuthService: $userId');
        } catch (e) {
          print('⚠️ [LOAD_CARD] Falha ao obter userId do AuthService: $e');
        }
      }
      if (userId == null || userId.isEmpty) {
        print('❌ [LOAD_CARD] userId indisponível, abortando carregamento do card');
        if (!isClosed) add(const UpdateWorkoutCard());
        return;
      }

      print('🔄 [LOAD_CARD] Iniciando carregamento para userId: $userId');

      // Carregar dados do card
      final cardData = await homeRepository.loadWorkoutCardData(userId);

      print('📦 [LOAD_CARD] Dados recebidos: ${cardData.keys}');

      // Verificar se requer autenticação
      if (cardData['requiresAuth'] == true) {
        print('❌ [LOAD_CARD] Requer autenticação');
        emit(HomeError('Usuário não autenticado. Faça login para continuar.'));
        return;
      }

      // Processar dados carregados
      final scheduledClasses =
          (cardData['scheduledClasses'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final pendingProposals =
          (cardData['pendingProposals'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      print('📊 [LOAD_CARD] Aulas carregadas: ${scheduledClasses.length}');
      print('📊 [LOAD_CARD] Propostas carregadas: ${pendingProposals.length}');

      // VERIFICAR SE OS DADOS SÃO DO USUÁRIO CORRETO
      for (var prop in pendingProposals) {
        final propStudentId = prop['studentId'] as String?;
        final propId = prop['id'] as String?;
        final studentData = prop['student'] as Map<String, dynamic>?;

        print(
          '  📋 Proposta: ID=$propId, Status=${prop['status']}, Data=${prop['date']}',
        );
        print('      studentId: $propStudentId');

        if (studentData != null) {
          print('      student.name: ${studentData['name']}');
          print('      student.email: ${studentData['email']}');
        }

        if (propStudentId != null && propStudentId != userId) {
          print('❌ [LOAD_CARD] ERRO: Proposta com studentId DIFERENTE!');
          print('❌ [LOAD_CARD]   - userId esperado: $userId');
          print('❌ [LOAD_CARD]   - studentId encontrado: $propStudentId');
          print('❌ [LOAD_CARD]   - proposalId: $propId');
        }
      }

      // Log detalhado das aulas
      for (var cls in scheduledClasses) {
        final clsStudentId = cls['studentId'] as String?;
        final clsId = cls['id'] as String?;

        print(
          '  📚 Aula: ID=$clsId, ProposalId=${cls['proposalId']}, Status=${cls['status']}, Data=${cls['date']}',
        );
        print('      studentId: $clsStudentId');

        if (clsStudentId != null && clsStudentId != userId) {
          print('❌ [LOAD_CARD] ERRO: Aula com studentId DIFERENTE!');
          print('❌ [LOAD_CARD]   - userId esperado: $userId');
          print('❌ [LOAD_CARD]   - studentId encontrado: $clsStudentId');
          print('❌ [LOAD_CARD]   - classId: $clsId');
        }
      }

      // Atualizar estado com dados carregados
      final updatedState = currentState.homeState.copyWith(
        scheduledClasses: scheduledClasses,
        pendingProposals: pendingProposals,
        // CORREÇÃO: Se não há propostas pendentes, isSearchingActive deve ser false
        isSearchingActive: pendingProposals.isNotEmpty
            ? currentState.homeState.isSearchingActive
            : false,
      );

      emit(HomeLoaded(updatedState));

      print('✅ [LOAD_CARD] Estado atualizado com sucesso');

      // Recalcular qual card mostrar
      if (!isClosed) add(const UpdateWorkoutCard());
    } catch (e) {
      print('❌ [LOAD_CARD] Erro ao carregar: $e');
      // Em caso de erro, manter estado atual e recalcular
      if (!isClosed) add(const UpdateWorkoutCard());
    }
  }

  /// Calcula qual card mostrar baseado na lógica de prioridades
  Map<String, dynamic> _calculateWorkoutCard(HomeState homeState) {
    print(
      '🎯 DEBUG: Calculando card - Aulas: ${homeState.scheduledClasses.length}, Propostas: ${homeState.pendingProposals.length}',
    );

    // 1. PRIORIDADE MÁXIMA: Aula agendada mais próxima
    if (homeState.scheduledClasses.isNotEmpty) {
      print('🎯 DEBUG: Verificando aulas agendadas...');
      print('🎯 DEBUG: Aulas disponíveis:');
      for (var cls in homeState.scheduledClasses) {
        print(
          '  - ID: ${cls['id']}, ProposalId: ${cls['proposalId']}, Status: ${cls['status']}, Data: ${cls['date']}, Hora: ${cls['time']}',
        );
      }

      final nextClass = _getNextScheduledClass(homeState.scheduledClasses);
      if (nextClass != null) {
        print('🎯 DEBUG: Aula encontrada - retornando scheduledClass');
        print(
          '🎯 DEBUG: Aula selecionada: ID=${nextClass['id']}, Status=${nextClass['status']}',
        );
        return {
          'state': WorkoutCardState.scheduledClass,
          'location': nextClass['location'],
          'date': nextClass['date'],
          'time': nextClass['time'],
          'data': nextClass,
        };
      } else {
        print(
          '⚠️ DEBUG: Aulas agendadas encontradas mas nenhuma próxima válida',
        );
      }
    }

    // 2. PRIORIDADE MÉDIA: Proposta pendente mais próxima
    // 🔧 CORREÇÃO: Filtrar propostas que já viraram aulas OU que não estão com status 'pending'
    final classProposalIds = homeState.scheduledClasses
        .map((cls) => cls['proposalId'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .toSet();

    print('🔧 DEBUG: IDs de propostas que viraram aulas: $classProposalIds');
    print(
      '🔧 DEBUG: Total de propostas pendentes antes do filtro: ${homeState.pendingProposals.length}',
    );

    for (var prop in homeState.pendingProposals) {
      print('🔧 DEBUG: Proposta: ID=${prop['id']}, Status=${prop['status']}');
    }

    final validPendingProposals = homeState.pendingProposals.where((prop) {
      final propId = prop['id'] as String?;
      final propStatus = (prop['status'] as String?)?.toLowerCase() ?? '';

      print('🔧 DEBUG: Analisando proposta $propId com status "$propStatus"');

      // Validar que a proposta está realmente pendente
      final isPendingStatus = propStatus == 'pending';
      if (!isPendingStatus) {
        print(
          '🔧 DEBUG: ❌ Proposta $propId tem status "$propStatus" (não pending), ignorando',
        );
        return false;
      }

      // Validar que a proposta não virou aula
      final isNotConverted =
          propId == null || !classProposalIds.contains(propId);
      if (!isNotConverted) {
        print('🔧 DEBUG: ❌ Proposta $propId já virou aula, ignorando');
        return false;
      }

      print('🔧 DEBUG: ✅ Proposta $propId é válida');
      return true;
    }).toList();

    print(
      '🔧 DEBUG: Total de propostas pendentes válidas após filtro: ${validPendingProposals.length}',
    );

    if (validPendingProposals.isNotEmpty) {
      print(
        '🎯 DEBUG: Verificando ${validPendingProposals.length} propostas pendentes válidas...',
      );

      final nextProposal = _getNextPendingProposal(validPendingProposals);
      if (nextProposal != null) {
        print('🎯 DEBUG: Proposta encontrada - retornando pendingProposal');
        return {
          'state': WorkoutCardState.pendingProposal,
          'location': nextProposal['location'],
          'date': nextProposal['date'],
          'time': nextProposal['time'],
          'data': nextProposal,
        };
      } else {
        print(
          '⚠️ DEBUG: Propostas pendentes encontradas mas nenhuma válida (todas expiradas)',
        );
      }
    }

    // 3. FALLBACK: Sem treino
    print('🎯 DEBUG: Nenhuma aula ou proposta válida - retornando noWorkout');
    final result = {
      'state': WorkoutCardState.noWorkout,
      'location': null,
      'date': null,
      'time': null,
      'data': null,
    };
    return result;
  }

  /// Encontra a próxima aula agendada
  Map<String, dynamic>? _getNextScheduledClass(
    List<Map<String, dynamic>> classes,
  ) {
    final now = DateTime.now();
    print('🔍 DEBUG: Filtrando ${classes.length} aulas...');
    print('🔍 DEBUG: Horário atual: $now');

    final validClasses = classes.where((cls) {
      // Filtrar por status válidos (incluir scheduled, active, pending_confirmation)
      final status = (cls['status'] ?? '').toString().toLowerCase();
      final isValidStatus =
          status == 'scheduled' ||
          status == 'active' ||
          status == 'pending_confirmation' ||
          status == 'pendingconfirmation';

      // Usar data completa (data + hora) para filtragem correta
      final classDateTime = _combineDateTime(cls['date'], cls['time']);

      // ✅ CORREÇÃO: Incluir aulas que estão no horário ou até 10 minutos após o início
      // Isso permite que a aula apareça durante o período de execução
      final tenMinutesAfterClass = classDateTime.add(
        const Duration(minutes: 10),
      );

      // Aulas válidas são:
      // 1. Aulas com status 'active' (sempre mostrar)
      // 2. Aulas futuras (ainda não começaram)
      // 3. Aulas que começaram mas ainda estão dentro da janela de 10 minutos
      final isFutureOrActive =
          status == 'active' ||
          classDateTime.isAfter(now) ||
          (now.isAfter(classDateTime) && now.isBefore(tenMinutesAfterClass));

      print(
        '  - Aula ${cls['id']}: status=$status, isValidStatus=$isValidStatus, isFutureOrActive=$isFutureOrActive, dateTime=$classDateTime, now=$now',
      );

      return isValidStatus && isFutureOrActive;
    }).toList();

    print('🔍 DEBUG: ${validClasses.length} aulas válidas após filtro');

    if (validClasses.isEmpty) {
      return null;
    }

    // ✅ CORREÇÃO: Ordenar por proximidade (data + hora completa)
    validClasses.sort((a, b) {
      DateTime dateTimeA = _combineDateTime(a['date'], a['time']);
      DateTime dateTimeB = _combineDateTime(b['date'], b['time']);

      return dateTimeA.compareTo(dateTimeB);
    });

    print('🔍 DEBUG: Aula selecionada: ${validClasses.first['id']}');

    return validClasses.first;
  }

  /// Combina data e hora para criar DateTime completo
  DateTime _combineDateTime(dynamic date, dynamic time) {
    DateTime dateTime;

    // Converter data
    if (date is String) {
      dateTime = DateTime.parse(date);
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      dateTime = DateTime.now();
    }

    // Converter hora
    String timeStr = time?.toString() ?? '00:00';
    final timeParts = timeStr.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;

    // Criar DateTime completo com data + hora
    return DateTime(dateTime.year, dateTime.month, dateTime.day, hour, minute);
  }

  /// Encontra a próxima proposta pendente
  Map<String, dynamic>? _getNextPendingProposal(
    List<Map<String, dynamic>> proposals,
  ) {
    final now = DateTime.now();

    print('📅 DEBUG: Filtrando ${proposals.length} propostas pendentes');
    print('📅 DEBUG: Data/hora atual: $now');

    final validProposals = proposals.where((prop) {
      // Usar data completa (data + hora) para comparação
      final proposalDateTime = _combineDateTime(prop['date'], prop['time']);
      final isValid = proposalDateTime.isAfter(now);

      print(
        '  - Proposta ${prop['id']}: ${proposalDateTime} (${isValid ? 'VÁLIDA' : 'EXPIRADA'})',
      );

      return isValid;
    }).toList();

    print('📅 DEBUG: ${validProposals.length} propostas válidas encontradas');

    if (validProposals.isEmpty) {
      print('📅 DEBUG: Nenhuma proposta válida - retornando null');
      return null;
    }

    // Ordenar por proximidade (data + hora)
    validProposals.sort((a, b) {
      final dateA = _combineDateTime(a['date'], a['time']);
      final dateB = _combineDateTime(b['date'], b['time']);
      return dateA.compareTo(dateB);
    });

    final selectedProposal = validProposals.first;
    print(
      '📅 DEBUG: Proposta selecionada: ${selectedProposal['id']} - ${selectedProposal['date']}',
    );

    return selectedProposal;
  }

  /// Reseta o estado do HomeBloc (usado no logout)
  Future<void> _onResetHome(
    ResetHome event,
    Emitter<HomeBlocState> emit,
  ) async {
    print('🔄 [HOME_BLOC] Resetando estado...');

    // Cancelar timers
    _proposalSearchTimer?.cancel();
    _proposalSearchTimer = null;

    // Voltar ao estado inicial
    emit(const HomeInitial());

    print('✅ [HOME_BLOC] Estado resetado com sucesso');
  }

  @override
  Future<void> close() async {
    _proposalSearchTimer?.cancel();
    _proposalSearchTimer = null;
    return super.close();
  }
}
