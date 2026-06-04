import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../home/data/services/auth_service.dart';
import '../../data/models/chat_conversation.dart';
import '../../data/services/chat_api_service.dart';
import 'chat_page.dart';

class ConversationsListPage extends StatefulWidget {
  final bool currentUserIsStudent;

  const ConversationsListPage({
    super.key,
    required this.currentUserIsStudent,
  });

  @override
  State<ConversationsListPage> createState() => _ConversationsListPageState();
}

class _ConversationsListPageState extends State<ConversationsListPage> {
  final ChatApiService _chatApi = sl<ChatApiService>();
  List<ChatConversation> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _chatApi.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = items
            .map(
              (json) => ChatConversation.fromJson(
                json,
                currentUserIsStudent: widget.currentUserIsStudent,
              ),
            )
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openChat(ChatConversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          classId: conversation.classId,
          receiverId: conversation.otherParticipantId,
          receiverName: conversation.otherParticipantName,
          location: conversation.location ?? '',
          date: conversation.formattedClassDate,
          time: conversation.classTime ?? '',
          duration: conversation.durationMinutes != null
              ? '${conversation.durationMinutes}min'
              : '',
          currentUserIsStudent: widget.currentUserIsStudent,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFDFE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mensagens',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2D3748)),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            widget.currentUserIsStudent
                ? 'Você ainda não tem conversas com personal trainers. Após um match, use o botão Chat na aula ou aqui quando houver mensagens.'
                : 'Você ainda não tem conversas com alunos. Após um match, use o botão Chat na aula.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 15,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryOrange,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final c = _conversations[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryOrange.withOpacity(0.15),
              child: Text(
                c.otherParticipantName.isNotEmpty
                    ? c.otherParticipantName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              c.otherParticipantName,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.lastMessageText != null && c.lastMessageText!.isNotEmpty)
                  Text(
                    c.lastMessageText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 13,
                      color: c.unreadCount > 0
                          ? const Color(0xFF2D3748)
                          : const Color(0xFF64748B),
                      fontWeight:
                          c.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  )
                else
                  const Text(
                    'Nenhuma mensagem ainda — toque para iniciar',
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  '${c.formattedClassDate} · ${c.location ?? 'Local não informado'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Fira Sans',
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            trailing: c.unreadCount > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${c.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            onTap: () => _openChat(c),
          );
        },
      ),
    );
  }
}

/// Abre a lista de conversas detectando se o usuário é aluno ou personal.
void openConversationsList(BuildContext context) {
  final auth = sl<AuthService>();
  final isStudent = auth.currentUserType?.toLowerCase() == 'student';
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ConversationsListPage(
        currentUserIsStudent: isStudent,
      ),
    ),
  );
}
