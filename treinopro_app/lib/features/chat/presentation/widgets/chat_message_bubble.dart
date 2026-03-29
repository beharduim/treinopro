import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/image_utils.dart';
import '../../data/models/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isFromCurrentUser;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isFromCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser) ...[
            // Avatar do remetente
            _buildAvatar(isFromCurrentUser: false),
            const SizedBox(width: 8),
          ],

          // Bolha da mensagem
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromCurrentUser
                    ? AppColors.primaryOrange
                    : const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isFromCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(isFromCurrentUser ? 4 : 16),
                ),
                border: isFromCurrentUser
                    ? null
                    : Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do remetente (apenas para mensagens recebidas)
                  if (!isFromCurrentUser) ...[
                    Text(
                      message.sender.name,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Texto da mensagem
                  Text(
                    message.messageText,
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 14,
                      color: isFromCurrentUser
                          ? Colors.white
                          : const Color(0xFF2D3748),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Timestamp e status de leitura
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.sentAt),
                        style: TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 11,
                          color: isFromCurrentUser
                              ? Colors.white.withValues(alpha: 0.8)
                              : const Color(0xFF718096),
                        ),
                      ),
                      if (isFromCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.isRead
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isFromCurrentUser) ...[
            const SizedBox(width: 8),
            // Avatar do usuário atual
            _buildAvatar(isFromCurrentUser: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isFromCurrentUser}) {
    return ImageUtils.buildProfileImage(
      imageUrl: message.sender.profilePicture,
      size: 32,
      fallbackIconColor: isFromCurrentUser
          ? Colors.white
          : const Color(0xFF718096),
      backgroundColor: isFromCurrentUser
          ? const Color(0xFF3182CE)
          : const Color(0xFFE2E8F0),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Hoje - mostrar apenas hora
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Ontem
      return 'Ontem ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Outros dias
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
