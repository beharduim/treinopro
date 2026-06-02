import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../../domain/entities/gamification_entity.dart';
import 'gamification_event.dart';
import 'gamification_state.dart';

/// BLoC para gerenciar estado de gamificação
class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  final GamificationRepository _gamificationRepository;
  bool _isAutoAssigning = false;
  bool _isRefreshing = false;
  int _refreshGeneration = 0;

  GamificationBloc({
    required GamificationRepository gamificationRepository,
  }) : _gamificationRepository = gamificationRepository,
       super(const GamificationInitial()) {
    
    // Registrar handlers de eventos
    on<InitializeGamification>(_onInitializeGamification);
    on<LoadUserProfile>(_onLoadUserProfile);
    on<LoadGamificationStats>(_onLoadGamificationStats);
    on<LoadUserMissions>(_onLoadUserMissions);
    on<AutoAssignNextMission>(_onAutoAssignNextMission);
    on<UpdateMissionProgress>(_onUpdateMissionProgress);
    on<AddXPEvent>(_onAddXP);
    on<LoadXPHistory>(_onLoadXPHistory);
    on<ProcessClassCompletion>(_onProcessClassCompletion);
    on<ProcessDailyLogin>(_onProcessDailyLogin);
    on<RefreshGamificationData>(_onRefreshGamificationData);
    on<ResetGamificationState>(_onResetGamificationState);
    
    // Evento de reset completo (logout)
    on<ResetGamification>(_onResetGamification);
  }

  // ===== HANDLERS DE EVENTOS =====

  Future<void> _onInitializeGamification(
    InitializeGamification event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      if (state is GamificationLoaded &&
          (state as GamificationLoaded).userProfile.userId == event.userId) {
        print(
          '🧭 MISSION CARD: Gamificação já carregada para ${event.userId}, ignorando reinit',
        );
        return;
      }

      print('🧭 MISSION CARD: Inicializando gamificação para userId: ${event.userId}');
      final hadLoadedState = state is GamificationLoaded;
      if (!hadLoadedState) {
        emit(const GamificationLoading());
      }
      
      // Carregar dados principais em paralelo
      final results = await Future.wait([
        _gamificationRepository.getUserProfile(event.userId),
        _gamificationRepository.getGamificationStats(event.userId),
        _gamificationRepository.getUserMissions(event.userId),
        _gamificationRepository.getXPHistory(event.userId, limit: 10),
      ]);

      final userProfile = results[0] as UserProfile;
      final stats = results[1] as GamificationStats;
      var userMissions = results[2] as List<UserMission>;
      final xpHistory = results[3] as List<XPHistory>;

      final hasActive = userMissions.any((m) => m.isActive && !m.isCompleted);
      if (!hasActive) {
        print(
          '🧭 MISSION CARD: Sem missão ativa — aguardando API (auto-assign) antes de exibir card',
        );
        try {
          _isAutoAssigning = true;
          final assigned =
              await _gamificationRepository.autoAssignNextMission(event.userId);
          if (assigned != null) {
            userMissions = _mergeUserMissions(userMissions, [assigned]);
          } else {
            userMissions =
                await _gamificationRepository.getUserMissions(event.userId);
          }
        } catch (e) {
          print('⚠️ MISSION CARD: auto-assign na init falhou: $e');
        } finally {
          _isAutoAssigning = false;
        }
      }

      emit(GamificationLoaded(
        userProfile: userProfile,
        stats: stats,
        userMissions: userMissions,
        xpHistory: xpHistory,
      ));

      print(
        '🧭 MISSION CARD: Gamificação inicializada - Level: ${userProfile.level}, '
        'Missões: ${userMissions.length}, ativas: '
        '${userMissions.where((m) => m.isActive && !m.isCompleted).length}',
      );
    } catch (e) {
      print('❌ DEBUG: Erro ao inicializar gamificação: $e');
      emit(GamificationError(message: 'Erro ao carregar dados de gamificação: $e'));
    }
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      print('🧭 MISSION CARD: Carregando perfil para userId: ${event.userId}');
      final userProfile = await _gamificationRepository.getUserProfile(event.userId);
      
      final currentState = state;
      print('🧭 MISSION CARD: Estado atual: ${currentState.runtimeType}');
      
      if (currentState is GamificationLoaded) {
        print('🧭 MISSION CARD: Atualizando perfil no estado carregado');
        emit(currentState.copyWith(userProfile: userProfile));
      } else {
        print('🧭 MISSION CARD: Estado não é GamificationLoaded, criando novo estado');
        // Carregar dados completos para criar um estado válido
        final stats = await _gamificationRepository.getGamificationStats(event.userId);
        final userMissions = await _gamificationRepository.getUserMissions(event.userId);
        final xpHistory = await _gamificationRepository.getXPHistory(event.userId, limit: 10);
        
        emit(GamificationLoaded(
          userProfile: userProfile,
          stats: stats,
          userMissions: userMissions,
          xpHistory: xpHistory,
        ));
      }
    } catch (e) {
      print('❌ DEBUG: Erro ao carregar perfil: $e');
      emit(GamificationError(message: 'Erro ao carregar perfil: $e'));
    }
  }

  Future<void> _onLoadGamificationStats(
    LoadGamificationStats event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      print('🧭 MISSION CARD: Carregando estatísticas para userId: ${event.userId}');
      final stats = await _gamificationRepository.getGamificationStats(event.userId);
      
      final currentState = state;
      print('🧭 MISSION CARD: Estado atual: ${currentState.runtimeType}');
      
      if (currentState is GamificationLoaded) {
        print('🧭 MISSION CARD: Atualizando estatísticas no estado carregado');
        emit(currentState.copyWith(stats: stats));
      } else {
        print('🧭 MISSION CARD: Estado não é GamificationLoaded, criando novo estado');
        // Carregar dados completos para criar um estado válido
        final userProfile = await _gamificationRepository.getUserProfile(event.userId);
        final userMissions = await _gamificationRepository.getUserMissions(event.userId);
        final xpHistory = await _gamificationRepository.getXPHistory(event.userId, limit: 10);
        
        emit(GamificationLoaded(
          userProfile: userProfile,
          stats: stats,
          userMissions: userMissions,
          xpHistory: xpHistory,
        ));
      }
    } catch (e) {
      print('❌ DEBUG: Erro ao carregar estatísticas: $e');
      emit(GamificationError(message: 'Erro ao carregar estatísticas: $e'));
    }
  }

  Future<void> _onLoadUserMissions(
    LoadUserMissions event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      print('🧭 MISSION CARD: Carregando missões para userId: ${event.userId}');
      final userMissions = await _gamificationRepository.getUserMissions(
        event.userId,
        status: event.status,
      );
      
      final currentState = state;
      print('🧭 MISSION CARD: Estado atual: ${currentState.runtimeType}');
      
      if (currentState is GamificationLoaded) {
        print('🧭 MISSION CARD: Atualizando missões no estado carregado');
        emit(currentState.copyWith(
          userMissions: _mergeUserMissions(
            currentState.userMissions,
            userMissions,
          ),
        ));
      } else {
        print('🧭 MISSION CARD: Estado não é GamificationLoaded, criando novo estado');
        // Se não há estado carregado, criar um novo
        final userProfile = await _gamificationRepository.getUserProfile(event.userId);
        final stats = await _gamificationRepository.getGamificationStats(event.userId);
        final xpHistory = await _gamificationRepository.getXPHistory(event.userId, limit: 10);
        
        emit(GamificationLoaded(
          userProfile: userProfile,
          stats: stats,
          userMissions: userMissions,
          xpHistory: xpHistory,
        ));
      }

      print('🧭 MISSION CARD: ${userMissions.length} missões carregadas');
    } catch (e) {
      print('❌ DEBUG: Erro ao carregar missões: $e');
      emit(GamificationError(message: 'Erro ao carregar missões: $e'));
    }
  }

  Future<void> _onAutoAssignNextMission(
    AutoAssignNextMission event,
    Emitter<GamificationState> emit,
  ) async {
    // Evitar chamadas simultâneas
    if (_isAutoAssigning) {
      print('🧭 MISSION CARD: Auto-assign já em andamento, ignorando chamada');
      return;
    }

    try {
      _isAutoAssigning = true;
      print('🧭 MISSION CARD: Atribuindo próxima missão automaticamente');
      
      final newMission = await _gamificationRepository.autoAssignNextMission(event.userId);
      
      if (newMission != null) {
        final currentState = state;
        print('🧭 MISSION CARD: Estado atual: ${currentState.runtimeType}');
        
        if (currentState is GamificationLoaded) {
          print('🧭 MISSION CARD: Atualizando missões após auto-assign');
          final updatedMissions = [...currentState.userMissions, newMission];
          
          emit(GamificationNewMissionAssigned(
            newMission: newMission,
            updatedMissions: updatedMissions,
          ));
          
          // Atualizar estado principal
          emit(currentState.copyWith(userMissions: updatedMissions));
        } else {
          print('🧭 MISSION CARD: Estado não é GamificationLoaded, criando novo estado');
          final userProfile = await _gamificationRepository.getUserProfile(event.userId);
          final stats = await _gamificationRepository.getGamificationStats(event.userId);
          final xpHistory = await _gamificationRepository.getXPHistory(event.userId, limit: 10);
          
          emit(GamificationLoaded(
            userProfile: userProfile,
            stats: stats,
            userMissions: [newMission],
            xpHistory: xpHistory,
          ));
        }

        print('🧭 MISSION CARD: Nova missão atribuída: ${newMission.mission.title}');
      } else {
        print('🧭 MISSION CARD: Nenhuma missão disponível para atribuição');
      }
    } catch (e) {
      print('❌ DEBUG: Erro ao atribuir missão: $e');
      emit(GamificationError(message: 'Erro ao atribuir missão: $e'));
    } finally {
      _isAutoAssigning = false;
    }
  }

  Future<void> _onUpdateMissionProgress(
    UpdateMissionProgress event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      print('🧭 MISSION CARD: Atualizando progresso de missão - Ação: ${event.progress.action}');
      
      final updatedMissions = await _gamificationRepository.updateMissionProgress(
        event.userId,
        event.progress,
      );
      
      final currentState = state;
      print('🧭 MISSION CARD: Estado atual: ${currentState.runtimeType}');
      
      if (currentState is GamificationLoaded) {
        print('🧭 MISSION CARD: Atualizando progresso no estado carregado');
        // Mesclar missões atualizadas na lista atual, preservando as demais
        final Map<String, UserMission> idToMission = {
          for (final m in currentState.userMissions) m.id: m,
        };

        for (final um in updatedMissions) {
          idToMission[um.id] = um;
        }

        final mergedMissions = idToMission.values.toList();

        // Verificar se alguma missão foi completada
        final completedMissions = updatedMissions.where((m) => m.isCompleted).toList();

        if (completedMissions.isNotEmpty) {
          final completedMission = completedMissions.first;

          // Recarregar perfil para atualizar XP
          final updatedProfile = await _gamificationRepository.getUserProfile(event.userId);

          // Se após merge não houver missão ativa, buscar do backend (pode ter acabado de atribuir)
          List<UserMission> missionsAfterEnsure = mergedMissions;
          final hasActiveAfterMerge = missionsAfterEnsure.any((m) => m.isActive);
          if (!hasActiveAfterMerge) {
            try {
              final fetched = await _gamificationRepository.getUserMissions(event.userId);
              if (fetched.isNotEmpty) {
                missionsAfterEnsure = fetched;
              }
            } catch (_) {}
          }

          emit(GamificationMissionCompleted(
            completedMission: completedMission,
            updatedMissions: missionsAfterEnsure,
            updatedProfile: updatedProfile,
          ));

          emit(currentState.copyWith(
            userMissions: missionsAfterEnsure,
            userProfile: updatedProfile,
          ));
        } else {
          // Se API não retornou nada, manter lista atual; se não houver ativa, buscar do backend
          List<UserMission> missionsAfterEnsure = updatedMissions.isEmpty ? currentState.userMissions : mergedMissions;
          final hasActive = missionsAfterEnsure.any((m) => m.isActive);
          if (!hasActive) {
            try {
              final fetched = await _gamificationRepository.getUserMissions(event.userId);
              if (fetched.isNotEmpty) {
                missionsAfterEnsure = fetched;
              }
            } catch (_) {}
          }

          emit(currentState.copyWith(userMissions: missionsAfterEnsure));
        }
      } else {
        print('🧭 MISSION CARD: Estado não é GamificationLoaded, criando novo estado');
        final userProfile = await _gamificationRepository.getUserProfile(event.userId);
        final stats = await _gamificationRepository.getGamificationStats(event.userId);
        final xpHistory = await _gamificationRepository.getXPHistory(event.userId, limit: 10);

        // Se a resposta de update veio vazia, manter missões atuais do backend
        final backendMissions = updatedMissions.isEmpty
            ? await _gamificationRepository.getUserMissions(event.userId)
            : updatedMissions;

        emit(GamificationLoaded(
          userProfile: userProfile,
          stats: stats,
          userMissions: backendMissions,
          xpHistory: xpHistory,
        ));
      }

      print('🧭 MISSION CARD: Progresso atualizado para ${updatedMissions.length} missões');
    } catch (e) {
      print('❌ DEBUG: Erro ao atualizar progresso: $e');
      emit(GamificationError(message: 'Erro ao atualizar progresso: $e'));
    }
  }

  Future<void> _onAddXP(
    AddXPEvent event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      print('🧭 MISSION CARD: Adicionando XP - Quantidade: ${event.addXP.xpAmount}');
      
      final levelUp = await _gamificationRepository.addXP(event.userId, event.addXP);
      
      if (levelUp != null) {
        // Recarregar dados atualizados
        final updatedProfile = await _gamificationRepository.getUserProfile(event.userId);
        final updatedStats = await _gamificationRepository.getGamificationStats(event.userId);
        
        emit(GamificationLevelUp(
          levelUp: levelUp,
          updatedProfile: updatedProfile,
          updatedStats: updatedStats,
        ));
        
        // Atualizar estado principal
        final currentState = state;
        print('🧭 MISSION CARD: Estado atual: ${currentState.runtimeType}');
        
        if (currentState is GamificationLoaded) {
          print('🧭 MISSION CARD: Atualizando perfil e stats após level up');
          emit(currentState.copyWith(
            userProfile: updatedProfile,
            stats: updatedStats,
          ));
        } else {
          print('🧭 MISSION CARD: Estado não é GamificationLoaded, criando novo estado');
          final userMissions = await _gamificationRepository.getUserMissions(event.userId);
          final xpHistory = await _gamificationRepository.getXPHistory(event.userId, limit: 10);
          
          emit(GamificationLoaded(
            userProfile: updatedProfile,
            stats: updatedStats,
            userMissions: userMissions,
            xpHistory: xpHistory,
          ));
        }

        print('🧭 MISSION CARD: Level up! Novo nível: ${levelUp.newLevel}');
      } else {
        print('🧭 MISSION CARD: XP adicionado sem level up');
      }
    } catch (e) {
      print('❌ DEBUG: Erro ao adicionar XP: $e');
      emit(GamificationError(message: 'Erro ao adicionar XP: $e'));
    }
  }

  Future<void> _onLoadXPHistory(
    LoadXPHistory event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      print('🧭 MISSION CARD: Carregando histórico de XP - Página: ${event.page}');
      
      final xpHistory = await _gamificationRepository.getXPHistory(
        event.userId,
        source: event.source,
        startDate: event.startDate,
        endDate: event.endDate,
        page: event.page,
        limit: event.limit,
      );
      
      final currentState = state;
      print('🧭 MISSION CARD: Estado atual: ${currentState.runtimeType}');
      
      if (currentState is GamificationLoaded) {
        print('🧭 MISSION CARD: Atualizando histórico no estado carregado');
        final updatedHistory = event.page == 1 
            ? xpHistory 
            : [...currentState.xpHistory, ...xpHistory];
        
        emit(currentState.copyWith(
          xpHistory: updatedHistory,
          isLoadingMore: false,
        ));
      } else {
        print('🧭 MISSION CARD: Estado não é GamificationLoaded, criando novo estado');
        // Carregar dados completos para criar um estado válido
        final userProfile = await _gamificationRepository.getUserProfile(event.userId);
        final stats = await _gamificationRepository.getGamificationStats(event.userId);
        final userMissions = await _gamificationRepository.getUserMissions(event.userId);
        
        emit(GamificationLoaded(
          userProfile: userProfile,
          stats: stats,
          userMissions: userMissions,
          xpHistory: xpHistory,
        ));
      }

      print('🧭 MISSION CARD: ${xpHistory.length} entradas de histórico carregadas');
    } catch (e) {
      print('❌ DEBUG: Erro ao carregar histórico: $e');
      emit(GamificationError(message: 'Erro ao carregar histórico: $e'));
    }
  }

  Future<void> _onProcessClassCompletion(
    ProcessClassCompletion event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      print('🧭 [GAMIFICATION_BLOC] ===== INICIANDO PROCESSAMENTO DE CONCLUSÃO =====');
      print('🧭 [GAMIFICATION_BLOC] UserId: ${event.userId}');
      print('🧭 [GAMIFICATION_BLOC] ClassId: ${event.classId}');
      print('🧭 [GAMIFICATION_BLOC] Estado atual: ${state.runtimeType}');
      
      print('🧭 [GAMIFICATION_BLOC] Chamando _gamificationRepository.processClassCompletion...');
      await _gamificationRepository.processClassCompletion(event.userId, event.classId);
      print('🧭 [GAMIFICATION_BLOC] processClassCompletion concluído com sucesso');
      
      print('🧭 [GAMIFICATION_BLOC] Recarregando dados atualizados...');
      // Recarregar dados atualizados
      final updatedProfile = await _gamificationRepository.getUserProfile(event.userId);
      print('🧭 [GAMIFICATION_BLOC] Profile atualizado: ${updatedProfile.runtimeType}');
      
      final updatedStats = await _gamificationRepository.getGamificationStats(event.userId);
      print('🧭 [GAMIFICATION_BLOC] Stats atualizados: ${updatedStats.runtimeType}');
      
      final updatedMissions = await _gamificationRepository.getUserMissions(event.userId);
      print('🧭 [GAMIFICATION_BLOC] Missões atualizadas: ${updatedMissions.length} missões');
      
      // Log detalhado das missões
      for (int i = 0; i < updatedMissions.length; i++) {
        final mission = updatedMissions[i];
        print('🧭 [GAMIFICATION_BLOC] Missão $i: ${mission.mission.title} - Status: ${mission.status} - Progresso: ${mission.progress}/${mission.totalRequired}');
      }
      
      final currentState = state;
      print('🧭 [GAMIFICATION_BLOC] Estado atual: ${currentState.runtimeType}');
      
      if (currentState is GamificationLoaded) {
        print('🧭 [GAMIFICATION_BLOC] Atualizando estado existente...');
        emit(currentState.copyWith(
          userProfile: updatedProfile,
          stats: updatedStats,
          userMissions: updatedMissions,
        ));
        print('🧭 [GAMIFICATION_BLOC] Estado atualizado com sucesso');
      } else {
        print('🧭 [GAMIFICATION_BLOC] Criando novo estado...');
        final xpHistory = await _gamificationRepository.getXPHistory(event.userId, limit: 10);
        emit(GamificationLoaded(
          userProfile: updatedProfile,
          stats: updatedStats,
          userMissions: updatedMissions,
          xpHistory: xpHistory,
        ));
        print('🧭 [GAMIFICATION_BLOC] Novo estado criado com sucesso');
      }

      print('✅ [GAMIFICATION_BLOC] ===== PROCESSAMENTO DE CONCLUSÃO FINALIZADO =====');
    } catch (e) {
      print('❌ [GAMIFICATION_BLOC] Erro ao processar conclusão: $e');
      print('❌ [GAMIFICATION_BLOC] Stack trace: ${StackTrace.current}');
      emit(GamificationError(message: 'Erro ao processar conclusão: $e'));
    }
  }

  Future<void> _onProcessDailyLogin(
    ProcessDailyLogin event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      print('🧭 MISSION CARD: Processando login diário');
      
      await _gamificationRepository.processDailyLogin(event.userId);
      
      // Recarregar dados atualizados
      final updatedProfile = await _gamificationRepository.getUserProfile(event.userId);
      final updatedStats = await _gamificationRepository.getGamificationStats(event.userId);
      final updatedMissions = await _gamificationRepository.getUserMissions(event.userId);
      
      final currentState = state;
      print('🧭 MISSION CARD: Estado atual: ${currentState.runtimeType}');
      
      if (currentState is GamificationLoaded) {
        print('🧭 MISSION CARD: Atualizando dados após login diário');
        emit(currentState.copyWith(
          userProfile: updatedProfile,
          stats: updatedStats,
          userMissions: updatedMissions,
        ));
      } else {
        print('🧭 MISSION CARD: Estado não é GamificationLoaded, criando novo estado');
        final xpHistory = await _gamificationRepository.getXPHistory(event.userId, limit: 10);
        emit(GamificationLoaded(
          userProfile: updatedProfile,
          stats: updatedStats,
          userMissions: updatedMissions,
          xpHistory: xpHistory,
        ));
      }

      print('🧭 MISSION CARD: Login diário processado com sucesso');
    } catch (e) {
      print('❌ DEBUG: Erro ao processar login diário: $e');
      emit(GamificationError(message: 'Erro ao processar login diário: $e'));
    }
  }

  Future<void> _onRefreshGamificationData(
    RefreshGamificationData event,
    Emitter<GamificationState> emit,
  ) async {
    final generation = ++_refreshGeneration;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (isClosed || generation != _refreshGeneration) {
      return;
    }

    if (_isRefreshing) {
      print('🧭 MISSION CARD: Refresh já em andamento, ignorando chamada');
      return;
    }

    try {
      _isRefreshing = true;
      print('🧭 MISSION CARD: Refresh automático de dados de gamificação');

      final results = await Future.wait([
        _gamificationRepository.getUserProfile(event.userId),
        _gamificationRepository.getGamificationStats(event.userId),
        _gamificationRepository.getUserMissions(event.userId),
      ]);

      final userProfile = results[0] as UserProfile;
      final stats = results[1] as GamificationStats;
      final userMissions = results[2] as List<UserMission>;

      final currentState = state;
      print('🧭 MISSION CARD: Estado atual: ${currentState.runtimeType}');

      if (currentState is GamificationLoaded) {
        final mergedMissions = _mergeUserMissions(
          currentState.userMissions,
          userMissions,
        );
        if (_missionsSnapshotEqual(
          currentState.userMissions,
          mergedMissions,
        )) {
          return;
        }
        print('🧭 MISSION CARD: Atualizando dados via refresh');
        emit(currentState.copyWith(
          userProfile: userProfile,
          stats: stats,
          userMissions: mergedMissions,
        ));
      } else {
        print('🧭 MISSION CARD: Estado não é GamificationLoaded, criando novo estado');
        final xpHistory =
            await _gamificationRepository.getXPHistory(event.userId, limit: 10);
        emit(GamificationLoaded(
          userProfile: userProfile,
          stats: stats,
          userMissions: userMissions,
          xpHistory: xpHistory,
        ));
      }
    } catch (e) {
      print('❌ DEBUG: Erro no refresh automático: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  List<UserMission> _mergeUserMissions(
    List<UserMission> existing,
    List<UserMission> incoming,
  ) {
    if (incoming.isEmpty) {
      return existing;
    }

    final byId = {for (final mission in existing) mission.id: mission};
    for (final mission in incoming) {
      byId[mission.id] = mission;
    }

    final merged = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  bool _missionsSnapshotEqual(
    List<UserMission> a,
    List<UserMission> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.id != right.id ||
          left.progress != right.progress ||
          left.isCompleted != right.isCompleted ||
          left.isActive != right.isActive) {
        return false;
      }
    }
    return true;
  }

  Future<void> _onResetGamificationState(
    ResetGamificationState event,
    Emitter<GamificationState> emit,
  ) async {
    print('🧭 MISSION CARD: Resetando estado de gamificação');
    emit(const GamificationInitial());
  }

  /// Reseta completamente o GamificationBloc (usado no logout)
  Future<void> _onResetGamification(
    ResetGamification event,
    Emitter<GamificationState> emit,
  ) async {
    print('🔄 [GAMIFICATION_BLOC] Resetando estado...');
    
    // Voltar ao estado inicial
    emit(const GamificationInitial());
    
    print('✅ [GAMIFICATION_BLOC] Estado resetado com sucesso');
  }
}
