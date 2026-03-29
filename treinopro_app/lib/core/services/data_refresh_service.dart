import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/bloc/home_event.dart';
import '../../features/home/presentation/bloc/home_state.dart' as bloc_state;
import '../../features/home/domain/entities/home_state.dart';
import 'cache_service.dart';

/// Serviço para refresh automático de dados
class DataRefreshService {
  final HomeRepository _homeRepository;
  final HomeBloc _homeBloc;
  final CacheService _cacheService;
  
  Timer? _refreshTimer;
  Timer? _searchTimer;
  Timer? _refreshDebounceTimer;
  
  // Configurações de refresh
  static const Duration _refreshInterval = Duration(seconds: 30); // Refresh a cada 30 segundos para reduzir requisições
  static const Duration _searchCheckInterval = Duration(seconds: 30); // Verificar busca a cada 30 segundos
  
  DataRefreshService({
    required HomeRepository homeRepository,
    required HomeBloc homeBloc,
    required CacheService cacheService,
  }) : _homeRepository = homeRepository,
       _homeBloc = homeBloc,
       _cacheService = cacheService;

  /// Verifica se o refresh automático está rodando
  bool get isRunning => _refreshTimer != null;

  /// Inicia o refresh automático (DESATIVADO - usando apenas WebSocket)
  void startAutoRefresh() {
    // Serviço desativado - usando apenas WebSocket para evitar sobrecarga do servidor
    debugPrint('📡 DataRefreshService: Polling desativado - usando apenas WebSocket');
    return;
    
    // Código antigo preservado caso precise reativar no futuro
    // _stopAutoRefresh(); // Para qualquer timer existente
    // _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
    //   _refreshData();
    // });
    // _searchTimer = Timer.periodic(_searchCheckInterval, (timer) {
    //   _checkSearchStatus();
    // });
  }

  /// Para o refresh automático
  void stopAutoRefresh() {
    _stopAutoRefresh();
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _searchTimer?.cancel();
    _searchTimer = null;
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = null;
  }

  /// Força um refresh imediato dos dados
  Future<void> forceRefresh() async {
    await _refreshData();
  }

  /// Força refresh do card de treinos especificamente
  void forceWorkoutCardRefresh() {
    // Debounce para evitar refresh múltiplos em sequência
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Invalidar cache antes de forçar refresh para garantir dados atualizados
      _cacheService.invalidateCache();
      _homeBloc.add(const LoadWorkoutCardData());
    });
  }

  /// Atualiza os dados do card de treinos
  Future<void> _refreshData() async {
    try {
      // Verificar se há mudanças antes de fazer refresh completo
      final currentState = _homeBloc.state;
      if (currentState is bloc_state.HomeLoaded) {
        // Fazer refresh inteligente - verificar dados e forçar refresh se necessário
        await _smartRefresh(currentState);
      } else {
        // Se não está carregado, inicializar a home primeiro
        _homeBloc.add(const InitializeHome());
        
        // Aguardar um pouco e tentar novamente
        await Future.delayed(const Duration(milliseconds: 500));
        final newState = _homeBloc.state;
        if (newState is bloc_state.HomeLoaded) {
          await _smartRefresh(newState);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ DEBUG: Erro no auto refresh: $e');
      }
    }
  }

  /// Refresh inteligente - verifica propostas pendentes e aulas agendadas
  Future<void> _smartRefresh(bloc_state.HomeLoaded currentState) async {
    try {
      final userId = currentState.homeState.userId;
      if (userId == null) {
        return;
      }
      
      // Verificar propostas pendentes
      final pendingProposals = await _homeRepository.loadPendingProposals(userId);
      
      // Verificar aulas agendadas
      final scheduledClasses = await _homeRepository.loadScheduledClasses(userId);
      
      // Removido: refresh de gamificação automático. Mantemos WebSocket + onResume + pull-to-refresh.
      
      // Forçar refresh quando HÁ dados OU quando NÃO HÁ dados mas o card atual não reflete isso
      final currentCardState = currentState.homeState.workoutCardState;
      final shouldBeNoWorkout = pendingProposals.isEmpty && scheduledClasses.isEmpty;
      final isNotShowingNoWorkout = currentCardState != WorkoutCardState.noWorkout;

      if (pendingProposals.isNotEmpty || scheduledClasses.isNotEmpty || (shouldBeNoWorkout && isNotShowingNoWorkout)) {
        forceWorkoutCardRefresh();
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ DEBUG: Erro no smart refresh: $e');
      }
    }
  }

  /// Verifica o status da busca ativa
  void _checkSearchStatus() {
    final state = _homeBloc.state;
    if (state is bloc_state.HomeLoaded && state.homeState.isSearchingActive) {
      // Verificar se a busca expirou (3 minutos)
      // TODO: Implementar searchStartTime no HomeState
      // final searchStartTime = state.homeState.searchStartTime;
      
      // TODO: Implementar verificação de expiração
      // if (searchStartTime != null) {
      //   final elapsed = now.difference(searchStartTime);
      //   if (elapsed.inMinutes >= 3) {
      //     // Busca expirou, parar busca
      //     _homeBloc.add(const StopProposalSearch());
      //     
      //     if (kDebugMode) {
      //       print('⏰ DEBUG: Busca expirou após 3 minutos');
      //     }
      //   }
      // }
    }
  }

  /// Dispara refresh quando há mudanças no backend
  void notifyDataChanged() {
    if (kDebugMode) {
      print('📡 DEBUG: Notificação de mudança de dados recebida');
    }
    
    // Força refresh imediato
    forceRefresh();
  }

  /// Dispara refresh quando uma proposta é criada
  void notifyProposalCreated({
    required String location,
    required DateTime trainingDate,
    required String trainingTime,
  }) {
    if (kDebugMode) {
      print('📝 DEBUG: Proposta criada, iniciando busca');
    }
    
    // Iniciar busca ativa
    _homeBloc.add(StartProposalSearch(
      location: location,
      trainingDate: trainingDate,
      trainingTime: trainingTime,
    ));
    
    // Força refresh dos dados
    forceRefresh();
  }

  /// Dispara refresh quando uma proposta é aceita
  void notifyProposalAccepted() {
    if (kDebugMode) {
      print('✅ DEBUG: Proposta aceita, parando busca');
    }
    
    // Parar busca ativa
    _homeBloc.add(const StopProposalSearch());
    
    // Força refresh dos dados
    forceRefresh();
  }

  /// Dispara refresh quando uma aula é cancelada
  void notifyClassCancelled() {
    if (kDebugMode) {
      print('❌ DEBUG: Aula cancelada');
    }
    
    // Força refresh dos dados
    forceRefresh();
  }

  void dispose() {
    _stopAutoRefresh();
  }
}
