import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/notification_model.dart';

/// Modal para exibir notificações
class NotificationsModal extends StatefulWidget {
  final List<NotificationModel> notifications;
  final VoidCallback? onClearAll;
  final Function(String)? onMarkAsRead;
  final Function(String)? onDelete;
  final Function(NotificationModel)? onNotificationTap;

  const NotificationsModal({
    super.key,
    required this.notifications,
    this.onClearAll,
    this.onMarkAsRead,
    this.onDelete,
    this.onNotificationTap,
  });

  @override
  State<NotificationsModal> createState() => _NotificationsModalState();
}

class _NotificationsModalState extends State<NotificationsModal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header do modal
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notificações',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A202C),
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (widget.notifications.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${widget.notifications.where((n) => !n.isRead).length} não lidas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
                if (widget.notifications.isNotEmpty)
                  InkWell(
                    onTap: widget.onClearAll,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Limpar todas',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Lista de notificações
          Expanded(
            child: widget.notifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: widget.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = widget.notifications[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: _buildNotificationItem(notification),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma notificação',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Você está em dia!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final notificationType = notification.data?['type'] as String?;
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: () => widget.onNotificationTap?.call(notification),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isUnread ? Colors.white : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? AppColors.primaryOrange.withValues(alpha: 0.2)
                : Colors.grey[200]!,
            width: isUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnread
                  ? AppColors.primaryOrange.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              offset: const Offset(0, 2),
              blurRadius: isUnread ? 12 : 6,
              spreadRadius: isUnread ? 1 : 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone com gradiente e fundo melhorado
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getNotificationGradient(
                      notificationType ?? notification.type,
                    ),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _getNotificationColor(
                        notificationType ?? notification.type,
                      ).withValues(alpha: 0.2),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _getNotificationIcon(notificationType ?? notification.type),
                  size: 24,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: 16),

              // Conteúdo da notificação
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: const Color(0xFF1A202C),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notification.message,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                  fontWeight: isUnread
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(left: 8, top: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryOrange.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Footer com data e ações
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 250;

                        final actions = Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (isUnread)
                              InkWell(
                                onTap: () =>
                                    widget.onMarkAsRead?.call(notification.id),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCompact ? 8 : 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryOrange.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isCompact
                                        ? 'Marcar lida'
                                        : 'Marcar como lida',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryOrange,
                                    ),
                                  ),
                                ),
                              ),
                            InkWell(
                              onTap: () =>
                                  widget.onDelete?.call(notification.id),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ],
                        );

                        if (isCompact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _formatDate(notification.createdAt),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: actions,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _formatDate(notification.createdAt),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: actions,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    // Verificar primeiro o tipo específico da notificação (data['type'])
    switch (type.toLowerCase()) {
      case 'new_message':
        return const Color(0xFF3B82F6); // Azul para mensagens
      case 'class_reminder':
        return const Color(0xFF8B5CF6); // Roxo para lembretes de aula
      case 'payment_received':
        return const Color(0xFF10B981); // Verde para pagamentos
      case 'dispute_created':
      case 'dispute_update':
        return const Color(0xFFF59E0B); // Laranja/Amarelo para disputas
      case 'mission_completed':
        return const Color(0xFF10B981); // Verde para missões
      case 'success':
        return const Color(0xFF10B981);
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'error':
        return const Color(0xFFEF4444);
      case 'info':
      default:
        return AppColors.primaryOrange;
    }
  }

  List<Color> _getNotificationGradient(String type) {
    switch (type.toLowerCase()) {
      case 'new_message':
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
      case 'class_reminder':
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      case 'payment_received':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'dispute_created':
      case 'dispute_update':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'mission_completed':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'success':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'warning':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'error':
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case 'info':
      default:
        return [AppColors.primaryOrange, AppColors.primaryOrangeLight];
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'new_message':
        return Icons.chat_bubble_outline_rounded;
      case 'class_reminder':
        return Icons.calendar_today_rounded;
      case 'payment_received':
        return Icons.payments_rounded;
      case 'dispute_created':
      case 'dispute_update':
        return Icons.gavel_rounded;
      case 'mission_completed':
        return Icons.emoji_events_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      case 'warning':
        return Icons.warning_rounded;
      case 'error':
        return Icons.error_rounded;
      case 'info':
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      // Se for mais de uma semana, mostrar data completa
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day/$month';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}${difference.inDays == 1 ? ' dia' : ' dias'} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}${difference.inHours == 1 ? ' hora' : ' horas'} atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}${difference.inMinutes == 1 ? ' minuto' : ' minutos'} atrás';
    } else {
      return 'Agora';
    }
  }
}
