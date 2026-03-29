import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/services/websocket_service.dart';
import '../../data/services/chat_api_service.dart';
import '../../data/models/chat_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatApiService _chatApiService = sl<ChatApiService>();
  final WebSocketService _ws = sl<WebSocketService>();

  // Estado interno
  List<ChatMessage> _messages = [];
  String? _classId;
  String? _receiverId;
  String? _receiverName;
  bool _showRulesModal = false;

  // Cache para mensagens pendentes (para evitar duplicação)
  final Set<String> _pendingMessageIds = <String>{};
  final Set<String> _sentMessageTexts = <String>{};

  // Subscriptions
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  StreamSubscription<bool>? _connSub;

  ChatBloc() : super(const ChatInitial()) {
    on<ChatInitialize>(_onInitialize);
    on<ChatLoadMessages>(_onLoadMessages);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatMarkAsRead>(_onMarkAsRead);
    on<ChatMarkAllAsRead>(_onMarkAllAsRead);
    on<ChatConnectWebSocket>(_onConnectWebSocket);
    on<ChatDisconnectWebSocket>(_onDisconnectWebSocket);
    on<ChatUpdateFromWebSocket>(_onUpdateFromWebSocket);
    on<ChatJoinClassRoom>(_onJoinClassRoom);
    on<ChatLeaveClassRoom>(_onLeaveClassRoom);
    on<ChatShowRulesModal>(_onShowRulesModal);
    on<ChatHideRulesModal>(_onHideRulesModal);
    on<ChatUpdateWebSocketConnection>(_onUpdateWebSocketConnection);
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    _connSub?.cancel();
    // Limpar cache ao fechar o bloc
    _pendingMessageIds.clear();
    _sentMessageTexts.clear();
    return super.close();
  }

  Future<void> _onInitialize(
    ChatInitialize event,
    Emitter<ChatState> emit,
  ) async {
    try {
      debugPrint('💬 [CHAT BLOC] Inicializando chat - ClassId: ${event.classId}');
      _classId = event.classId;
      _receiverId = event.receiverId;
      _receiverName = event.receiverName;
      _showRulesModal = true; // Mostrar modal de regras ao inicializar

      debugPrint('💬 [CHAT BLOC] Emitindo ChatLoaded inicial');
      if (!isClosed) {
        emit(ChatLoaded(
          messages: _messages,
          classId: _classId!,
          receiverId: _receiverId!,
          receiverName: _receiverName!,
          showRulesModal: _showRulesModal,
        ));

        // Carregar mensagens
        debugPrint('💬 [CHAT BLOC] Adicionando ChatLoadMessages');
        add(const ChatLoadMessages());

        // Conectar WebSocket
        debugPrint('💬 [CHAT BLOC] Adicionando ChatConnectWebSocket');
        add(const ChatConnectWebSocket());
      }
    } catch (e) {
      debugPrint('❌ [CHAT BLOC] Erro ao inicializar: $e');
      if (!isClosed) {
        emit(ChatError(
          message: 'Erro ao inicializar chat: $e',
          messages: _messages,
        ));
      }
    }
  }

  Future<void> _onLoadMessages(
    ChatLoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (_classId == null) return;

    try {
      if (!isClosed) {
        emit(ChatLoaded(
          messages: _messages,
          classId: _classId!,
          receiverId: _receiverId!,
          receiverName: _receiverName!,
          isLoading: true,
          showRulesModal: _showRulesModal,
        ));
      }

      final messages = await _chatApiService.getMessages(_classId!);
      debugPrint('💬 [CHAT BLOC] Mensagens carregadas: ${messages.length}');
      for (int i = 0; i < messages.length; i++) {
        debugPrint('💬 [CHAT BLOC] Mensagem $i: ${messages[i].messageText} - ${messages[i].sentAt}');
      }
      _messages = messages;

      if (!isClosed) {
        emit(ChatLoaded(
          messages: _messages,
          classId: _classId!,
          receiverId: _receiverId!,
          receiverName: _receiverName!,
          isLoading: false,
          showRulesModal: _showRulesModal,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(ChatError(
          message: 'Erro ao carregar mensagens: $e',
          messages: _messages,
        ));
      }
    }
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (_classId == null || _receiverId == null) return;

    try {
      debugPrint('💬 [CHAT BLOC] Enviando mensagem: ${event.messageText}');
      debugPrint('💬 [CHAT BLOC] Mensagens antes: ${_messages.length}');

      // Marcar mensagem como pendente para evitar duplicação via WebSocket
      _sentMessageTexts.add(event.messageText);
      debugPrint('💬 [CHAT BLOC] Mensagem marcada como pendente: ${event.messageText}');

      final messageDto = SendMessageDto(
        classId: _classId!,
        receiverId: _receiverId!,
        messageText: event.messageText,
      );

      final newMessage = await _chatApiService.sendMessage(messageDto);
      
      // Verificar se o bloc ainda está ativo antes de continuar
      if (isClosed) {
        debugPrint('💬 [CHAT BLOC] Bloc fechado, cancelando operação');
        return;
      }
      
      // Marcar mensagem como processada
      _pendingMessageIds.add(newMessage.id);
      _sentMessageTexts.remove(event.messageText);
      debugPrint('💬 [CHAT BLOC] Mensagem processada, ID: ${newMessage.id}');
      
      // Verificar se a mensagem já não foi adicionada via WebSocket
      final alreadyExists = _messages.any((msg) => msg.id == newMessage.id);
      if (!alreadyExists) {
        // IMPORTANTE: Criar uma NOVA lista ao invés de modificar a existente
        _messages = [..._messages, newMessage];

        debugPrint('💬 [CHAT BLOC] Mensagem adicionada: ${newMessage.messageText}');
        debugPrint('💬 [CHAT BLOC] Mensagens depois: ${_messages.length}');
        debugPrint('💬 [CHAT BLOC] Emitindo ChatLoaded com ${_messages.length} mensagens');

        if (!isClosed) {
          emit(ChatLoaded(
            messages: _messages,
            classId: _classId!,
            receiverId: _receiverId!,
            receiverName: _receiverName!,
            showRulesModal: _showRulesModal,
          ));
        }
      } else {
        debugPrint('💬 [CHAT BLOC] Mensagem já existe via WebSocket, não adicionando novamente');
      }
      
      debugPrint('💬 [CHAT BLOC] Mensagem enviada via API REST (WebSocket será emitido automaticamente pelo backend)');
    } catch (e) {
      // Remover do cache em caso de erro
      _sentMessageTexts.remove(event.messageText);
      debugPrint('❌ [CHAT BLOC] Erro ao enviar mensagem: $e');
      if (!isClosed) {
        emit(ChatError(
          message: 'Erro ao enviar mensagem: $e',
          messages: _messages,
        ));
      }
    }
  }

  Future<void> _onMarkAsRead(
    ChatMarkAsRead event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatApiService.markAsRead(event.messageId);

      // Atualizar mensagem local - criar nova lista
      final index = _messages.indexWhere((msg) => msg.id == event.messageId);
      if (index != -1) {
        // IMPORTANTE: Criar uma NOVA lista ao invés de modificar a existente
        final updatedMessages = List<ChatMessage>.from(_messages);
        updatedMessages[index] = ChatMessage(
          id: _messages[index].id,
          classId: _messages[index].classId,
          senderId: _messages[index].senderId,
          receiverId: _messages[index].receiverId,
          messageText: _messages[index].messageText,
          sentAt: _messages[index].sentAt,
          isRead: true,
          createdAt: _messages[index].createdAt,
          updatedAt: _messages[index].updatedAt,
          sender: _messages[index].sender,
        );
        _messages = updatedMessages;
      }

      if (!isClosed) {
        emit(ChatLoaded(
          messages: _messages,
          classId: _classId!,
          receiverId: _receiverId!,
          receiverName: _receiverName!,
          showRulesModal: _showRulesModal,
        ));
      }
    } catch (e) {
      print('❌ [CHAT BLOC] Erro ao marcar como lida: $e');
    }
  }

  Future<void> _onMarkAllAsRead(
    ChatMarkAllAsRead event,
    Emitter<ChatState> emit,
  ) async {
    if (_classId == null) return;

    try {
      await _chatApiService.markAllAsRead(_classId!);

      // Atualizar todas as mensagens como lidas
      _messages = _messages.map((msg) => ChatMessage(
        id: msg.id,
        classId: msg.classId,
        senderId: msg.senderId,
        receiverId: msg.receiverId,
        messageText: msg.messageText,
        sentAt: msg.sentAt,
        isRead: true,
        createdAt: msg.createdAt,
        updatedAt: msg.updatedAt,
        sender: msg.sender,
      )).toList();

      if (!isClosed) {
        emit(ChatLoaded(
          messages: _messages,
          classId: _classId!,
          receiverId: _receiverId!,
          receiverName: _receiverName!,
          showRulesModal: _showRulesModal,
        ));
      }
    } catch (e) {
      print('❌ [CHAT BLOC] Erro ao marcar todas como lidas: $e');
    }
  }

  Future<void> _onConnectWebSocket(
    ChatConnectWebSocket event,
    Emitter<ChatState> emit,
  ) async {
    debugPrint('💬 [CHAT BLOC] Conectando WebSocket...');
    debugPrint('💬 [CHAT BLOC] WebSocket já conectado: ${_ws.isConnected}');
    
    // Conectar ao WebSocket
    await _ws.connect();
    
    // Aguarda a conexão estabilizar completamente para evitar race com join
    await Future.delayed(const Duration(milliseconds: 1000));
    
    debugPrint('💬 [CHAT BLOC] WebSocket conectado após connect(): ${_ws.isConnected}');
    
    // Conexão
    _connSub?.cancel();
    _connSub = _ws.connectionStream.listen((connected) {
      debugPrint('💬 [CHAT BLOC] WebSocket conectado: $connected');
      // Usar add ao invés de emit diretamente para evitar erro de emit após handler completar
      if (!isClosed) {
        add(ChatUpdateWebSocketConnection(connected));
      }
    });

    // Mensagens
    _wsSub?.cancel();
    _wsSub = _ws.messageStream.listen((message) {
      debugPrint('💬 [CHAT BLOC] Mensagem WebSocket recebida: ${message['type']}');
      debugPrint('💬 [CHAT BLOC] Conteúdo completo da mensagem: $message');
      final type = message['type'] as String?;
      if (type == 'message_received' || type == 'new_message' || type == 'message_sent') {
        debugPrint('💬 [CHAT BLOC] Processando mensagem de chat: $type');
        add(ChatUpdateFromWebSocket(message));
      } else if (type == 'joined_class') {
        debugPrint('💬 [CHAT BLOC] Confirmação de entrada na sala recebida');
      } else if (type == 'left_class') {
        debugPrint('💬 [CHAT BLOC] Confirmação de saída da sala recebida');
      } else {
        debugPrint('💬 [CHAT BLOC] Ignorando mensagem de tipo: $type');
      }
    });

    // Entrar na sala da classe
    add(const ChatJoinClassRoom());
  }

  Future<void> _onDisconnectWebSocket(
    ChatDisconnectWebSocket event,
    Emitter<ChatState> emit,
  ) async {
    await _wsSub?.cancel();
    await _connSub?.cancel();

    // Sair da sala da classe
    add(const ChatLeaveClassRoom());

    final current = state;
    if (current is ChatLoaded) {
      emit(current.copyWith(isWebSocketConnected: false));
    }
  }

  Future<void> _onUpdateFromWebSocket(
    ChatUpdateFromWebSocket event,
    Emitter<ChatState> emit,
  ) async {
    debugPrint('💬 [CHAT BLOC] Processando mensagem WebSocket...');
    debugPrint('💬 [CHAT BLOC] Dados recebidos: ${event.data}');
    
    if (state is! ChatLoaded) {
      debugPrint('💬 [CHAT BLOC] Estado não é ChatLoaded, ignorando');
      return;
    }

    try {
      Map<String, dynamic>? messageData;
      
      // Para new_message: { type: 'new_message', data: { classId, message: {...}, timestamp } }
      if (event.data['data'] is Map<String, dynamic>) {
        final data = event.data['data'] as Map<String, dynamic>;
        
        // Extrair o objeto 'message' de dentro de 'data'
        if (data['message'] is Map<String, dynamic>) {
          messageData = data['message'] as Map<String, dynamic>;
          debugPrint('💬 [CHAT BLOC] Usando estrutura event.data[\'data\'][\'message\'] (new_message)');
        } else {
          // Fallback: data já é a mensagem (para message_sent/message_received)
          messageData = data;
          debugPrint('💬 [CHAT BLOC] Usando estrutura event.data[\'data\'] diretamente');
        }
      }
      // Estrutura alternativa: event.data['message']
      else if (event.data['message'] is Map<String, dynamic>) {
        messageData = event.data['message'] as Map<String, dynamic>;
        debugPrint('💬 [CHAT BLOC] Usando estrutura event.data[\'message\']');
      }
      // Fallback: usar event.data diretamente
      else {
        messageData = event.data;
        debugPrint('💬 [CHAT BLOC] Usando event.data diretamente (fallback)');
      }

      debugPrint('💬 [CHAT BLOC] Dados finais para parsing: $messageData');
      debugPrint('💬 [CHAT BLOC] Criando ChatMessage a partir dos dados');
      
      // Corrigir campos nulos que podem vir do WebSocket
      if (messageData['receiverId'] == null) {
        messageData['receiverId'] = _receiverId ?? '';
        debugPrint('💬 [CHAT BLOC] receiverId corrigido para: ${messageData['receiverId']}');
      }
      
      final message = ChatMessage.fromJson(messageData);
      
      debugPrint('💬 [CHAT BLOC] Mensagem criada: ${message.messageText}');
      debugPrint('💬 [CHAT BLOC] ClassId da mensagem: ${message.classId}');
      debugPrint('💬 [CHAT BLOC] ClassId atual: $_classId');
      
      // Garantir que a mensagem é da classe atual
      if (_classId != null && message.classId != _classId) {
        debugPrint('💬 [CHAT BLOC] Mensagem de outra classe (${message.classId}), ignorando');
        return;
      }
      
      // Verificar se é uma mensagem que acabamos de enviar (para evitar duplicação)
      final isMessageWeJustSent = _sentMessageTexts.contains(message.messageText) || 
                                  _pendingMessageIds.contains(message.id);
      
      if (isMessageWeJustSent) {
        debugPrint('💬 [CHAT BLOC] Mensagem que acabamos de enviar via WebSocket, ignorando para evitar duplicação');
        debugPrint('💬 [CHAT BLOC] ID: ${message.id}, Texto: ${message.messageText}');
        return;
      }
      
      // Verificar se é uma nova mensagem usando múltiplos critérios para evitar duplicação
      final isDuplicate = _messages.any((msg) => 
        msg.id == message.id || 
        (msg.messageText == message.messageText && 
         msg.senderId == message.senderId && 
         msg.sentAt.difference(message.sentAt).abs().inSeconds < 5)
      );
      
      if (!isDuplicate) {
        debugPrint('💬 [CHAT BLOC] Nova mensagem detectada, adicionando...');
        
        // IMPORTANTE: Criar uma NOVA lista ao invés de modificar a existente
        _messages = [..._messages, message];
        
        debugPrint('💬 [CHAT BLOC] Emitindo ChatLoaded com ${_messages.length} mensagens');
        
        if (!isClosed) {
          emit(ChatLoaded(
            messages: _messages,
            classId: _classId!,
            receiverId: _receiverId!,
            receiverName: _receiverName!,
            showRulesModal: _showRulesModal,
          ));
        }
      } else {
        debugPrint('💬 [CHAT BLOC] Mensagem duplicada detectada, ignorando');
        debugPrint('💬 [CHAT BLOC] ID: ${message.id}, Texto: ${message.messageText}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [CHAT BLOC] Erro ao processar mensagem WebSocket: $e');
      debugPrint('❌ [CHAT BLOC] Stack trace: $stackTrace');
    }
  }

  Future<void> _onJoinClassRoom(
    ChatJoinClassRoom event,
    Emitter<ChatState> emit,
  ) async {
    if (_classId == null) return;

    try {
      debugPrint('💬 [CHAT BLOC] Tentando entrar na sala da classe: $_classId');
      debugPrint('💬 [CHAT BLOC] WebSocket conectado: ${_ws.isConnected}');
      
      // Enviar comando para entrar na sala via WebSocket
      _ws.emit('join_class', {
        'classId': _classId,
      });
      
      debugPrint('💬 [CHAT BLOC] Comando join_class enviado para: $_classId');
      
      // Aguardar um pouco para garantir que a conexão foi estabelecida
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('💬 [CHAT BLOC] Sala da classe configurada com sucesso');
    } catch (e) {
      debugPrint('❌ [CHAT BLOC] Erro ao entrar na sala: $e');
    }
  }

  Future<void> _onLeaveClassRoom(
    ChatLeaveClassRoom event,
    Emitter<ChatState> emit,
  ) async {
    if (_classId == null) return;

    try {
      // Enviar comando para sair da sala via WebSocket
      _ws.emit('leave_class', {
        'classId': _classId,
      });
      
      debugPrint('💬 [CHAT BLOC] Saiu da sala da classe: $_classId');
    } catch (e) {
      debugPrint('❌ [CHAT BLOC] Erro ao sair da sala: $e');
    }
  }

  Future<void> _onShowRulesModal(
    ChatShowRulesModal event,
    Emitter<ChatState> emit,
  ) async {
    _showRulesModal = true;
    
    final current = state;
    if (current is ChatLoaded && !isClosed) {
      emit(current.copyWith(showRulesModal: true));
    }
  }

  Future<void> _onHideRulesModal(
    ChatHideRulesModal event,
    Emitter<ChatState> emit,
  ) async {
    _showRulesModal = false;
    
    final current = state;
    if (current is ChatLoaded && !isClosed) {
      emit(current.copyWith(showRulesModal: false));
    }
  }

  Future<void> _onUpdateWebSocketConnection(
    ChatUpdateWebSocketConnection event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is ChatLoaded && !isClosed) {
      emit(current.copyWith(isWebSocketConnected: event.isConnected));
    }
  }
}
