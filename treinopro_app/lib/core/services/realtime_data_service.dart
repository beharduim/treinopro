import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/bloc/home_event.dart' as home_events;
import '../../features/classes/presentation/bloc/classes_bloc.dart';
import '../../features/classes/presentation/bloc/classes_event.dart';
import '../../features/proposals/presentation/bloc/proposals_bloc.dart';
import '../../features/proposals/presentation/bloc/proposals_event.dart';
import '../../features/gamification/presentation/bloc/gamification_bloc.dart';
import '../../features/gamification/presentation/bloc/gamification_event.dart';
import '../../core/di/dependency_injection.dart';
import '../../features/home/data/services/auth_service.dart';
import 'websocket_service.dart';
import 'live_activity_service.dart';
import '../../features/proposals/presentation/bloc/proposal_search_bloc.dart' as proposal_search;
import '../../features/users/data/services/users_api_service.dart';
// import 'fcm_service.dart'; // COMENTADO: Não usando FCMService por enquanto

/// Serviço para gerenciar dados em tempo real via WebSocket (substitui DataRefreshService)
class RealtimeDataService {
  static final RealtimeDataService _instance = RealtimeDataService._internal();
  factory RealtimeDataService() => _instance;
  RealtimeDataService._internal();

  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  
  // BLoCs para notificar mudanças
  HomeBloc? _homeBloc;
  ClassesBloc? _classesBloc;
  ProposalsBloc? _proposalsBloc;
  GamificationBloc? _gamificationBloc;
  proposal_search.ProposalSearchBloc? _proposalSearchBloc;
  
  // ✅ ESTRATÉGIA UBER: Dados temporários para transição suave
  Map<String, dynamic>? _pendingMatchData;
  
  // Callback para notificar PersonalHomePage sobre class_created
  Function(Map<String, dynamic>)? _onClassCreatedCallback;
  
  // Estado da conexão
  bool _isConnected = false;
  bool _isInitialized = false;
  
  // Fallback inteligente (sem polling)
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 10);
  
  // Debounce para evitar estouro de chamadas de LoadWorkoutCardData
  Timer? _homeCardReloadDebounce;

  /// Inicializa o serviço com os BLoCs necessários
  void initialize({
    required HomeBloc homeBloc,
    required ClassesBloc classesBloc,
    required ProposalsBloc proposalsBloc,
    required GamificationBloc gamificationBloc,
    required proposal_search.ProposalSearchBloc proposalSearchBloc,
    Function(Map<String, dynamic>)? onClassCreated,
  }) {
    // ✅ CORREÇÃO: Limpar referências antigas antes de atribuir novas
    if (_isInitialized) {
      debugPrint('⚠️ RealtimeDataService: Já inicializado, limpando referências antigas...');
      _messageSubscription?.cancel();
      _connectionSubscription?.cancel();
      _reconnectTimer?.cancel();
      _homeCardReloadDebounce?.cancel();
    }
    
    // ✅ CORREÇÃO: Verificar se os BLoCs não estão fechados antes de atribuir
    if (homeBloc.isClosed) {
      debugPrint('❌ RealtimeDataService: HomeBloc está fechado, não inicializando');
      return;
    }
    
    _homeBloc = homeBloc;
    _classesBloc = classesBloc;
    _proposalsBloc = proposalsBloc;
    _gamificationBloc = gamificationBloc;
    _proposalSearchBloc = proposalSearchBloc;
    _onClassCreatedCallback = onClassCreated;
    
    _isInitialized = true;
    debugPrint('🔄 RealtimeDataService: Inicializado com novos BLoCs');
    debugPrint('🔄 RealtimeDataService: HomeBloc hashCode: ${homeBloc.hashCode}');
    debugPrint('🔄 RealtimeDataService: ClassesBloc hashCode: ${classesBloc.hashCode}');
    debugPrint('🔄 RealtimeDataService: ProposalsBloc hashCode: ${proposalsBloc.hashCode}');
    
    // Conectar WebSocket
    _connect();
  }

  /// Conecta ao WebSocket
  Future<void> _connect() async {
    if (!_isInitialized) {
      debugPrint('❌ RealtimeDataService: Não inicializado');
      return;
    }

    try {
      await _webSocketService.connect();
      _setupListeners();
    } catch (e) {
      debugPrint('❌ RealtimeDataService: Erro ao conectar - $e');
      _scheduleReconnect();
    }
  }

  /// Configura listeners do WebSocket
  void _setupListeners() {
    // Listener de conexão
    _connectionSubscription?.cancel();
    _connectionSubscription = _webSocketService.connectionStream.listen((connected) {
      _isConnected = connected;
      debugPrint('🔄 RealtimeDataService: WebSocket ${connected ? "conectado" : "desconectado"}');
      
      if (connected) {
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();
        
        // CRÍTICO: Reconfigurar listener de mensagens se foi cancelado (app voltou do background)
        if (_messageSubscription == null) {
          _messageSubscription = _webSocketService.messageStream.listen(_handleMessage);
          debugPrint('🔄 [REALTIME] Listener de mensagens reconfigurado após reconexão');
        }
      } else {
        // Não agendar reconexão se app está em background
        final wsService = WebSocketService();
        if (!wsService.isInBackground) {
          _scheduleReconnect();
        } else {
          debugPrint('⏸️ [REALTIME] App em background - não agendando reconexão');
        }
      }
    });

    // Listener de mensagens
    _messageSubscription?.cancel();
    _messageSubscription = _webSocketService.messageStream.listen(_handleMessage);
  }

  /// Processa mensagens do WebSocket
  void _handleMessage(Map<String, dynamic> message) {
    // NOTA: Não bloqueamos o messageStream aqui porque listeners diretos (como personal_home_page)
    // precisam receber os eventos para funcionar corretamente (ex: abrir modal)
    // A verificação de background será feita apenas no processamento interno específico
    
    final type = message['type'] as String?;
    final data = message['data'] as Map<String, dynamic>?;
    
    debugPrint('📥 [REALTIME] ===== EVENTO WEBSOCKET RECEBIDO =====');
    debugPrint('📥 [REALTIME] Tipo: $type');
    debugPrint('📥 [REALTIME] Dados: ${data?.keys ?? "null"}');
    debugPrint('📥 [REALTIME] Timestamp: ${DateTime.now().toIso8601String()}');
    
    switch (type) {
      // Eventos de propostas
      case 'proposal_update':
        _handleProposalUpdate(data);
        break;
      case 'proposal_created':
        _handleProposalCreated(data);
        break;
      case 'proposal_accepted':
        _handleProposalAccepted(data);
        break;
      case 'proposal_match_found':
        _handleProposalMatchFound(data);
        break;
      case 'proposal_expired':
        _handleProposalExpired(data);
        break;
      case 'new_proposal':
        _handleNewProposal(data);
        break;
      case 'match_confirmed':
        _handleMatchConfirmed(data);
        break;
        
      // Eventos de aulas
      case 'class_update':
        _handleClassUpdate(data);
        break;
      case 'class_created':
        _handleClassCreated(data);
        break;
      case 'class_timer_started':
        _handleClassTimerStarted(data);
        break;
      case 'class_timer_expired':
        _handleClassTimerExpired(data);
        break;
      
      // Chat
      case 'new_message':
        _handleNewMessage(data);
        break;
        
      // Eventos de gamificação
      case 'profile_update':
        _handleProfileUpdate(data);
        break;
      case 'mission_assigned':
        _handleMissionAssigned(data);
        break;
      case 'mission_completed':
        _handleMissionCompleted(data);
        break;
      case 'xp_gained':
        _handleXPGained(data);
        break;
      case 'level_up':
        _handleLevelUp(data);
        break;
        
      // Eventos específicos do personal
      case 'financial_update':
        _handleFinancialUpdate(data);
        break;
        
      // Eventos de avaliações
      case 'rating_created':
        _handleRatingCreated(data);
        break;
        
      // Eventos de disputas
      case 'dispute_created':
        _handleDisputeCreated(data);
        break;
      case 'dispute_resolved':
        _handleDisputeResolved(data);
        break;
      case 'dispute_updated':
        _handleDisputeUpdated(data);
        break;
      
      // Eventos do sistema que não precisam de ação
      case 'user_online':
      case 'user_offline':
        debugPrint('📱 RealtimeDataService: Evento $type ignorado (não requer ação)');
        break;
        
      default:
        debugPrint('⚠️ RealtimeDataService: Evento desconhecido - $type');
    }
  }

  // ===== HANDLERS DE EVENTOS =====

  void _handleProposalUpdate(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('📝 RealtimeDataService: Proposta atualizada');
    
    // Atualizar lista imediatamente via WebSocket
    try {
      _proposalsBloc?.add(ProposalsUpdateFromWebSocket(data: {
        'action': 'proposal_updated',
        ...data,
      }));
    } catch (_) {}

    // Verificar se é um cancelamento
    final action = data['action'] as String?;
    if (action == 'proposal_cancelled') {
      debugPrint('❌ RealtimeDataService: Proposta cancelada - atualizando imediatamente');

      // Para cancelamentos, primeiro disparar ProposalCancelled para limpar isSearchingActive
      final proposalId = data['proposal']?['id'] as String?;
      if (proposalId != null) {
        _homeBloc?.add(home_events.ProposalCancelled(proposalId: proposalId));
        debugPrint('❌ RealtimeDataService: ProposalCancelled disparado com ID: $proposalId');
        LiveActivityService.instance.endActivity(proposalId: proposalId);
      } else {
        _homeBloc?.add(const home_events.ProposalCancelled());
        debugPrint('❌ RealtimeDataService: ProposalCancelled disparado sem ID');
        LiveActivityService.instance.endActivity();
      }
      
      // Aguardar um pouco para o ProposalCancelled ser processado antes de recarregar dados
      Future.delayed(const Duration(milliseconds: 100), () {
        _proposalsBloc?.add(const ProposalsRefresh());
        _homeBloc?.add(const home_events.LoadWorkoutCardData());
        
        // ✅ CORREÇÃO: Remover ClassesRefresh - cancelamento de proposta não deve impactar página de aulas
        // Propostas canceladas não afetam a lista de aulas dos personais
        // _classesBloc?.add(const ClassesRefresh()); // REMOVIDO
      });
    } else {
      // Para outras atualizações, usar fluxo normal
      _proposalsBloc?.add(const ProposalsRefresh());
      _scheduleHomeCardReload(const Duration(milliseconds: 100));
    }
  }

  void _handleProposalCreated(Map<String, dynamic>? data) async {
    if (data == null) return;
    debugPrint('🔔 RealtimeDataService: Proposta criada');
    
    // Atualizar lista imediatamente via WebSocket
    try {
      _proposalsBloc?.add(ProposalsUpdateFromWebSocket(data: {
        'action': 'proposal_created',
        ...data,
      }));
    } catch (_) {}
    
    // COMENTADO: Não usando FCMService por enquanto
    // Verificar se há dados pendentes de notificação FCM (quando usuário toca na notificação)
    // final pendingNotificationData = FCMService.instance.getPendingNotificationData();
    // if (pendingNotificationData != null) {
    //   debugPrint('🎯 [REALTIME] Dados de notificação pendente encontrados, abrindo modal');
    //   _openProposalModalFromNotification(pendingNotificationData, data);
    // }
    
    // Notificar ProposalsBloc para processar a nova proposta
    _proposalsBloc?.add(const ProposalsRefresh());
  }

  // COMENTADO: Método não usado enquanto FCMService está desabilitado
  // /// Abrir modal de proposta a partir de dados de notificação
  // void _openProposalModalFromNotification(Map<String, dynamic> notificationData, Map<String, dynamic> proposalData) {
  //   debugPrint('🎯 [REALTIME] Abrindo ProposalModal com dados da notificação');
  //   
  //   // Extrair dados da proposta
  //   final proposal = proposalData['proposal'] as Map<String, dynamic>?;
  //   final student = proposalData['student'] as Map<String, dynamic>?;
  //   
  //   if (proposal == null || student == null) {
  //     debugPrint('❌ [REALTIME] Dados incompletos para abrir modal');
  //     return;
  //   }
  //   
  //   // Preparar dados para o modal
  //   final modalData = {
  //     'studentName': student['name'] ?? student['firstName'] ?? 'Aluno',
  //     'location': proposal['locationName'] ?? 'Localização',
  //     'time': proposal['trainingTime'] ?? '00:00',
  //     'date': proposal['trainingDate'] != null 
  //         ? DateTime.parse(proposal['trainingDate']).toString().substring(0, 10)
  //         : null,
  //     'modality': proposal['modality'] ?? 'Personal Training',
  //     'price': proposal['price']?.toString() ?? '0',
  //     'proposalId': proposal['id']?.toString() ?? '',
  //     'studentRating': student['rating']?.toString() ?? '0.0',
  //     'studentExperience': student['timeOnPlatform'] ?? '0 dias',
  //     'studentImageUrl': student['photo'] ?? student['profileImageUrl'] ?? '',
  //   };
  //   
  //   debugPrint('🎯 [REALTIME] Dados do modal: $modalData');
  //   
  //   // Notificar PersonalHomePage para abrir o modal
  //   if (_onClassCreatedCallback != null) {
  //     _onClassCreatedCallback!(modalData);
  //   }
  // }

  void _handleProposalMatchFound(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('🤝 RealtimeDataService: Match encontrado');
    debugPrint('📊 [PROPOSAL_MATCH_FOUND] Dados recebidos: ${data.keys}');
    
    // Notificar HomeBloc sobre o match
    final proposal = data['proposal'] as Map<String, dynamic>?;
    final personal = data['personal'] as Map<String, dynamic>?;
    
    // DEBUG: Log detalhado dos dados do personal
    if (personal != null) {
      debugPrint('🔍 [PROPOSAL_MATCH_FOUND] Dados do personal: ${personal.keys}');
      debugPrint('🔍 [PROPOSAL_MATCH_FOUND] personal.name: ${personal['name']}');
      debugPrint('🔍 [PROPOSAL_MATCH_FOUND] personal.firstName: ${personal['firstName']}');
      debugPrint('🔍 [PROPOSAL_MATCH_FOUND] personal.lastName: ${personal['lastName']}');
      debugPrint('🔍 [PROPOSAL_MATCH_FOUND] personal.photo: ${personal['photo']}');
      debugPrint('🔍 [PROPOSAL_MATCH_FOUND] personal.profileImageUrl: ${personal['profileImageUrl']}');
      debugPrint('🔍 [PROPOSAL_MATCH_FOUND] personal.rating: ${personal['rating']}');
      debugPrint('🔍 [PROPOSAL_MATCH_FOUND] personal.averageRating: ${personal['averageRating']}');
    }
    
    if (proposal != null && personal != null) {
      _homeBloc?.add(home_events.ProposalMatched({
        'location': proposal['locationName'] ?? '',
        'date': proposal['trainingDate'] ?? '',
        'time': proposal['trainingTime'] ?? '',
        'personalName': personal['name'] ?? '',
        'personalImage': personal['photo'] ?? '',
      }));
      
      // DEBUG: Log dos dados enviados para ProposalMatched
      debugPrint('🔍 [PROPOSAL_MATCH_FOUND] Dados enviados para ProposalMatched:');
      debugPrint('🔍 [PROPOSAL_MATCH_FOUND] personalName: ${personal['name'] ?? ''}');
      debugPrint('🔍 [PROPOSAL_MATCH_FOUND] personalImage: ${personal['photo'] ?? ''}');
    }
  }

  void _handleProposalExpired(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('⏰ [PROPOSAL_EXPIRED] Proposta expirada');
    debugPrint('📊 [PROPOSAL_EXPIRED] Dados recebidos: ${data.keys}');
    
    final proposalId = data['proposalId'] as String? ?? data['proposal']?['id'] as String?;
    debugPrint('🔍 [PROPOSAL_EXPIRED] ProposalId: ${proposalId ?? "null"}');
    
    // 🔧 CORREÇÃO: Verificar se o BLoC está fechado antes de adicionar eventos
    if (_homeBloc != null && !_homeBloc!.isClosed) {
      _homeBloc!.add(const home_events.ProposalSearchExpired());
      debugPrint('📤 [PROPOSAL_EXPIRED] ProposalSearchExpired disparado - isSearchingActive será false');
    } else {
      debugPrint('⚠️ [PROPOSAL_EXPIRED] HomeBloc está fechado, ignorando evento');
    }
    LiveActivityService.instance.endActivity(proposalId: proposalId);
    
    // Aguardar um pouco para o ProposalSearchExpired ser processado antes de recarregar dados
    Future.delayed(const Duration(milliseconds: 100), () {
      debugPrint('🔄 [PROPOSAL_EXPIRED] Recarregando dados após 100ms');
      
      // Remover imediatamente da lista via WebSocket
      try {
        _proposalsBloc?.add(ProposalsUpdateFromWebSocket(data: {
          'action': 'proposal_expired',
          if (proposalId != null) 'proposalId': proposalId,
          ...data,
        }));
      } catch (_) {}

      // Notificar ProposalsBloc (com verificação)
      if (_proposalsBloc != null && !_proposalsBloc!.isClosed) {
        _proposalsBloc!.add(const ProposalsRefresh());
        debugPrint('📤 [PROPOSAL_EXPIRED] ProposalsBloc notificado');
      }
      
      // Notificar HomeBloc para recarregar dados (com verificação)
      if (_homeBloc != null && !_homeBloc!.isClosed) {
        _homeBloc!.add(const home_events.LoadWorkoutCardData());
        debugPrint('📤 [PROPOSAL_EXPIRED] HomeBloc notificado - card mudará para pendingProposal');
      }
      
      debugPrint('🏁 [PROPOSAL_EXPIRED] Handler finalizado');
    });
  }

  void _handleNewProposal(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('🆕 RealtimeDataService: Nova proposta');
    
    // Atualizar lista imediatamente via WebSocket
    try {
      _proposalsBloc?.add(ProposalsUpdateFromWebSocket(data: data));
    } catch (_) {}

    // Notificar ProposalsBloc
    _proposalsBloc?.add(const ProposalsRefresh());
  }

  void _handleMatchConfirmed(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('✅ RealtimeDataService: Match confirmado');
    debugPrint('📊 [MATCH_CONFIRMED] Dados recebidos: ${data.keys}');

    // Encerrar Live Activity — match confirmado, proposta não está mais disponível
    final matchProposalId = (data['proposal'] as Map<String, dynamic>?)?['id'] as String?
        ?? data['proposalId'] as String?;
    LiveActivityService.instance.endActivity(proposalId: matchProposalId);

    // Notificar todos os BLoCs relevantes IMEDIATAMENTE
    _proposalsBloc?.add(const ProposalsRefresh());
    _classesBloc?.add(const ClassesRefresh());
    debugPrint('📤 [MATCH_CONFIRMED] ProposalsBloc e ClassesBloc notificados');
    
    // Verificar autenticação ANTES de processar
    final authService = sl<AuthService>();
    final hasToken = authService.isAuthenticated;
    debugPrint('🔐 [MATCH_CONFIRMED] Verificando autenticação: $hasToken');
    if (!hasToken) {
      debugPrint('❌ [MATCH_CONFIRMED] Usuário não autenticado - abortando processamento');
      return;
    }
    
    // Disparar evento ProposalMatched APENAS para o aluno (não para o personal que aceitou)
    final proposal = data['proposal'] as Map<String, dynamic>?;
    final personal = data['personal'] as Map<String, dynamic>?;
    final student = data['student'] as Map<String, dynamic>?;
    
    // DEBUG: Log detalhado dos dados do personal
    if (personal != null) {
      debugPrint('🔍 [MATCH_CONFIRMED] Dados do personal: ${personal.keys}');
      debugPrint('🔍 [MATCH_CONFIRMED] personal.name: ${personal['name']}');
      debugPrint('🔍 [MATCH_CONFIRMED] personal.firstName: ${personal['firstName']}');
      debugPrint('🔍 [MATCH_CONFIRMED] personal.lastName: ${personal['lastName']}');
      debugPrint('🔍 [MATCH_CONFIRMED] personal.photo: ${personal['photo']}');
      debugPrint('🔍 [MATCH_CONFIRMED] personal.profileImageUrl: ${personal['profileImageUrl']}');
      debugPrint('🔍 [MATCH_CONFIRMED] personal.rating: ${personal['rating']}');
      debugPrint('🔍 [MATCH_CONFIRMED] personal.averageRating: ${personal['averageRating']}');
    }
    
    if (proposal != null && personal != null && student != null) {
      final personalId = personal['id'] as String?;
      final studentId = student['id'] as String?;
      final currentUserId = _getCurrentUserId();
      
      debugPrint('🔐 [MATCH_CONFIRMED] Token de autenticação verificado - processando normalmente');
      
      debugPrint('🔍 [MATCH_CONFIRMED] personalId=$personalId, studentId=$studentId, currentUserId=$currentUserId');
      
      // Só disparar ProposalMatched se o usuário atual é o aluno (não o personal que aceitou)
      if (currentUserId != null && currentUserId == studentId) {
        debugPrint('👨‍🎓 [MATCH_CONFIRMED] Usuário é o ALUNO - processando match');
        
        String? _firstNonEmptyString(List<dynamic> candidates) {
          for (final c in candidates) {
            final v = c?.toString();
            if (v != null && v.trim().isNotEmpty) return v.trim();
          }
          return null;
        }

        double? _firstParsableDouble(List<dynamic> candidates) {
          for (final c in candidates) {
            if (c == null) continue;
            final parsed = double.tryParse(c.toString());
            if (parsed != null) return parsed;
          }
          return null;
        }

        // ✅ CORREÇÃO: Só usar dados reais, não fallbacks
        final personalName = _firstNonEmptyString([
          personal['name'],
          '${personal['firstName'] ?? ''} ${personal['lastName'] ?? ''}'.trim(),
        ]);

        final personalImage = _firstNonEmptyString([
          personal['photo'],
          personal['profileImageUrl'],
          personal['avatarUrl'],
          personal['imageUrl'],
        ]);

        final personalRating = _firstParsableDouble([
          personal['rating'],
          personal['averageRating'],
          personal['score'],
        ]);

        final personalResponseTime = _firstNonEmptyString([
          personal['timeOnPlatform'],
          personal['memberSince'],
          personal['responseTime'],
          'Rápido', // Fallback
        ]) ?? 'Rápido';

        // DEBUG: Log dos dados extraídos
        debugPrint('🔍 [MATCH_CONFIRMED] Dados extraídos - personalName: $personalName');
        debugPrint('🔍 [MATCH_CONFIRMED] Dados extraídos - personalImage: $personalImage');
        debugPrint('🔍 [MATCH_CONFIRMED] Dados extraídos - personalRating: $personalRating');
        debugPrint('🔍 [MATCH_CONFIRMED] Dados extraídos - personalResponseTime: $personalResponseTime');
        
        // DEBUG: Log dos dados brutos do personal para debug
        debugPrint('🔍 [MATCH_CONFIRMED] Dados brutos do personal:');
        personal.forEach((key, value) {
          debugPrint('🔍 [MATCH_CONFIRMED] personal[$key]: $value');
        });
        
        // ✅ ESTRATÉGIA UBER: Não mudar para matched com dados genéricos
        // Só avançaremos o modal para matched se houver pelo menos nome OU foto
        final hasMeaningfulPersonalData = (personalName != null && personalName.trim().isNotEmpty && personalName != 'Personal Trainer') ||
                                          (personalImage != null && personalImage.trim().isNotEmpty);
        if (!hasMeaningfulPersonalData) {
          debugPrint('🚗 [MATCH_CONFIRMED] Mantendo estado "searching" (dados genéricos) até class_created trazer dados completos');
        }
        
        // Armazenar dados temporariamente para quando class_created chegar
        _pendingMatchData = {
          'location': proposal['locationName'] ?? 'Localização',
          'date': proposal['trainingDate'] ?? DateTime.now().toIso8601String(),
          'time': proposal['trainingTime'] ?? '00:00',
          'personalName': personalName,
          'personalImage': personalImage,
          'personalRating': personalRating,
          'personalTimeOnPlatform': personalResponseTime,
          'proposalId': proposal['id']?.toString() ?? '',
        };
        
        // ✅ Só enviar WebSocketMatchFound se houver dados minimamente úteis
        if (hasMeaningfulPersonalData) {
          debugPrint('📦 [MATCH_CONFIRMED] Dados suficientes, enviando WebSocketMatchFound com nome/foto');
          if (_proposalSearchBloc != null && !_proposalSearchBloc!.isClosed) {
            final modality = proposal['modality']?.toString() ?? 'Personal Training';
            _proposalSearchBloc!.add(proposal_search.WebSocketMatchFound(
              personalName: personalName ?? 'Personal Trainer',
              personalPhoto: personalImage ?? '',
              personalRating: personalRating ?? 0.0,
              personalResponseTime: personalResponseTime,
              proposalId: proposal['id']?.toString() ?? '',
              modality: modality,
            ));
            debugPrint('✅ [MATCH_CONFIRMED] WebSocketMatchFound enviado (com dados úteis)');
          } else {
            debugPrint('⚠️ [MATCH_CONFIRMED] ProposalSearchBloc não disponível');
          }
        } else {
          debugPrint('⏳ [MATCH_CONFIRMED] Aguardando class_created para dados completos');
        }
        
        // Tentar obter classId do evento (se disponível)
        final classId = data['classId'] as String? ?? data['class']?['id'] as String?;
        debugPrint('🔍 [MATCH_CONFIRMED] ClassId encontrado: ${classId ?? "null"}');
        
        // ClassId será atualizado pelo class_created com dados completos
        debugPrint('📦 [MATCH_CONFIRMED] ClassId será atualizado pelo class_created: ${classId ?? "aguardando"}');
        
        // Notificar HomeBloc imediatamente (com lock de refresh no ApiService não há race condition)
        if (_homeBloc != null && !_homeBloc!.isClosed) {
          _homeBloc!.add(const home_events.LoadWorkoutCardData());
          debugPrint('📤 [MATCH_CONFIRMED] HomeBloc notificado IMEDIATAMENTE para aluno');
        }
      } else if (currentUserId != null && currentUserId == personalId) {
        debugPrint('👨‍🏫 [MATCH_CONFIRMED] Usuário é o PERSONAL que aceitou - apenas recarregando dados');
        // Apenas recarregar dados para o personal
        if (_homeBloc != null && !_homeBloc!.isClosed) {
          _homeBloc!.add(const home_events.LoadWorkoutCardData());
        }
      } else {
        debugPrint('⚠️ [MATCH_CONFIRMED] Usuário não identificado como aluno ou personal');
        if (_homeBloc != null && !_homeBloc!.isClosed) {
          _homeBloc!.add(const home_events.LoadWorkoutCardData());
        }
      }
    } else {
      debugPrint('⚠️ [MATCH_CONFIRMED] Dados incompletos - proposal: ${proposal != null}, personal: ${personal != null}, student: ${student != null}');
      // Fallback: apenas recarregar dados
      if (_homeBloc != null && !_homeBloc!.isClosed) {
        _homeBloc!.add(const home_events.LoadWorkoutCardData());
      }
    }
    
    debugPrint('🏁 [MATCH_CONFIRMED] Handler finalizado');
  }

  /// Obtém o ID do usuário atual
  String? _getCurrentUserId() {
    try {
      return sl<AuthService>().currentUserId;
    } catch (e) {
      debugPrint('❌ RealtimeDataService: Erro ao obter currentUserId: $e');
      return null;
    }
  }

  void _handleClassUpdate(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('🏋️ [CLASS_UPDATE] Aula atualizada');
    debugPrint('📊 [CLASS_UPDATE] Dados recebidos: ${data.keys}');
    
    // Verificar o tipo de ação
    final action = data['action'] as String?;
    final classData = data['class'] as Map<String, dynamic>?;
    
    debugPrint('🔍 [CLASS_UPDATE] Action: ${action ?? "null"}');
    
    if (action == 'class_cancelled') {
      debugPrint('❌ [CLASS_UPDATE] Aula cancelada - removendo apenas o card específico');
      
      // ✅ CORREÇÃO: Usar ClassesUpdateFromWebSocket para atualizar apenas o card específico
      // ao invés de fazer refresh completo da lista (evita refresh contínuo)
      if (classData != null) {
        _classesBloc?.add(ClassesUpdateFromWebSocket(data: {
          'action': 'class_cancelled',
          'class': classData,
        }));
        debugPrint('✅ [CLASS_UPDATE] ClassesUpdateFromWebSocket disparado para remover card específico');
      }
      
      // Atualizar card da home (para remover aula cancelada)
      _homeBloc?.add(const home_events.LoadWorkoutCardData());
      
      debugPrint('✅ [CLASS_UPDATE] Card específico será removido sem refresh completo da lista');
      return; // ✅ IMPORTANTE: Retornar aqui para não executar o código abaixo (evita ClassesRefresh duplicado)
    } else if (action == 'class_created' && classData != null) {
      debugPrint('🚗 [CLASS_UPDATE] Aula criada via class_update - processando como class_created');
      // Delegar para o handler específico de class_created
      _handleClassCreated(data);
      return; // Não continuar com o processamento normal do class_update
    } else if (action == 'class_completed' && classData != null) {
      debugPrint('✅ [CLASS_UPDATE] Aula concluída - processando missões');
      _processClassCompletion(classData);
    } else if (action != null) {
      debugPrint('🔄 [CLASS_UPDATE] Ação: $action');
    }
    
    // ✅ CORREÇÃO: Só notificar ClassesBloc se não for cancelamento (já tratado acima com return)
    // Para outras ações, usar ClassesUpdateFromWebSocket para atualização incremental
    if (classData != null && action != null) {
      _classesBloc?.add(ClassesUpdateFromWebSocket(data: {
        'action': action,
        'class': classData,
      }));
      debugPrint('📤 [CLASS_UPDATE] ClassesUpdateFromWebSocket disparado (action: $action)');
    } else {
      // Fallback: refresh completo apenas se não houver dados da aula
    _classesBloc?.add(const ClassesRefresh());
      debugPrint('📤 [CLASS_UPDATE] ClassesRefresh disparado (fallback - sem classData)');
    }
    
    // Notificar HomeBloc
    if (action == 'class_cancelled') {
      // Já tratado acima com return
    } else {
      _scheduleHomeCardReload(const Duration(milliseconds: 50));
      debugPrint('📤 [CLASS_UPDATE] HomeBloc notificado (debounced 50ms)');
    }
    
    debugPrint('🏁 [CLASS_UPDATE] Handler finalizado');
  }

  Future<void> _handleClassCreated(Map<String, dynamic>? data) async {
    if (data == null) {
      debugPrint('❌ [CLASS_CREATED] Data é null!');
      return;
    }
    debugPrint('🆕 [CLASS_CREATED] ===== NOVA AULA CRIADA =====');
    debugPrint('📊 [CLASS_CREATED] Dados recebidos: ${data.keys}');
    debugPrint('📊 [CLASS_CREATED] Timestamp: ${DateTime.now().toIso8601String()}');
    
    // Processar dados da aula para cache do chat
    final classData = data['class'] as Map<String, dynamic>?;
    if (classData != null) {
      final classId = classData['id'] as String?;
      final proposalId = classData['proposalId'] as String?;
      final status = classData['status'] as String?;
      final classDate = classData['date'] as String?;
      final classTime = classData['time'] as String?;
      
      debugPrint('🔍 [CLASS_CREATED] ClassId: $classId, ProposalId: $proposalId, Status: $status');
      debugPrint('🔍 [CLASS_CREATED] Data/Hora: $classDate às $classTime');
      
      // DEBUG: Log detalhado dos dados da aula
      debugPrint('🔍 [CLASS_CREATED] Dados da aula: ${classData.keys}');
      final personal = classData['personal'] as Map<String, dynamic>?;
      if (personal != null) {
        debugPrint('🔍 [CLASS_CREATED] Dados do personal na aula: ${personal.keys}');
        debugPrint('🔍 [CLASS_CREATED] personal.name: ${personal['name']}');
        debugPrint('🔍 [CLASS_CREATED] personal.firstName: ${personal['firstName']}');
        debugPrint('🔍 [CLASS_CREATED] personal.lastName: ${personal['lastName']}');
        debugPrint('🔍 [CLASS_CREATED] personal.profileImageUrl: ${personal['profileImageUrl']}');
        debugPrint('🔍 [CLASS_CREATED] personal.rating: ${personal['rating']}');
      }
      
      if (proposalId != null) {
        // Notificar PersonalHomePage sobre nova aula para cache do chat
        if (_onClassCreatedCallback != null) {
          try {
            _onClassCreatedCallback!(classData);
            debugPrint('✅ [CLASS_CREATED] PersonalHomePage notificado sobre nova aula');
          } catch (e) {
            debugPrint('⚠️ [CLASS_CREATED] Erro ao notificar PersonalHomePage: $e');
          }
        }
        
        // ✅ ESTRATÉGIA UBER: Fazer transição para matched com dados completos
        try {
          final searchBloc = _proposalSearchBloc;
          if (searchBloc == null) {
            debugPrint('⚠️ [CLASS_CREATED] ProposalSearchBloc não inicializado');
            return;
          }
          final currentState = searchBloc.state;
          debugPrint('🔍 [CLASS_CREATED] Estado atual do ProposalSearchBloc: ${currentState.runtimeType}');
          
          if (currentState is proposal_search.ProposalSearchActive) {
            debugPrint('🚗 [CLASS_CREATED] Estratégia Uber: Modal ainda está "searching", fazendo transição para "matched" com dados completos');
            
            // ✅ DEBUG: Logs detalhados dos dados brutos
            debugPrint('🔍 [CLASS_CREATED] Dados brutos do classData:');
            debugPrint('🔍 [CLASS_CREATED] classData.keys: ${classData.keys}');
            debugPrint('🔍 [CLASS_CREATED] classData.personalProfileImageUrl: ${classData['personalProfileImageUrl']}');
            debugPrint('🔍 [CLASS_CREATED] classData.personalPhoto: ${classData['personalPhoto']}');
            debugPrint('🔍 [CLASS_CREATED] classData.personalImage: ${classData['personalImage']}');
            debugPrint('🔍 [CLASS_CREATED] classData.personalRating: ${classData['personalRating']}');
            debugPrint('🔍 [CLASS_CREATED] classData.personalScore: ${classData['personalScore']}');
            debugPrint('🔍 [CLASS_CREATED] classData.personalTimeOnPlatform: ${classData['personalTimeOnPlatform']}');
            
            // Extrair dados completos do personal
            final personal = classData['personal'] as Map<String, dynamic>?;
            if (personal != null) {
              debugPrint('🔍 [CLASS_CREATED] personal.keys: ${personal.keys}');
              debugPrint('🔍 [CLASS_CREATED] personal.profileImageUrl: ${personal['profileImageUrl']}');
              debugPrint('🔍 [CLASS_CREATED] personal.photo: ${personal['photo']}');
              debugPrint('🔍 [CLASS_CREATED] personal.imageUrl: ${personal['imageUrl']}');
              debugPrint('🔍 [CLASS_CREATED] personal.avatarUrl: ${personal['avatarUrl']}');
              debugPrint('🔍 [CLASS_CREATED] personal.rating: ${personal['rating']}');
              debugPrint('🔍 [CLASS_CREATED] personal.averageRating: ${personal['averageRating']}');
              debugPrint('🔍 [CLASS_CREATED] personal.score: ${personal['score']}');
              debugPrint('🔍 [CLASS_CREATED] personal.timeOnPlatform: ${personal['timeOnPlatform']}');
              debugPrint('🔍 [CLASS_CREATED] personal.memberSince: ${personal['memberSince']}');
            } else {
              debugPrint('⚠️ [CLASS_CREATED] personal é null!');
            }
            
            final personalFirstName = (classData['personalFirstName'] ?? personal?['firstName'])?.toString() ?? '';
            final personalLastName = (classData['personalLastName'] ?? personal?['lastName'])?.toString() ?? '';
            
            // ✅ CORREÇÃO: Melhorar extração do nome com mais fallbacks
            String personalName = '';
            if ((personal?['name']?.toString() ?? '').isNotEmpty) {
              personalName = personal!['name'].toString();
            } else if (personalFirstName.isNotEmpty || personalLastName.isNotEmpty) {
              personalName = ('$personalFirstName $personalLastName').trim();
            } else if ((classData['personalName']?.toString() ?? '').isNotEmpty) {
              personalName = classData['personalName'].toString();
            } else {
              personalName = 'Personal Trainer'; // Fallback apenas se realmente não houver dados
            }
            
            debugPrint('🔍 [CLASS_CREATED] Nome extraído: "$personalName" (firstName="$personalFirstName", lastName="$personalLastName")');
            
            // ✅ CORREÇÃO: Melhorar extração da foto com mais fallbacks
            final personalPhoto = (classData['personalProfileImageUrl'] ?? 
                                  classData['personalPhoto'] ?? 
                                  classData['personalImage'] ?? 
                                  personal?['profileImageUrl'] ?? 
                                  personal?['photo'] ?? 
                                  personal?['imageUrl'] ?? 
                                  personal?['avatarUrl'])?.toString() ?? '';
            
            // ✅ CORREÇÃO: Melhorar extração do rating com mais fallbacks
            final personalRatingRaw = classData['personalRating'] ?? 
                                     classData['personalScore'] ?? 
                                     personal?['rating'] ?? 
                                     personal?['averageRating'] ?? 
                                     personal?['score'] ?? 
                                     '0.0';
            final personalRating = double.tryParse(personalRatingRaw.toString()) ?? 0.0;
            
            // ✅ CORREÇÃO: Melhorar extração do tempo de plataforma
            String personalTimeOnPlatform = '';
            if ((classData['personalTimeOnPlatform']?.toString() ?? '').isNotEmpty) {
              personalTimeOnPlatform = classData['personalTimeOnPlatform'].toString();
            } else if ((personal?['timeOnPlatform']?.toString() ?? '').isNotEmpty) {
              personalTimeOnPlatform = personal!['timeOnPlatform'].toString();
            } else if ((personal?['memberSince']?.toString() ?? '').isNotEmpty) {
              personalTimeOnPlatform = personal!['memberSince'].toString();
            } else if ((classData['personalResponseTime']?.toString() ?? '').isNotEmpty) {
              personalTimeOnPlatform = classData['personalResponseTime'].toString();
            } else {
              personalTimeOnPlatform = 'Rápido'; // Fallback apenas se realmente não houver dados
            }
            
            debugPrint('🔍 [CLASS_CREATED] Tempo na plataforma extraído: "$personalTimeOnPlatform"');
            
            debugPrint('✅ [CLASS_CREATED] Dados completos extraídos: name=$personalName, photo=$personalPhoto, rating=$personalRating, timeOnPlatform=$personalTimeOnPlatform');
            
            // ✅ CORREÇÃO: Se os dados estão vazios, buscar via API
            if (personalPhoto.isEmpty || personalRating == 0.0) {
              debugPrint('⚠️ [CLASS_CREATED] Dados incompletos do WebSocket, buscando via API...');
              
              // Buscar dados completos via API
              try {
                final personalId = personal?['id'] as String? ?? classData['personalId'] as String?;
                if (personalId != null) {
                  debugPrint('🔍 [CLASS_CREATED] Buscando dados completos para personalId: $personalId');
                  
                  // Fazer chamada à API para buscar dados completos
                  final usersApi = sl<UsersApiService>();
                  final personalInfo = await usersApi.getUserBasicInfo(personalId);
                  
                  if (personalInfo.isNotEmpty) {
                    final apiPersonalName = (personalInfo['firstName'] ?? '').toString() + ' ' + (personalInfo['lastName'] ?? '').toString();
                    final apiPersonalPhoto = (personalInfo['profileImageUrl'] ?? '').toString();
                    final apiPersonalRating = double.tryParse((personalInfo['rating'] ?? '0.0').toString()) ?? 0.0;
                    final apiPersonalTimeOnPlatform = (personalInfo['timeOnPlatform'] ?? 'Rápido').toString();
                    
                    debugPrint('✅ [CLASS_CREATED] Dados da API: name=$apiPersonalName, photo=$apiPersonalPhoto, rating=$apiPersonalRating, timeOnPlatform=$apiPersonalTimeOnPlatform');
                    
                    // Usar dados da API se disponíveis
                    final finalPersonalName = apiPersonalName.trim().isNotEmpty ? apiPersonalName.trim() : personalName;
                    final finalPersonalPhoto = apiPersonalPhoto.isNotEmpty ? apiPersonalPhoto : personalPhoto;
                    final finalPersonalRating = apiPersonalRating > 0.0 ? apiPersonalRating : personalRating;
                    final finalPersonalTimeOnPlatform = apiPersonalTimeOnPlatform.isNotEmpty ? apiPersonalTimeOnPlatform : personalTimeOnPlatform;
                    
                    debugPrint('✅ [CLASS_CREATED] Dados finais: name=$finalPersonalName, photo=$finalPersonalPhoto, rating=$finalPersonalRating, timeOnPlatform=$finalPersonalTimeOnPlatform');
                    
                    // Extrair modalidade da proposta
                    final modality = (classData['proposalModality'] ?? 'Treino')?.toString() ?? 'Treino';
                    
                    // Fazer transição para matched com dados completos da API
                    searchBloc.add(proposal_search.WebSocketMatchFound(
                      personalName: finalPersonalName,
                      personalPhoto: finalPersonalPhoto,
                      personalRating: finalPersonalRating,
                      personalResponseTime: finalPersonalTimeOnPlatform,
                      proposalId: proposalId,
                      modality: modality,
                    ));
                  } else {
                    debugPrint('⚠️ [CLASS_CREATED] API retornou dados vazios, usando dados do WebSocket');
                    // Extrair modalidade da proposta
                    final modality = (classData['proposalModality'] ?? 'Treino')?.toString() ?? 'Treino';
                    // Usar dados do WebSocket mesmo que vazios
                    searchBloc.add(proposal_search.WebSocketMatchFound(
                      personalName: personalName,
                      personalPhoto: personalPhoto,
                      personalRating: personalRating,
                      personalResponseTime: personalTimeOnPlatform,
                      proposalId: proposalId,
                      modality: modality,
                    ));
                  }
                } else {
                  debugPrint('⚠️ [CLASS_CREATED] personalId não encontrado, usando dados do WebSocket');
                  // Extrair modalidade da proposta
                  final modality = (classData['proposalModality'] ?? 'Treino')?.toString() ?? 'Treino';
                  // Usar dados do WebSocket mesmo que vazios
                  searchBloc.add(proposal_search.WebSocketMatchFound(
                    personalName: personalName,
                    personalPhoto: personalPhoto,
                    personalRating: personalRating,
                    personalResponseTime: personalTimeOnPlatform,
                    proposalId: proposalId,
                    modality: modality,
                  ));
                }
              } catch (e) {
                debugPrint('❌ [CLASS_CREATED] Erro ao buscar dados da API: $e');
                // Extrair modalidade da proposta
                final modality = (classData['proposalModality'] ?? 'Treino')?.toString() ?? 'Treino';
                // Usar dados do WebSocket mesmo que vazios
                searchBloc.add(proposal_search.WebSocketMatchFound(
                  personalName: personalName,
                  personalPhoto: personalPhoto,
                  personalRating: personalRating,
                  personalResponseTime: personalTimeOnPlatform,
                  proposalId: proposalId,
                  modality: modality,
                ));
              }
            } else {
              debugPrint('✅ [CLASS_CREATED] Dados do WebSocket estão completos, usando diretamente');
              // Extrair modalidade da proposta
              final modality = (classData['proposalModality'] ?? 'Treino')?.toString() ?? 'Treino';
              // Fazer transição para matched com dados completos
              searchBloc.add(proposal_search.WebSocketMatchFound(
                personalName: personalName,
                personalPhoto: personalPhoto,
                personalRating: personalRating,
                personalResponseTime: personalTimeOnPlatform,
                proposalId: proposalId,
                modality: modality,
              ));
            }
            
            // Atualizar classId
            if (classId != null && classId.isNotEmpty) {
              searchBloc.add(proposal_search.UpdateClassId(classId: classId));
              debugPrint('✅ [CLASS_CREATED] ClassId atualizado: $classId');
            }
            
            // Enviar dados para HomeBloc também
            if (_pendingMatchData != null) {
              _pendingMatchData!['personalName'] = personalName;
              _pendingMatchData!['personalImage'] = personalPhoto;
              _pendingMatchData!['personalRating'] = personalRating;
              _homeBloc?.add(home_events.ProposalMatched(_pendingMatchData!));
              debugPrint('✅ [CLASS_CREATED] ProposalMatched enviado para HomeBloc com dados completos');
              _pendingMatchData = null; // Limpar dados pendentes
            }
            
            // 🔧 CORREÇÃO: SEMPRE recarregar dados do HomeBloc quando uma aula é criada
            // Isso garante que o card de workout seja atualizado automaticamente
            if (_homeBloc != null && !_homeBloc!.isClosed) {
              _homeBloc!.add(const home_events.LoadWorkoutCardData());
              debugPrint('✅ [CLASS_CREATED] HomeBloc notificado para recarregar dados do card');
            }
            
            debugPrint('🎉 [CLASS_CREATED] Transição para matched concluída com dados completos!');
            
          } else if (currentState is proposal_search.ProposalSearchMatched) {
            debugPrint('✅ [CLASS_CREATED] Modal já está em matched, apenas atualizando dados');
            
            // Atualizar classId se necessário
            if (classId != null && classId.isNotEmpty) {
              searchBloc.add(proposal_search.UpdateClassId(classId: classId));
              debugPrint('✅ [CLASS_CREATED] ClassId atualizado: $classId');
            }
            
          } else {
            debugPrint('⚠️ [CLASS_CREATED] Modal não está em estado ativo (${currentState.runtimeType})');
          }
        } catch (e) {
          debugPrint('❌ [CLASS_CREATED] Erro ao fazer transição: $e');
        }

        // ✅ ESTRATÉGIA UBER: Fallback removido - agora sempre usamos dados completos do class_created
      }
    } else {
      debugPrint('⚠️ [CLASS_CREATED] Dados da aula (class) não encontrados no payload');
    }
    
    // Notificar ClassesBloc
    _classesBloc?.add(const ClassesRefresh());
    debugPrint('📤 [CLASS_CREATED] ClassesBloc notificado');
    
    // ✅ CORREÇÃO: Notificar HomeBloc IMEDIATAMENTE e também com delay
    // Notificação imediata para atualizar o card rapidamente
    if (_homeBloc != null && !_homeBloc!.isClosed) {
      _homeBloc!.add(const home_events.LoadWorkoutCardData());
      debugPrint('📤 [CLASS_CREATED] HomeBloc notificado IMEDIATAMENTE');
    }
    
    // ✅ CORREÇÃO: Aguardar um pequeno delay para garantir que a API tem os dados atualizados
    // Isso resolve o problema de race condition onde a API ainda não commitou a transação
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_homeBloc != null && !_homeBloc!.isClosed) {
        _homeBloc!.add(const home_events.LoadWorkoutCardData());
        debugPrint('📤 [CLASS_CREATED] HomeBloc notificado após 300ms - card será atualizado com dados frescos');
      }
    });
    
    // ✅ CORREÇÃO ADICIONAL: Notificar novamente após 1 segundo para garantir
    // Isso garante que mesmo se houver problemas de timing, o card será atualizado
    Future.delayed(const Duration(seconds: 1), () {
      if (_homeBloc != null && !_homeBloc!.isClosed) {
        _homeBloc!.add(const home_events.LoadWorkoutCardData());
        debugPrint('📤 [CLASS_CREATED] HomeBloc notificado após 1s - garantindo atualização final');
      }
    });
    
    debugPrint('🏁 [CLASS_CREATED] Handler finalizado');
  }

  void _handleClassTimerStarted(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('⏰ RealtimeDataService: Timer de aula iniciado');
    
    // Notificar ClassesBloc
    _classesBloc?.add(const ClassesRefresh());
    
    // ✅ CORREÇÃO: Atualizar card da home quando aula iniciar
    _homeBloc?.add(const home_events.LoadWorkoutCardData());
    
    // Notificação local informando que a aula começou
    // try {
    //   final classTitle = data['class']?['title']?.toString() ?? 'Sua aula';
    //   sl<NotificationService>().showClassStartedNotification(classTitle: classTitle);
    // } catch (e) {
    //   debugPrint('⚠️ RealtimeDataService: Falha ao notificar início da aula: $e');
    // }
    
    debugPrint('✅ RealtimeDataService: Card da home atualizado após timer iniciado');
  }

  void _handleClassTimerExpired(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('⏰ RealtimeDataService: Timer de aula expirado');
    
    // Notificar ClassesBloc
    _safeAddToBloc(_classesBloc, const ClassesRefresh(), 'ClassesBloc');
    
    // Notificar HomeBloc
    _safeAddToBloc(_homeBloc, const home_events.LoadWorkoutCardData(), 'HomeBloc');
  }

  void _handleProfileUpdate(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('👤 RealtimeDataService: Perfil atualizado');
    
    // Notificar GamificationBloc
    final userId = data['userId'] as String?;
    if (userId != null) {
      _gamificationBloc?.add(RefreshGamificationData(userId: userId));
    }
  }

  void _handleMissionAssigned(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('🎯 RealtimeDataService: Missão atribuída');
    
    // Notificar GamificationBloc
    final userId = data['userId'] as String?;
    if (userId != null) {
      _gamificationBloc?.add(LoadUserMissions(userId: userId));
    }
  }

  void _handleMissionCompleted(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('🎯 RealtimeDataService: Missão completada');
    
    // Notificar GamificationBloc
    final userId = data['userId'] as String?;
    if (userId != null) {
      _gamificationBloc?.add(RefreshGamificationData(userId: userId));
    }
  }

  void _handleXPGained(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('⭐ RealtimeDataService: XP ganho');
    
    // Notificar GamificationBloc
    final userId = data['userId'] as String?;
    if (userId != null) {
      _gamificationBloc?.add(LoadUserProfile(userId: userId));
      _gamificationBloc?.add(LoadGamificationStats(userId: userId));
    }
  }

  void _handleLevelUp(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('🚀 RealtimeDataService: Level up!');
    
    // Notificar GamificationBloc
    final userId = data['userId'] as String?;
    if (userId != null) {
      _gamificationBloc?.add(RefreshGamificationData(userId: userId));
    }
  }

  void _handleNewMessage(Map<String, dynamic>? data) {
    if (data == null) return;
    try {
      final senderName = data['senderName']?.toString() ?? 'Nova mensagem';
      final text = data['text']?.toString() ?? 'Você recebeu uma mensagem';
      // Montar payload JSON com dados necessários para abrir o chat
      final payload = {
        'type': 'chat',
        'data': {
          'classId': data['classId']?.toString() ?? '',
          'receiverId': data['senderId']?.toString() ?? '',
          'receiverName': senderName,
          'location': data['location']?.toString() ?? 'Local a definir',
          'date': data['date']?.toString() ?? '',
          'time': data['time']?.toString() ?? '',
          'duration': data['duration']?.toString() ?? '',
          'currentUserIsStudent': (data['currentUserRole']?.toString() ?? 'student') == 'student',
        }
      };
      // sl<NotificationService>().showMessageNotification(
      //   title: senderName,
      //   body: text,
      //   payload: payload.toString(),
      // );
      debugPrint('✅ RealtimeDataService: Notificação de mensagem exibida');
    } catch (e) {
      debugPrint('⚠️ RealtimeDataService: Erro ao notificar mensagem: $e');
    }
  }

  void _handleDisputeCreated(Map<String, dynamic>? data) {
    if (data == null) return;
    try {
      final dispute = data['dispute'] as Map<String, dynamic>?;
      final classData = data['class'] as Map<String, dynamic>?;
      
      if (dispute != null && classData != null) {
        final reportedBy = dispute['reportedBy'] as String? ?? '';
        final reportedTo = dispute['reportedTo'] as String? ?? '';
        // final reason = dispute['reason'] as String? ?? 'Ausência não justificada';
        final className = classData['title']?.toString() ?? 'Aula';
        final classDate = classData['date']?.toString() ?? '';
        final classTime = classData['time']?.toString() ?? '';
        
        // Determinar quem está sendo notificado
        final currentUserId = _getCurrentUserId();
        String notificationTitle;
        String notificationBody;
        
        if (currentUserId == reportedBy) {
          // Quem reportou recebe confirmação
          notificationTitle = 'Disputa criada';
          notificationBody = 'Sua disputa sobre "$className" foi registrada. Aguarde a análise.';
        } else if (currentUserId == reportedTo) {
          // Quem foi reportado recebe notificação
          notificationTitle = 'Nova disputa';
          notificationBody = 'Uma disputa foi criada sobre sua aula "$className" ($classDate às $classTime)';
        } else {
          // Fallback genérico
          notificationTitle = 'Nova disputa';
          notificationBody = 'Uma disputa foi criada para a aula "$className"';
        }
        
        // Payload para navegação futura (quando implementarmos tela de disputas)
        // final payload = {
        //   'type': 'dispute',
        //   'data': {
        //     'disputeId': dispute['id']?.toString() ?? '',
        //     'classId': classData['id']?.toString() ?? '',
        //     'reason': reason,
        //     'status': dispute['status']?.toString() ?? 'pending',
        //   }
        // };
        
        // sl<NotificationService>().showDisputeNotification(
        //   title: notificationTitle,
        //   body: notificationBody,
        // );
        
        debugPrint('✅ RealtimeDataService: Notificação de disputa criada exibida');
      }
    } catch (e) {
      debugPrint('⚠️ RealtimeDataService: Erro ao notificar disputa criada: $e');
    }
  }

  void _handleDisputeResolved(Map<String, dynamic>? data) {
    if (data == null) return;
    try {
      final dispute = data['dispute'] as Map<String, dynamic>?;
      final classData = data['class'] as Map<String, dynamic>?;
      
      if (dispute != null && classData != null) {
        final status = dispute['status'] as String? ?? '';
        final className = classData['title']?.toString() ?? 'Aula';
        // final resolution = dispute['adminNotes']?.toString() ?? 'Disputa resolvida';
        
        String notificationTitle;
        String notificationBody;
        
        switch (status) {
          case 'resolved_for_student':
            notificationTitle = 'Disputa resolvida';
            notificationBody = 'Sua disputa sobre "$className" foi resolvida a seu favor';
            break;
          case 'resolved_for_personal':
            notificationTitle = 'Disputa resolvida';
            notificationBody = 'A disputa sobre "$className" foi resolvida a favor do personal';
            break;
          default:
            notificationTitle = 'Disputa resolvida';
            notificationBody = 'A disputa sobre "$className" foi resolvida';
        }
        
        // sl<NotificationService>().showDisputeNotification(
        //   title: notificationTitle,
        //   body: notificationBody,
        // );
        
        debugPrint('✅ RealtimeDataService: Notificação de disputa resolvida exibida');
      }
    } catch (e) {
      debugPrint('⚠️ RealtimeDataService: Erro ao notificar disputa resolvida: $e');
    }
  }

  void _handleDisputeUpdated(Map<String, dynamic>? data) {
    if (data == null) return;
    try {
      final dispute = data['dispute'] as Map<String, dynamic>?;
      final classData = data['class'] as Map<String, dynamic>?;
      
      if (dispute != null && classData != null) {
        final status = dispute['status'] as String? ?? '';
        final className = classData['title']?.toString() ?? 'Aula';
        
        String notificationTitle;
        String notificationBody;
        
        switch (status) {
          case 'student_confirmed_absence':
            notificationTitle = 'Disputa atualizada';
            notificationBody = 'O aluno confirmou a ausência na aula "$className"';
            break;
          case 'student_denied_absence':
            notificationTitle = 'Disputa atualizada';
            notificationBody = 'O aluno negou a ausência na aula "$className"';
            break;
          default:
            notificationTitle = 'Disputa atualizada';
            notificationBody = 'A disputa sobre "$className" foi atualizada';
        }
        
        // sl<NotificationService>().showDisputeNotification(
        //   title: notificationTitle,
        //   body: notificationBody,
        // );
        
        debugPrint('✅ RealtimeDataService: Notificação de disputa atualizada exibida');
      }
    } catch (e) {
      debugPrint('⚠️ RealtimeDataService: Erro ao notificar disputa atualizada: $e');
    }
  }

  void _handleRatingCreated(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('⭐ RealtimeDataService: Avaliação criada');
    
    // Notificar ClassesBloc para atualizar lista de aulas
    _classesBloc?.add(const ClassesRefresh());
    
    // Notificar HomeBloc para atualizar cards de aulas na home
    _homeBloc?.add(const home_events.LoadWorkoutCardData());
    
    debugPrint('✅ RealtimeDataService: ClassesBloc e HomeBloc notificados sobre avaliação criada');
  }

  // ===== PROCESSAMENTO DE CONCLUSÃO DE AULA =====

  void _processClassCompletion(Map<String, dynamic> classData) {
    try {
      final classId = classData['id'] as String?;
      final studentId = classData['studentId'] as String?;
      final personalId = classData['personalId'] as String?;
      
      if (classId == null) {
        debugPrint('❌ RealtimeDataService: ClassId não encontrado');
        return;
      }
      
      debugPrint('🎯 RealtimeDataService: Processando conclusão da aula $classId');
      
      // Processar para o aluno (se disponível)
      if (studentId != null) {
        debugPrint('👨‍🎓 RealtimeDataService: Processando missões para aluno $studentId');
        _gamificationBloc?.add(ProcessClassCompletion(
          userId: studentId,
          classId: classId,
        ));
      }
      
      // Processar para o personal (se disponível)
      if (personalId != null) {
        debugPrint('👨‍🏫 RealtimeDataService: Processando missões para personal $personalId');
        _gamificationBloc?.add(ProcessClassCompletion(
          userId: personalId,
          classId: classId,
        ));
      }
      
      debugPrint('✅ RealtimeDataService: Conclusão de aula processada com sucesso');
    } catch (e) {
      debugPrint('❌ RealtimeDataService: Erro ao processar conclusão: $e');
    }
  }

  // ===== FALLBACK INTELIGENTE (SEM POLLING) =====

  void _scheduleReconnect() {
    // CRÍTICO: Verificar se app está em background ANTES de agendar reconexão
    final wsService = WebSocketService();
    if (wsService.isInBackground) {
      debugPrint('⏸️ [REALTIME] App em background - não agendando reconexão');
      debugPrint('⏸️ [REALTIME] App em background - conexão bloqueada');
      return;
    }
    
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ RealtimeDataService: Máximo de tentativas de reconexão atingido');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectDelay.inSeconds * _reconnectAttempts);
    
    debugPrint('🔄 RealtimeDataService: Tentando reconectar em ${delay.inSeconds}s (tentativa $_reconnectAttempts/$_maxReconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      // Verificar novamente antes de conectar (pode ter mudado)
      if (!wsService.isInBackground) {
        _connect();
      } else {
        debugPrint('⏸️ [REALTIME] App está em background - cancelando reconexão agendada');
      }
    });
  }

  /// Força uma atualização manual (sem polling)
  void forceRefresh() {
    if (!_isConnected) {
      debugPrint('⚠️ RealtimeDataService: WebSocket desconectado, tentando reconectar...');
      _connect();
      return;
    }
    
    debugPrint('🔄 RealtimeDataService: Forçando refresh manual');
    
    // Atualizar todos os BLoCs
    _homeBloc?.add(const home_events.LoadWorkoutCardData());
    _classesBloc?.add(const ClassesRefresh());
    _proposalsBloc?.add(const ProposalsRefresh());
  }

  void _handleFinancialUpdate(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('💰 RealtimeDataService: Atualização financeira');
    
    try {
      final action = data['action'] as String?;
      final userId = data['userId'] as String?;
      final financial = data['financial'] as Map<String, dynamic>?;
      
      debugPrint('💰 [FINANCIAL_UPDATE] Action: $action, UserId: $userId');
      
      // Verificar se é para o usuário atual
      final currentUserId = _getCurrentUserId();
      if (userId != currentUserId) {
        debugPrint('💰 [FINANCIAL_UPDATE] Evento não é para o usuário atual, ignorando');
        return;
      }
      
      switch (action) {
        case 'payment_released':
          _handlePaymentReleased(financial);
          break;
        case 'withdrawal_completed':
          _handleWithdrawalCompleted(financial);
          break;
        case 'payout_processed':
          _handlePayoutProcessed(financial);
          break;
        default:
          debugPrint('💰 [FINANCIAL_UPDATE] Ação desconhecida: $action');
      }
      
      // Notificar HomeBloc para recarregar dados do personal
      _scheduleHomeCardReload(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('⚠️ RealtimeDataService: Erro ao processar atualização financeira: $e');
    }
  }

  void _handlePaymentReleased(Map<String, dynamic>? financial) {
    if (financial == null) return;
    
    try {
      final amount = financial['amount'] as num?;
      final classTitle = financial['classTitle']?.toString() ?? 'aula';
      // final classDate = financial['classDate']?.toString() ?? '';
      
      if (amount != null) {
        final formattedAmount = amount.toStringAsFixed(2).replaceAll('.', ',');
        
        // sl<NotificationService>().showPaymentNotification(
        //   title: '💰 Pagamento recebido',
        //   body: 'R\$ $formattedAmount da sua aula "$classTitle" foi depositado na carteira!',
        //   amount: amount.toDouble(),
        // );
        
        debugPrint('✅ RealtimeDataService: Notificação de pagamento exibida - R\$ $formattedAmount');
      }
    } catch (e) {
      debugPrint('⚠️ RealtimeDataService: Erro ao notificar pagamento: $e');
    }
  }

  void _handleWithdrawalCompleted(Map<String, dynamic>? financial) {
    if (financial == null) return;
    
    try {
      final amount = financial['amount'] as num?;
      final method = financial['method']?.toString() ?? 'conta bancária';
      // final status = financial['status']?.toString() ?? 'concluído';
      
      if (amount != null) {
        final formattedAmount = amount.toStringAsFixed(2).replaceAll('.', ',');
        
        // sl<NotificationService>().showWithdrawalNotification(
        //   title: '💳 Saque realizado',
        //   body: 'R\$ $formattedAmount foi sacado para sua $method com sucesso!',
        //   amount: amount.toDouble(),
        // );
        
        debugPrint('✅ RealtimeDataService: Notificação de saque exibida - R\$ $formattedAmount');
      }
    } catch (e) {
      debugPrint('⚠️ RealtimeDataService: Erro ao notificar saque: $e');
    }
  }

  void _handlePayoutProcessed(Map<String, dynamic>? financial) {
    if (financial == null) return;
    
    try {
      final amount = financial['amount'] as num?;
      final method = financial['method']?.toString() ?? 'conta bancária';
      
      if (amount != null) {
        final formattedAmount = amount.toStringAsFixed(2).replaceAll('.', ',');
        
        // sl<NotificationService>().showPayoutNotification(
        //   title: '🏦 Repasse processado',
        //   body: 'R\$ $formattedAmount foi transferido para sua $method',
        //   amount: amount.toDouble(),
        // );
        
        debugPrint('✅ RealtimeDataService: Notificação de repasse exibida - R\$ $formattedAmount');
      }
    } catch (e) {
      debugPrint('⚠️ RealtimeDataService: Erro ao notificar repasse: $e');
    }
  }


  /// Verifica se está conectado
  bool get isConnected => _isConnected;

  /// Notifica que uma proposta foi criada (chamado pelo CreateProposalPage)
  void notifyProposalCreated({
    required String location,
    required DateTime trainingDate,
    required String trainingTime,
  }) {
    debugPrint('📢 [REALTIME] notifyProposalCreated chamado');
    debugPrint('📢 [REALTIME] Location: $location');
    debugPrint('📢 [REALTIME] TrainingDate: $trainingDate');
    debugPrint('📢 [REALTIME] TrainingTime: $trainingTime');
    
    if (_homeBloc != null && !_homeBloc!.isClosed) {
      debugPrint('📢 [REALTIME] HomeBloc disponível: ${_homeBloc!.hashCode}');
      debugPrint('📢 [REALTIME] HomeBloc estado: ${_homeBloc!.state.runtimeType}');
      
      _homeBloc!.add(home_events.StartProposalSearch(
        location: location,
        trainingDate: trainingDate,
        trainingTime: trainingTime,
      ));
      
      debugPrint('✅ [REALTIME] StartProposalSearch disparado para HomeBloc correto');
    } else {
      debugPrint('❌ [REALTIME] HomeBloc não disponível ou fechado');
    }
    
    // ✅ MELHORIA: Também notificar ProposalSearchBloc para sincronização completa
    if (_proposalSearchBloc != null && !_proposalSearchBloc!.isClosed) {
      debugPrint('📢 [REALTIME] ProposalSearchBloc disponível: ${_proposalSearchBloc!.hashCode}');
      debugPrint('📢 [REALTIME] ProposalSearchBloc estado: ${_proposalSearchBloc!.state.runtimeType}');
      
      _proposalSearchBloc!.add(proposal_search.StartProposalSearch(
        location: location,
        trainingDate: trainingDate,
        trainingTime: trainingTime,
      ));
      
      debugPrint('✅ [REALTIME] StartProposalSearch disparado para ProposalSearchBloc correto');
    } else {
      debugPrint('❌ [REALTIME] ProposalSearchBloc não disponível ou fechado');
    }
  }

  /// Obtém a instância atual do ProposalSearchBloc (para uso em outras páginas)
  proposal_search.ProposalSearchBloc? get proposalSearchBloc => _proposalSearchBloc;

  /// Cancela subscriptions quando app vai para background
  /// Isso previne que mensagens WebSocket sejam processadas em background
  void cancelSubscriptions() {
    debugPrint('⏸️ [REALTIME] Cancelando subscriptions para background...');
    
    // Cancelar subscriptions (mas manter referências para reconectar depois)
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    
    // Cancelar timers de reconexão
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _homeCardReloadDebounce?.cancel();
    _homeCardReloadDebounce = null;
    
    debugPrint('✅ [REALTIME] Subscriptions canceladas - WebSocket não processará mensagens em background');
  }

  /// Restaura subscriptions quando app volta ao foreground
  /// CRÍTICO: Deve ser chamado quando WebSocket reconecta após voltar do background
  void restoreSubscriptions() {
    if (!_isInitialized) {
      debugPrint('⚠️ [REALTIME] Não inicializado - não restaurando subscriptions');
      return;
    }

    debugPrint('🔄 [REALTIME] Restaurando subscriptions após voltar do background...');
    
    // Reconfigurar listeners se WebSocket está conectado
    if (_webSocketService.isConnected) {
      _setupListeners();
      debugPrint('✅ [REALTIME] Subscriptions restauradas - WebSocket conectado');
    } else {
      debugPrint('⚠️ [REALTIME] WebSocket não está conectado - tentando conectar...');
      _connect();
    }
  }

  /// Desconecta e limpa recursos
  void dispose() {
    debugPrint('🗑️ RealtimeDataService: Iniciando limpeza...');
    
    // Cancelar subscriptions
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _homeCardReloadDebounce?.cancel();
    _homeCardReloadDebounce = null;
    
    // Desconectar WebSocket (manual porque é dispose)
    _webSocketService.disconnect(manual: true);
    
    // ⚠️ CORREÇÃO DO BUG: Limpar referências aos BLoCs e dados em cache
    _homeBloc = null;
    _classesBloc = null;
    _proposalsBloc = null;
    _gamificationBloc = null;
    _proposalSearchBloc = null;
    _onClassCreatedCallback = null;
    _pendingMatchData = null;
    
    // Resetar estado
    _isConnected = false;
    _isInitialized = false;
    _reconnectAttempts = 0;
    
    debugPrint('✅ RealtimeDataService: Desconectado e limpo completamente');
  }

  // ===== HANDLERS ADICIONAIS =====
  void _handleProposalAccepted(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('🤝 RealtimeDataService: Proposta aceita');
    _proposalsBloc?.add(const ProposalsRefresh());
    // Encerrar Live Activity — outro personal aceitou
    final proposalId = data['proposal']?['id'] as String? ?? data['proposalId'] as String?;
    LiveActivityService.instance.endActivity(proposalId: proposalId);
    // Não atualiza o card ainda; aguardamos match_confirmed/class_created
  }

  void _scheduleHomeCardReload(Duration delay) {
    _homeCardReloadDebounce?.cancel();
    _homeCardReloadDebounce = Timer(delay, () {
      _safeAddToBloc(_homeBloc, const home_events.LoadWorkoutCardData(), 'HomeBloc');
    });
  }

  /// Atualiza a instância ativa do ProposalsBloc para receber eventos em tempo real
  void attachProposalsBloc(ProposalsBloc bloc) {
    try {
      final old = _proposalsBloc;
      _proposalsBloc = bloc;
      debugPrint('🔗 RealtimeDataService: ProposalsBloc atualizado (old=${old?.hashCode}, new=${bloc.hashCode})');
    } catch (e) {
      debugPrint('⚠️ RealtimeDataService: Falha ao anexar ProposalsBloc: $e');
    }
  }
}

// ===== UTILITÁRIOS SEGUROS PARA EMITIR EVENTOS EM BLoCs =====
/// Evita lançar exceção "Cannot add new events after calling close" ao tentar
/// adicionar eventos em BLoCs já fechados (comuns em callbacks atrasados/Timers).
void _safeAddToBloc(dynamic bloc, dynamic event, String blocName) {
  try {
    if (bloc == null) return;
    final bool isClosed = (bloc.isClosed == true);
    if (isClosed) {
      debugPrint('⚠️ RealtimeDataService: $blocName já foi fechado, ignorando evento ${event.runtimeType}');
      return;
    }
    bloc.add(event);
  } catch (e) {
    debugPrint('⚠️ RealtimeDataService: Falha ao adicionar evento em $blocName: $e');
  }
}
