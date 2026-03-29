import 'package:equatable/equatable.dart';
import '../../data/models/chat_message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// Carregando mensagens
class ChatLoading extends ChatState {
  const ChatLoading();
}

/// Mensagens carregadas
class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final String classId;
  final String receiverId;
  final String receiverName;
  final bool isWebSocketConnected;
  final bool showRulesModal;
  final bool isLoading;

  const ChatLoaded({
    required this.messages,
    required this.classId,
    required this.receiverId,
    required this.receiverName,
    this.isWebSocketConnected = false,
    this.showRulesModal = false,
    this.isLoading = false,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    String? classId,
    String? receiverId,
    String? receiverName,
    bool? isWebSocketConnected,
    bool? showRulesModal,
    bool? isLoading,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      classId: classId ?? this.classId,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
      showRulesModal: showRulesModal ?? this.showRulesModal,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        classId,
        receiverId,
        receiverName,
        isWebSocketConnected,
        showRulesModal,
        isLoading,
      ];
}

/// Erro
class ChatError extends ChatState {
  final String message;
  final List<ChatMessage>? messages;

  const ChatError({
    required this.message,
    this.messages,
  });

  @override
  List<Object?> get props => [message, messages];
}

/// Operação em progresso
class ChatOperationInProgress extends ChatState {
  final List<ChatMessage> messages;
  final String operation;
  final bool isWebSocketConnected;

  const ChatOperationInProgress({
    required this.messages,
    required this.operation,
    this.isWebSocketConnected = false,
  });

  @override
  List<Object?> get props => [messages, operation, isWebSocketConnected];
}

/// Operação bem-sucedida
class ChatOperationSuccess extends ChatState {
  final List<ChatMessage> messages;
  final String message;
  final bool isWebSocketConnected;

  const ChatOperationSuccess({
    required this.messages,
    required this.message,
    this.isWebSocketConnected = false,
  });

  @override
  List<Object?> get props => [messages, message, isWebSocketConnected];
}

/// Operação falhou
class ChatOperationFailure extends ChatState {
  final List<ChatMessage> messages;
  final String error;
  final bool isWebSocketConnected;

  const ChatOperationFailure({
    required this.messages,
    required this.error,
    this.isWebSocketConnected = false,
  });

  @override
  List<Object?> get props => [messages, error, isWebSocketConnected];
}
