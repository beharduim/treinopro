import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../features/home/data/services/auth_service.dart';
import '../di/dependency_injection.dart' as di;
import '../config/app_config.dart';

/// Serviço para gerenciar conexões WebSocket
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  StreamController<Map<String, dynamic>>? _messageController;
  StreamController<bool>? _connectionController;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  
  // Controle de lifecycle do app
  bool _isManuallyDisconnected = false; // Flag para distinguir desconexão manual vs lifecycle
  bool _wasConnectedBeforeBackground = false; // Lembra se estava conectado antes de ir para background
  bool _isInBackground = false; // Flag para saber se app está em background

  AuthService? _authService;

  /// Stream de mensagens recebidas
  Stream<Map<String, dynamic>> get messageStream {
    _messageController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _messageController!.stream;
  }

  /// Stream de status de conexão
  Stream<bool> get connectionStream {
    _connectionController ??= StreamController<bool>.broadcast();
    return _connectionController!.stream;
  }

  /// Verifica se está conectado
  bool get isConnected => _isConnected;
  
  /// Verifica se app está em background (baseado no lifecycle)
  bool get isInBackground => _isInBackground;

  /// Inicializa o serviço com dependências
  void initialize(AuthService authService) {
    _authService = authService;
  }

  /// Conecta ao WebSocket
  Future<void> connect() async {
    // Garantir que flag está correta ao conectar (app deve estar em foreground)
    _isInBackground = false;
    
    // CRÍTICO: Não conectar se app está em background
    if (_isInBackground) {
      debugPrint('⏸️ [WEBSOCKET] App em background - conexão bloqueada');
      return;
    }
    
    if (_isConnected) {
      debugPrint('🔌 WebSocket: Já conectado, ignorando nova conexão');
      return;
    }

    try {
      debugPrint('🔌 WebSocket: Iniciando conexão...');
      
      // Garantir AuthService inicializado
      final auth = _authService ?? di.sl<AuthService>();
      _authService = auth;
      debugPrint('🔌 WebSocket: AuthService obtido');
      
      // CRÍTICO: Verificar userId antes de conectar
      final currentUserId = auth.currentUserId;
      debugPrint('🔌 WebSocket: UserId atual no AuthService: $currentUserId');

      final token = await auth.getValidToken();
      if (token == null) {
        debugPrint('❌ WebSocket: Token não disponível - usuário não autenticado');
        return;
      }
      debugPrint('🔌 WebSocket: Token obtido: ${token.substring(0, 20)}...');
      
      // Decodificar token para verificar userId
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalized));
          final Map<String, dynamic> tokenData = json.decode(decoded);
          final tokenUserId = tokenData['sub'];
          debugPrint('🔌 WebSocket: UserId no token: $tokenUserId');
          
          if (tokenUserId != currentUserId) {
            debugPrint('❌ WebSocket: ERRO - Token com userId diferente do AuthService!');
            debugPrint('❌ WebSocket: Token userId: $tokenUserId');
            debugPrint('❌ WebSocket: AuthService userId: $currentUserId');
            debugPrint('❌ WebSocket: ABORTANDO CONEXÃO - Token inválido');
            return;
          }
        }
      } catch (e) {
        debugPrint('⚠️ WebSocket: Erro ao decodificar token: $e');
      }

      final baseUrl = AppConfig.apiBaseUrl;
      final namespace = '/chat';

      debugPrint('🔌 Socket.IO: AppConfig.apiBaseUrl = $baseUrl');
      debugPrint('🔌 Socket.IO: Conectando em $baseUrl com namespace $namespace');

      _socket = IO.io(
        baseUrl + namespace,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setQuery({'token': token})
            .setAuth({'token': token})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .setPath('/socket.io/')
            .build(),
      );

      _socket!.onConnect((_) {
        try {
          _isConnected = true;
          _reconnectAttempts = 0;
          debugPrint('✅ Socket.IO: Conectado');
          final sid = _socket?.id;
          final nsp = _socket?.nsp;
          debugPrint('🔌 Socket.IO: Socket ID: ${sid ?? '-'}');
          debugPrint('🔌 Socket.IO: Namespace: ${nsp ?? '-'}');
          _connectionController ??= StreamController<bool>.broadcast();
          _connectionController!.add(true);
          
          // CORREÇÃO: Não precisa restaurar subscriptions manualmente
          // As subscriptions do RealtimeDataService continuam ativas mesmo quando WebSocket desconecta
          // Quando o WebSocket reconecta, elas voltam a funcionar automaticamente
        } catch (e) {
          debugPrint('⚠️ Socket.IO: onConnect handler error: $e');
        }
      });

      _socket!.onDisconnect((_) {
        debugPrint('🔌 Socket.IO: Desconectado');
        _isConnected = false;
        _connectionController?.add(false);
        
        // CRÍTICO: Não reconectar automaticamente se app está em background
        // Isso permite que FCM funcione corretamente
        if (!_isInBackground && _shouldReconnect) {
          debugPrint('🔄 [WEBSOCKET] App em foreground - agendando reconexão...');
          _scheduleReconnect();
        } else {
          debugPrint('⏸️ [WEBSOCKET] App em background ou reconexão desabilitada - NÃO reconectando');
        }
      });

      _socket!.onError((err) {
        debugPrint('❌ Socket.IO: Erro de conexão: $err');
        _onError(err);
      });
      _socket!.on('message', (data) => _onMessage(data));
      _socket!.on('user_online', (data) => _onMessage({'type': 'user_online', 'data': data}));
      _socket!.on('user_offline', (data) => _onMessage({'type': 'user_offline', 'data': data}));
      _socket!.on('message_sent', (data) => _onMessage({'type': 'message_sent', 'data': data}));
      _socket!.on('message_received', (data) => _onMessage({'type': 'message_received', 'data': data}));
      // Mensagens emitidas para a sala da aula (room class_<id>)
      _socket!.on('new_message', (data) {
        debugPrint('📥 [WEBSOCKET] Evento new_message recebido: $data');
        _onMessage({'type': 'new_message', 'data': data});
      });
      
      // Confirmação de entrada na sala
      _socket!.on('joined_class', (data) {
        debugPrint('✅ [WEBSOCKET] Entrou na sala da classe: $data');
      });
      
      // Confirmação de saída da sala
      _socket!.on('left_class', (data) {
        debugPrint('❌ [WEBSOCKET] Saiu da sala da classe: $data');
      });

      // Gamificação: eventos em tempo real
      _socket!.on('profile_update', (data) => _onMessage({'type': 'profile_update', 'data': data}));
      _socket!.on('mission_completed', (data) {
        debugPrint('🎯 [WEBSOCKET] Evento mission_completed recebido: $data');
        _onMessage({'type': 'mission_completed', 'data': data});
      });
      _socket!.on('mission_assigned', (data) {
        debugPrint('🎯 [WEBSOCKET] Evento mission_assigned recebido: $data');
        _onMessage({'type': 'mission_assigned', 'data': data});
      });
      _socket!.on('class_update', (data) {
        debugPrint('📥 [WEBSOCKET] Evento class_update recebido: $data');
        _onMessage({'type': 'class_update', 'data': data});
      });
      _socket!.on('class_created', (data) {
        debugPrint('📥 [WEBSOCKET] Evento class_created recebido: $data');
        _onMessage({'type': 'class_created', 'data': data});
      });
      _socket!.on('proposal_update', (data) => _onMessage({'type': 'proposal_update', 'data': data}));
      _socket!.on('proposal_created', (data) {
        debugPrint('🔔 [WEBSOCKET] Evento proposal_created recebido: $data');
        _onMessage({'type': 'proposal_created', 'data': data});
      });
      _socket!.on('proposal_accepted', (data) {
        debugPrint('🤝 [WEBSOCKET] Evento proposal_accepted recebido: $data');
        _onMessage({'type': 'proposal_accepted', 'data': data});
      });
      _socket!.on('proposal_expired', (data) {
        debugPrint('🗑️ [WEBSOCKET] Evento proposal_expired recebido: $data');
        _onMessage({'type': 'proposal_expired', 'data': data});
      });
      _socket!.on('new_proposal', (data) {
        debugPrint('🔔 [WEBSOCKET] Evento new_proposal recebido: $data');
        _onMessage({'type': 'new_proposal', 'data': data});
      });
      _socket!.on('match_confirmed', (data) => _onMessage({'type': 'match_confirmed', 'data': data}));
      
      // Eventos de avaliações
      _socket!.on('rating_created', (data) {
        debugPrint('⭐ [WEBSOCKET] Evento rating_created recebido: $data');
        _onMessage({'type': 'rating_created', 'data': data});
      });
      
      // Eventos de timer
      _socket!.on('class_timer_started', (data) {
        debugPrint('🕐 [WEBSOCKET] Evento class_timer_started recebido: $data');
        _onMessage({'type': 'class_timer_started', 'data': data});
      });
      
      _socket!.on('class_timer_expired', (data) {
        debugPrint('⏰ [WEBSOCKET] Evento class_timer_expired recebido: $data');
        _onMessage({'type': 'class_timer_expired', 'data': data});
      });

      // Eventos financeiros
      _socket!.on('financial_update', (data) {
        debugPrint('💰 [WEBSOCKET] Evento financial_update recebido: $data');
        _onMessage({'type': 'financial_update', 'data': data});
      });

      // Eventos de disputas
      _socket!.on('dispute_created', (data) {
        debugPrint('⚖️ [WEBSOCKET] Evento dispute_created recebido: $data');
        _onMessage({'type': 'dispute_created', 'data': data});
      });
      
      _socket!.on('dispute_resolved', (data) {
        debugPrint('✅ [WEBSOCKET] Evento dispute_resolved recebido: $data');
        _onMessage({'type': 'dispute_resolved', 'data': data});
      });
      
      _socket!.on('dispute_updated', (data) {
        debugPrint('🔄 [WEBSOCKET] Evento dispute_updated recebido: $data');
        _onMessage({'type': 'dispute_updated', 'data': data});
      });

      debugPrint('🔌 Socket.IO: Iniciando conexão...');
      _socket!.connect();

    } catch (e) {
      debugPrint('❌ WebSocket: Erro ao conectar - $e');
      _scheduleReconnect();
    }
  }

  /// Desconecta do WebSocket
  Future<void> disconnect({bool manual = false}) async {
    _isManuallyDisconnected = manual;
    
    if (manual) {
      // Desconexão manual - não reconectar automaticamente
      _shouldReconnect = false;
    } else {
      // Desconexão automática - pode reconectar depois
      _shouldReconnect = true;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    // CRÍTICO: Desconectar Socket.IO corretamente antes de dispose
    if (_socket != null) {
      try {
        // Desconectar explicitamente (remove todos os listeners e fecha conexão)
        if (_socket!.connected) {
          _socket!.disconnect();
          debugPrint('🔌 [WEBSOCKET] Socket.IO desconectado explicitamente');
        }
        
        // Remover todos os listeners do Socket.IO
        // O dispose() não remove listeners, então precisamos fazer isso manualmente
        _socket!.clearListeners();
        debugPrint('🔌 [WEBSOCKET] Listeners do Socket.IO removidos');
        
        // Finalmente, dispose do socket
        _socket!.dispose();
        debugPrint('🔌 [WEBSOCKET] Socket.IO dispose() executado');
      } catch (e) {
        debugPrint('⚠️ [WEBSOCKET] Erro ao desconectar Socket.IO: $e');
      } finally {
        _socket = null;
      }
    }
    
    _isConnected = false;
    debugPrint('🔌 [WEBSOCKET] WebSocket desconectado${manual ? " (manual)" : ""}');
  }
  
  /// Gerencia conexão baseado no lifecycle do app
  /// Quando app vai para background, desconecta para economizar recursos
  /// Quando app volta ao foreground, reconecta para atualizações em tempo real
  void handleAppLifecycleChange(String state) {
    debugPrint('🔄 [WEBSOCKET] handleAppLifecycleChange chamado: $state');
    debugPrint('🔄 [WEBSOCKET] Estado atual: _isConnected=$_isConnected, _wasConnectedBeforeBackground=$_wasConnectedBeforeBackground, _isManuallyDisconnected=$_isManuallyDisconnected');
    
    if (state == 'paused' || state == 'inactive') {
      // App está indo para background
      _isInBackground = true; // CRÍTICO: Marcar que app está em background
      debugPrint('⏸️ [WEBSOCKET] App indo para background - state: $state');
      
      // Cancelar qualquer reconexão agendada
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      debugPrint('⏸️ [WEBSOCKET] Cancelando reconexões automáticas agendadas');
      
      if (_isConnected) {
        _wasConnectedBeforeBackground = true;
        debugPrint('📱 [WEBSOCKET] App em background - desconectando WebSocket');
        
        // CORREÇÃO: Não cancelar subscriptions - quando WebSocket desconecta,
        // as subscriptions simplesmente não recebem mensagens.
        // Quando reconecta, elas voltam a funcionar automaticamente.
        // Isso evita o problema de ter que restaurar manualmente.
        
        disconnect(manual: false); // Não é manual, é automático por lifecycle
        debugPrint('✅ [WEBSOCKET] WebSocket desconectado com sucesso');
      } else {
        _wasConnectedBeforeBackground = false;
        debugPrint('📱 [WEBSOCKET] App em background - WebSocket já estava desconectado');
      }
    } else if (state == 'resumed') {
      // App voltou ao foreground
      _isInBackground = false; // CRÍTICO: Marcar que app voltou ao foreground
      debugPrint('✅ [WEBSOCKET] App voltou ao foreground');
      
      // ✅ CORREÇÃO CRÍTICA: Sempre tentar reconectar quando app volta ao foreground,
      // exceto se foi desconexão manual. Isso garante que propostas sejam recebidas
      // mesmo após hibernação do celular.
      if (!_isConnected && !_isManuallyDisconnected) {
        debugPrint('📱 [WEBSOCKET] App em foreground - agendando reconexão do WebSocket...');
        debugPrint('📱 [WEBSOCKET] _wasConnectedBeforeBackground=$_wasConnectedBeforeBackground');
        _wasConnectedBeforeBackground = false;
        _shouldReconnect = true;
        _reconnectAttempts = 0;
        
        // ✅ CORREÇÃO: Delay reduzido para melhorar responsividade
        // Reduzido de 500ms para 200ms para reconexão mais rápida
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!_isInBackground && !_isConnected && !_isManuallyDisconnected) {
            debugPrint('📱 [WEBSOCKET] Executando reconexão após delay...');
            // Conectar - o onConnect vai notificar RealtimeDataService automaticamente
            connect();
          } else {
            debugPrint('📱 [WEBSOCKET] Condições mudaram - cancelando reconexão agendada');
          }
        });
      } else if (_isConnected) {
        // WebSocket já está conectado - subscriptions já estão ativas e funcionando
        debugPrint('📱 [WEBSOCKET] App em foreground - WebSocket já conectado, subscriptions ativas');
      } else {
        debugPrint('📱 [WEBSOCKET] App em foreground - WebSocket não reconectando (desconexão manual)');
        debugPrint('📱 [WEBSOCKET] _isManuallyDisconnected=$_isManuallyDisconnected');
      }
    } else {
      debugPrint('ℹ️ [WEBSOCKET] Estado do lifecycle não tratado: $state');
    }
  }

  /// Envia uma mensagem
  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected || _socket == null) {
      debugPrint('❌ WebSocket: Não conectado, não é possível enviar mensagem');
      return;
    }

    try {
      _socket!.emit('message', message);
      debugPrint('📤 Socket.IO: Mensagem emitida - ${message['type']}');
    } catch (e) {
      debugPrint('❌ WebSocket: Erro ao enviar mensagem - $e');
    }
  }

  /// Emite um evento customizado diretamente
  /// CRÍTICO: Bloqueia emit em background para economizar recursos
  void emit(String event, Map<String, dynamic> data) {
    // CRÍTICO: Não emitir eventos se app está em background
    if (_isInBackground) {
      debugPrint('⏸️ [WEBSOCKET] App em background - bloqueando emit($event)');
      debugPrint('⏸️ [WEBSOCKET] App em background - operação bloqueada');
      return;
    }
    
    if (!_isConnected || _socket == null) {
      debugPrint('❌ WebSocket: Não conectado, não é possível emitir $event');
      return;
    }
    try {
      _socket!.emit(event, data);
      debugPrint('📤 Socket.IO: Evento "$event" emitido com payload: $data');
    } catch (e) {
      debugPrint('❌ WebSocket: Erro ao emitir $event - $e');
    }
  }

  /// Processa mensagem recebida
  void _onMessage(dynamic data) {
    try {
      Map<String, dynamic> message;
      if (data is String) {
        message = json.decode(data) as Map<String, dynamic>;
      } else if (data is Map) {
        message = Map<String, dynamic>.from(data);
      } else {
        debugPrint('❌ WebSocket: Tipo de mensagem não suportado: ${data.runtimeType}');
        return;
      }

      debugPrint('📥 [WEBSOCKET] Mensagem processada - tipo: ${message['type']}, dados: ${message['data']}');
      _messageController?.add(message);
    } catch (e) {
      debugPrint('❌ WebSocket: Erro ao processar mensagem - $e');
    }
  }

  /// Trata erros de conexão
  void _onError(dynamic error) {
    debugPrint('❌ WebSocket: Erro - $error');
    _isConnected = false;
    _connectionController?.add(false);
    
    // CRÍTICO: Não reconectar automaticamente se app está em background
    if (_isInBackground) {
      debugPrint('⏸️ [WEBSOCKET] App em background - não reconectando após erro');
      debugPrint('⏸️ [WEBSOCKET] App em background - operação bloqueada');
      return;
    }
    
    // Apenas agendar reconexão se app está em foreground
    _scheduleReconnect();
  }

  // Removido: _onDisconnected não é mais usado com Socket.IO

  /// Agenda reconexão
  void _scheduleReconnect() {
    // CRÍTICO: Não reconectar se app está em background
    if (_isInBackground) {
      debugPrint('⏸️ [WEBSOCKET] App em background - cancelando reconexão automática');
      return;
    }
    
    if (!_shouldReconnect || _reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ WebSocket: Máximo de tentativas de reconexão atingido ou reconexão desabilitada');
      return;
    }

    _reconnectAttempts++;
    debugPrint('🔄 WebSocket: Tentativa de reconexão $_reconnectAttempts/$_maxReconnectAttempts em ${_reconnectDelay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      // Verificar novamente antes de conectar (pode ter mudado)
      if (!_isInBackground) {
        connect();
      } else {
        debugPrint('⏸️ [WEBSOCKET] App está em background - cancelando reconexão agendada');
      }
    });
  }

  /// Reinicia a conexão
  Future<void> reconnect() async {
    await disconnect(manual: false); // Reconexão automática, não manual
    _shouldReconnect = true;
    _reconnectAttempts = 0;
    _isManuallyDisconnected = false; // Reset flag
    await connect();
  }

  /// Dispose do serviço
  void dispose() {
    _shouldReconnect = false;
    _isManuallyDisconnected = true; // Marcar como desconexão manual no dispose
    _reconnectTimer?.cancel();
    _messageController?.close();
    _connectionController?.close();
    _socket?.dispose();
  }
}
