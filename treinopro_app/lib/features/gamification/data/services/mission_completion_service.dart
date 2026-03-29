import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../presentation/bloc/gamification_bloc.dart';
// import '../../presentation/bloc/gamification_event.dart';
// import '../../presentation/bloc/gamification_state.dart';
import '../../domain/entities/gamification_entity.dart';

/// Serviço para gerenciar conclusão automática de missões
class MissionCompletionService {
  static final MissionCompletionService _instance = MissionCompletionService._internal();
  factory MissionCompletionService() => _instance;
  MissionCompletionService._internal();

  // ignore: unused_field
  GamificationBloc? _gamificationBloc; // Mantido para futura reativação controlada
  Timer? _checkTimer;
  // ignore: unused_field
  String? _currentUserId; // Mantido para futura reativação controlada

  /// Inicializa o serviço
  void initialize(GamificationBloc gamificationBloc) {
    _gamificationBloc = gamificationBloc;
    debugPrint('🎯 MissionCompletionService: Inicializado');
  }

  /// Inicia o monitoramento de conclusão de missões
  void startMonitoring(String userId) {
    _currentUserId = userId;
    
    // Serviço desativado para evitar requisições desnecessárias
    debugPrint('🎯 MissionCompletionService: Monitoramento desativado para reduzir requisições');
    return;
    
    // Código antigo preservado caso reativemos no futuro
    // _checkTimer?.cancel();
    // _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    //   _checkForCompletedMissions();
    // });
  }

  /// Para o monitoramento
  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _currentUserId = null;
    debugPrint('🎯 MissionCompletionService: Monitoramento parado');
  }

  /// Verifica se há missões completadas
  void _checkForCompletedMissions() {
    // Serviço desativado para evitar disparos indevidos de claim_reward em missões já concluídas
    debugPrint('🎯 MissionCompletionService: verificação desativada (serviço desligado)');
    return;
    // if (_currentUserId == null || _gamificationBloc == null) return;

    // Lógica antiga preservada abaixo caso reativemos no futuro
    // final state = _gamificationBloc!.state;
    // if (state is! GamificationLoaded) return;
    // final userMissions = state.userMissions;
    // final completedMissions = userMissions.where((mission) => mission.isCompleted).toList();
    // if (completedMissions.isNotEmpty) {
    //   debugPrint('🎯 MissionCompletionService: ${completedMissions.length} missões completadas encontradas');
    //   for (final mission in completedMissions) {
    //     _processCompletedMission(mission);
    //   }
    // }
  }

  /// Processa uma missão completada
  // void _processCompletedMission(UserMission mission) {
  //   debugPrint('🎯 MissionCompletionService: Processando missão completada: ${mission.mission.title}');
  //   _gamificationBloc?.add(UpdateMissionProgress(
  //     userId: _currentUserId!,
  //     progress: MissionProgress(
  //       userId: _currentUserId!,
  //       action: 'claim_reward',
  //       count: mission.totalRequired,
  //     ),
  //   ));
  //   Future.delayed(const Duration(seconds: 2), () {
  //     _gamificationBloc?.add(AutoAssignNextMission(userId: _currentUserId!));
  //   });
  // }

  /// Força verificação de missões completadas
  void forceCheck() {
    _checkForCompletedMissions();
  }

  /// Verifica se uma missão específica está completa
  bool isMissionCompleted(UserMission mission) {
    return mission.progress >= mission.totalRequired;
  }

  /// Calcula o progresso de uma missão
  double calculateMissionProgress(UserMission mission) {
    if (mission.totalRequired <= 0) return 0.0;
    return (mission.progress / mission.totalRequired).clamp(0.0, 1.0);
  }

  /// Verifica se uma missão pode ser completada com uma ação específica
  bool canCompleteWithAction(UserMission mission, String action, int value) {
    if (mission.mission.requirements.action != action) return false;
    
    final newProgress = mission.progress + value;
    return newProgress >= mission.totalRequired;
  }

  /// Dispose do serviço
  void dispose() {
    stopMonitoring();
  }
}
