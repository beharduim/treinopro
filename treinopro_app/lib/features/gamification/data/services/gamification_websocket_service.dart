import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../presentation/bloc/gamification_bloc.dart';
import '../../presentation/bloc/gamification_event.dart';

/// Serviço para gerenciar eventos de gamificação via WebSocket
class GamificationWebSocketService {
  static final GamificationWebSocketService _instance = GamificationWebSocketService._internal();
  factory GamificationWebSocketService() => _instance;
  GamificationWebSocketService._internal();

  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  // Deduplicação de eventos por eventId
  final Map<String, DateTime> _recentEventIds = <String, DateTime>{};
  static const Duration _dedupTTL = Duration(minutes: 5);
  
  HomeBloc? _homeBloc;
  GamificationBloc? _gamificationBloc;

  /// Inicializa o serviço
  void initialize({
    required HomeBloc homeBloc,
    required GamificationBloc gamificationBloc,
  }) {
    _homeBloc = homeBloc;
    _gamificationBloc = gamificationBloc;
    
    _listenToWebSocketMessages();
    debugPrint('🎮 GamificationWebSocket: Inicializado');
  }

  /// Escuta mensagens do WebSocket
  void _listenToWebSocketMessages() {
    _messageSubscription?.cancel();
    _messageSubscription = _webSocketService.messageStream.listen(_handleMessage);
  }

  /// Processa mensagens recebidas
  void _handleMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    
    switch (type) {
      case 'profile_update':
        _handleProfileUpdate(message);
        break;
      case 'mission_completed':
        _handleMissionCompleted(message);
        break;
      case 'mission_assigned':
        _handleMissionAssigned(message);
        break;
      case 'class_update':
        _handleClassUpdate(message);
        break;
      case 'class_completion_processed':
        _handleClassCompletionProcessed(message);
        break;
      case 'proposal_update':
        _handleProposalUpdate(message);
        break;
      case 'match_confirmed':
        _handleMatchConfirmed(message);
        break;
      default:
        debugPrint('🎮 GamificationWebSocket: Tipo de mensagem não reconhecido - $type');
    }
  }

  /// Trata evento de missão completada
  void _handleMissionCompleted(Map<String, dynamic> message) {
    final data = message['data'] as Map<String, dynamic>?;
    final userId = data?['userId'] as String?;
    final mission = data?['profile']?['mission'] as Map<String, dynamic>?;
    
    debugPrint('🎯 [GAMIFICATION_WS] Missão completada - ${mission?['title']} (${mission?['id']})');
    
    if (userId != null && userId.isNotEmpty) {
      // Recarregar dados de gamificação para atualizar missões
      _gamificationBloc?.add(RefreshGamificationData(userId: userId));
      debugPrint('🎯 [GAMIFICATION_WS] Dados de gamificação atualizados para userId: $userId');
    }
  }

  /// Trata evento de missão atribuída
  void _handleMissionAssigned(Map<String, dynamic> message) {
    final data = message['data'] as Map<String, dynamic>?;
    final userId = data?['userId'] as String?;
    final mission = data?['profile']?['mission'] as Map<String, dynamic>?;
    
    debugPrint('🎯 [GAMIFICATION_WS] Missão atribuída - ${mission?['title']} (${mission?['id']})');
    
    if (userId != null && userId.isNotEmpty) {
      // Recarregar dados de gamificação para atualizar missões
      _gamificationBloc?.add(RefreshGamificationData(userId: userId));
      debugPrint('🎯 [GAMIFICATION_WS] Dados de gamificação atualizados para userId: $userId');
    }
  }

  /// Trata evento de atualização de perfil (XP, level up, etc.)
  void _handleProfileUpdate(Map<String, dynamic> message) {
    final data = message['data'] as Map<String, dynamic>?;
    final eventId = data?['eventId'] as String?;
    final action = data?['action'] as String?;
    final userId = data?['userId'] as String?;
    
    // Deduplicação: ignorar eventos já processados
    if (!_shouldProcessEvent(eventId)) {
      debugPrint('🎮 GamificationWebSocket: Evento duplicado ignorado (eventId=$eventId, action=$action)');
      return;
    }

    debugPrint('🎮 GamificationWebSocket: Profile update - $action (eventId=$eventId)');
    
    if (action == 'xp_gained') {
      debugPrint('🎮 GamificationWebSocket: XP ganho - ${data?['xpGained']}');
    }

    if (action == 'mission_assigned') {
      final mission = data?['profile']?['mission'] as Map<String, dynamic>?;
      debugPrint('🎮 GamificationWebSocket: Missão atribuída - ${mission?['title']} (${mission?['id']})');
    }

    if (action == 'mission_completed') {
      final mission = data?['profile']?['mission'] as Map<String, dynamic>?;
      debugPrint('🎮 GamificationWebSocket: Missão completada - ${mission?['title']} (${mission?['id']})');
    }
    
    // Atualiza dados de gamificação se tivermos userId
    if (userId != null && userId.isNotEmpty) {
      // Refresh seletivo por tipo de ação
      if (action == 'mission_assigned' || action == 'mission_completed' || action == 'mission_progressed') {
        _gamificationBloc?.add(LoadUserMissions(userId: userId));
      } else if (action == 'xp_gained' || action == 'level_up') {
        _gamificationBloc?.add(LoadUserProfile(userId: userId));
        _gamificationBloc?.add(LoadGamificationStats(userId: userId));
        // Além de perfil/estatísticas, pode haver progresso de missão não-completada
        _gamificationBloc?.add(LoadUserMissions(userId: userId));
      } else {
        _gamificationBloc?.add(RefreshGamificationData(userId: userId));
      }
    }
    
    // Atualiza card de workout se necessário
    _homeBloc?.add(const LoadWorkoutCardData());
  }

  // ===== Deduplicação =====
  bool _shouldProcessEvent(String? eventId) {
    // Se não veio eventId, não deduplicar (compatibilidade)
    if (eventId == null || eventId.isEmpty) return true;

    // Remover antigos
    final now = DateTime.now();
    _recentEventIds.removeWhere((_, ts) => now.difference(ts) > _dedupTTL);

    if (_recentEventIds.containsKey(eventId)) {
      return false;
    }

    _recentEventIds[eventId] = now;
    // Mantém tamanho máximo para evitar crescimento
    const int maxSize = 200;
    if (_recentEventIds.length > maxSize) {
      // Remove o mais antigo
      final oldestEntry = _recentEventIds.entries.reduce((a, b) => a.value.isBefore(b.value) ? a : b);
      _recentEventIds.remove(oldestEntry.key);
    }
    return true;
  }

  /// Trata evento de atualização de aula
  void _handleClassUpdate(Map<String, dynamic> message) {
    final data = message['data'] as Map<String, dynamic>?;
    final action = data?['action'] as String?;
    
    debugPrint('🎮 GamificationWebSocket: Class update - $action');
    
    if (action == 'class_completed') {
      debugPrint('🎮 GamificationWebSocket: Aula completada - ${data?['class']?['id']}');
      
      // Forçar refresh de missões após conclusão de aula para resolver race condition
      final userId = data?['class']?['studentId'] as String?;
      if (userId != null && userId.isNotEmpty) {
        debugPrint('🎮 GamificationWebSocket: Atualizando missões para userId: $userId');
        _gamificationBloc?.add(LoadUserMissions(userId: userId));
        // Também atualizar perfil e estatísticas para garantir sincronização completa
        _gamificationBloc?.add(LoadUserProfile(userId: userId));
        _gamificationBloc?.add(LoadGamificationStats(userId: userId));
      }

      // Atualiza card de workout
      _homeBloc?.add(const LoadWorkoutCardData());
    }
  }

  /// Trata evento de conclusão de aula processada (evento consolidado do backend)
  void _handleClassCompletionProcessed(Map<String, dynamic> message) {
    final data = message['data'] as Map<String, dynamic>?;
    final userId = data?['userId'] as String?;
    final profile = data?['profile'] as Map<String, dynamic>?;
    final classId = profile?['classId'] as String?;
    final missionsUpdated = profile?['missionsUpdated'] as List<dynamic>?;
    final xpGained = profile?['xpGained'] as int?;
    
    debugPrint('🎯 [GAMIFICATION_WS] Conclusão de aula processada - ClassId: $classId, XP: $xpGained');
    debugPrint('🎯 [GAMIFICATION_WS] Missões atualizadas: ${missionsUpdated?.length ?? 0}');
    
    if (userId != null && userId.isNotEmpty) {
      // Recarregar dados de gamificação para refletir progresso atualizado
      _gamificationBloc?.add(LoadUserMissions(userId: userId));
      _gamificationBloc?.add(LoadUserProfile(userId: userId));
      _gamificationBloc?.add(LoadGamificationStats(userId: userId));
      debugPrint('🎯 [GAMIFICATION_WS] Dados de gamificação atualizados após processamento consolidado');
    }
    
    // Atualiza card de workout
    _homeBloc?.add(const LoadWorkoutCardData());
  }

  /// Trata evento de atualização de proposta
  void _handleProposalUpdate(Map<String, dynamic> message) {
    final data = message['data'] as Map<String, dynamic>?;
    final action = data?['action'] as String?;
    
    debugPrint('🎮 GamificationWebSocket: Proposal update - $action');
    
    // Atualiza dados da home se necessário
    _homeBloc?.add(const LoadWorkoutCardData());
  }

  /// Trata evento de match confirmado
  void _handleMatchConfirmed(Map<String, dynamic> message) {
    final data = message['data'] as Map<String, dynamic>?;
    
    debugPrint('🎮 GamificationWebSocket: Match confirmado - ${data?['proposal']?['id']}');
    
    // Disparar evento ProposalMatched para atualizar o card dinâmico
    if (_homeBloc != null && data != null) {
      final proposal = data['proposal'] as Map<String, dynamic>?;
      if (proposal != null) {
        final matchData = {
          'location': proposal['locationName'] ?? proposal['location'] ?? 'Local não informado',
          'date': proposal['trainingDate'] ?? proposal['date'] ?? DateTime.now().toIso8601String(),
          'time': proposal['trainingTime'] ?? proposal['time'] ?? '00:00',
          'personalName': proposal['personalName'] ?? 'Personal Trainer',
          'personalImage': proposal['personalImage'] ?? proposal['personalImageUrl'],
        };
        
        debugPrint('🎮 GamificationWebSocket: Disparando ProposalMatched com dados: $matchData');
        _homeBloc!.add(ProposalMatched(matchData));
      }
    }
    
    // Também atualiza dados da home para garantir sincronização
    _homeBloc?.add(const LoadWorkoutCardData());
  }

  /// Conecta ao WebSocket
  Future<void> connect() async {
    await _webSocketService.connect();
  }

  /// Desconecta do WebSocket
  Future<void> disconnect() async {
    await _webSocketService.disconnect();
  }

  /// Reinicia a conexão
  Future<void> reconnect() async {
    await _webSocketService.reconnect();
  }

  /// Verifica se está conectado
  bool get isConnected => _webSocketService.isConnected;

  /// Dispose do serviço
  void dispose() {
    _messageSubscription?.cancel();
    _webSocketService.dispose();
  }
}
