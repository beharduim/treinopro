import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/helpers/status_bar_helper.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_rules_modal.dart';
import '../widgets/chat_message_bubble.dart';

/// Página de chat para conversa com aluno
class ChatPage extends StatefulWidget {
  // ID da classe para o chat
  final String classId;
  // ID do destinatário
  final String receiverId;
  // Nome da outra parte da conversa (aluno ou professor)
  final String receiverName;
  final String location;
  final String date;
  final String time;
  final String duration;
  // Indica se o usuário atual é estudante
  final bool currentUserIsStudent;

  const ChatPage({
    super.key,
    required this.classId,
    required this.receiverId,
    required this.receiverName,
    required this.location,
    required this.date,
    required this.time,
    required this.duration,
    this.currentUserIsStudent = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  late final ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Define ícones escuros para páginas claras
    StatusBarHelper.setDarkStatusBar();

    // Criar uma nova instância do bloc em vez de usar singleton
    debugPrint('💬 [CHAT PAGE] Criando ChatBloc...');
    _chatBloc = ChatBloc();
    debugPrint('💬 [CHAT PAGE] ChatBloc criado: ${_chatBloc.hashCode}');
    debugPrint('💬 [CHAT PAGE] Adicionando ChatInitialize...');
    _chatBloc.add(
      ChatInitialize(
        classId: widget.classId,
        receiverId: widget.receiverId,
        receiverName: widget.receiverName,
      ),
    );
    debugPrint('💬 [CHAT PAGE] ChatInitialize adicionado');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _chatBloc.add(const ChatRecoverSession());
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '💬 [CHAT PAGE] Build chamado - ChatBloc: ${_chatBloc.hashCode}',
    );
    return BlocProvider.value(
      value: _chatBloc,
      child: _ChatPageContent(
        chatBloc: _chatBloc,
        classId: widget.classId,
        receiverId: widget.receiverId,
        receiverName: widget.receiverName,
        location: widget.location,
        date: widget.date,
        time: widget.time,
        duration: widget.duration,
        currentUserIsStudent: widget.currentUserIsStudent,
      ),
    );
  }
}

class _ChatPageContent extends StatefulWidget {
  final ChatBloc chatBloc;
  final String classId;
  final String receiverId;
  final String receiverName;
  final String location;
  final String date;
  final String time;
  final String duration;
  final bool currentUserIsStudent;

  const _ChatPageContent({
    required this.chatBloc,
    required this.classId,
    required this.receiverId,
    required this.receiverName,
    required this.location,
    required this.date,
    required this.time,
    required this.duration,
    required this.currentUserIsStudent,
  });

  @override
  State<_ChatPageContent> createState() => _ChatPageContentState();
}

class _ChatPageContentState extends State<_ChatPageContent> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('💬 [CHAT PAGE CONTENT] InitState chamado');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      debugPrint(
        '💬 [CHAT PAGE] Enviando mensagem: ${_messageController.text.trim()}',
      );
      widget.chatBloc.add(ChatSendMessage(_messageController.text.trim()));
      _messageController.clear();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;

    return StatusBarWrapper(
      isDarkBackground: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFDFE),
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFCFDFE),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF2D3748),
              size: 20,
            ),
            onPressed: () {
              context.read<ChatBloc>().add(const ChatDisconnectWebSocket());
              Navigator.pop(context);
            },
          ),
          title: const Text(
            'Chat',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          centerTitle: true,
        ),
        body: BlocConsumer<ChatBloc, ChatState>(
          bloc: widget.chatBloc,
          listener: (context, state) {
            debugPrint(
              '💬 [CHAT PAGE] Listener chamado - Estado: ${state.runtimeType}',
            );
            if (state is ChatLoaded) {
              debugPrint(
                '💬 [CHAT PAGE] Estado recebido: ${state.messages.length} mensagens',
              );
              debugPrint('💬 [CHAT PAGE] Última contagem: $_lastMessageCount');

              // Scroll para baixo apenas quando há uma nova mensagem
              if (state.messages.length > _lastMessageCount) {
                debugPrint(
                  '💬 [CHAT PAGE] Nova mensagem detectada! Fazendo scroll...',
                );
                _lastMessageCount = state.messages.length;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
              }
            }
          },
          builder: (context, state) {
            final messageCount = state is ChatLoaded
                ? state.messages.length
                : 0;
            debugPrint(
              '💬 [CHAT PAGE] Builder chamado - Estado: ${state.runtimeType}, Mensagens: $messageCount',
            );
            if (state is ChatLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryOrange,
                  ),
                ),
              );
            }

            if (state is ChatError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                        color: Color(0xFF2D3748),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ChatBloc>().add(const ChatLoadMessages());
                      },
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              );
            }

            if (state is ChatLoaded) {
              return Stack(
                children: [
                  Column(
                    children: [
                      // Match confirmado header
                      if (!isKeyboardOpen)
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Ícone de match
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF48BB78,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF48BB78),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Match Confirmado!',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Você e ${state.receiverName} confirmaram o match para:',
                                style: const TextStyle(
                                  fontFamily: 'Fira Sans',
                                  fontSize: 14,
                                  color: Color(0xFF718096),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              // Detalhes do match
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Color(0xFF3182CE),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            widget.location,
                                            style: const TextStyle(
                                              fontFamily: 'Fira Sans',
                                              fontSize: 14,
                                              color: Color(0xFF2D3748),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: Color(0xFF3182CE),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            widget.date,
                                            style: const TextStyle(
                                              fontFamily: 'Fira Sans',
                                              fontSize: 14,
                                              color: Color(0xFF2D3748),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          color: Color(0xFF3182CE),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${widget.time} - ${widget.duration}',
                                            style: const TextStyle(
                                              fontFamily: 'Fira Sans',
                                              fontSize: 14,
                                              color: Color(0xFF2D3748),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Lista de mensagens
                      Expanded(
                        child: state.isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryOrange,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: state.messages.length,
                                itemBuilder: (context, index) {
                                  final message = state.messages[index];
                                  debugPrint(
                                    '💬 [CHAT PAGE] Renderizando mensagem $index: ${message.messageText}',
                                  );
                                  return ChatMessageBubble(
                                    message: message,
                                    isFromCurrentUser:
                                        message.senderId != widget.receiverId,
                                  );
                                },
                              ),
                      ),
                      // Campo de input de mensagem
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          isKeyboardOpen ? 16 : mediaQuery.padding.bottom + 24,
                        ),
                        child: Row(
                          children: [
                            // Campo de texto
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(
                                      0xFF42464D,
                                    ).withValues(alpha: 0.24),
                                    width: 0.24,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    hintText: 'Digite sua mensagem',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Fira Sans',
                                      fontSize: 12,
                                      color: Color(0xFF42464D),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'Fira Sans',
                                    fontSize: 12,
                                    color: Color(0xFF42464D),
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Botão de enviar
                            GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Modal de regras
                  if (state.showRulesModal)
                    ChatRulesModal(
                      onClose: () {
                        context.read<ChatBloc>().add(
                          const ChatHideRulesModal(),
                        );
                      },
                    ),
                ],
              );
            }

            // Estado inicial ou outros estados
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryOrange,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
