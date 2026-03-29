import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Inicializar chat
class ChatInitialize extends ChatEvent {
  final String classId;
  final String receiverId;
  final String receiverName;

  const ChatInitialize({
    required this.classId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  List<Object?> get props => [classId, receiverId, receiverName];
}

/// Carregar mensagens
class ChatLoadMessages extends ChatEvent {
  const ChatLoadMessages();
}

/// Enviar mensagem
class ChatSendMessage extends ChatEvent {
  final String messageText;

  const ChatSendMessage(this.messageText);

  @override
  List<Object?> get props => [messageText];
}

/// Marcar mensagem como lida
class ChatMarkAsRead extends ChatEvent {
  final String messageId;

  const ChatMarkAsRead(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

/// Marcar todas as mensagens como lidas
class ChatMarkAllAsRead extends ChatEvent {
  const ChatMarkAllAsRead();
}

/// Conectar ao WebSocket
class ChatConnectWebSocket extends ChatEvent {
  const ChatConnectWebSocket();
}

/// Desconectar do WebSocket
class ChatDisconnectWebSocket extends ChatEvent {
  const ChatDisconnectWebSocket();
}

/// Atualizar do WebSocket
class ChatUpdateFromWebSocket extends ChatEvent {
  final Map<String, dynamic> data;

  const ChatUpdateFromWebSocket(this.data);

  @override
  List<Object?> get props => [data];
}

/// Entrar na sala da classe
class ChatJoinClassRoom extends ChatEvent {
  const ChatJoinClassRoom();
}

/// Sair da sala da classe
class ChatLeaveClassRoom extends ChatEvent {
  const ChatLeaveClassRoom();
}

/// Mostrar modal de regras
class ChatShowRulesModal extends ChatEvent {
  const ChatShowRulesModal();
}

/// Fechar modal de regras
class ChatHideRulesModal extends ChatEvent {
  const ChatHideRulesModal();
}

/// Atualizar estado de conexão do WebSocket
class ChatUpdateWebSocketConnection extends ChatEvent {
  final bool isConnected;

  const ChatUpdateWebSocketConnection(this.isConnected);

  @override
  List<Object?> get props => [isConnected];
}
