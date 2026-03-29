import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/local_notifications_storage.dart';
import '../widgets/notifications_modal.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../classes/presentation/pages/classes_page.dart';
import '../../../../core/services/notification_service.dart';

/// Mixin para gerenciar notificações (armazenadas localmente)
mixin NotificationsMixin<T extends StatefulWidget> on State<T> {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoadingNotifications = false;
  StreamSubscription<void>? _notificationAddedSubscription;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoadingNotifications => _isLoadingNotifications;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    
    // ✅ Escutar quando uma nova notificação é adicionada para atualizar contador automaticamente
    _notificationAddedSubscription = NotificationService.notificationAddedStream.listen(
      (_) {
        print('📢 [NOTIFICATIONS] Nova notificação detectada - recarregando...');
        // Adicionar um pequeno delay para garantir que SharedPreferences esteja sincronizado
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _loadNotifications();
          }
        });
      },
    );
  }
  
  @override
  void dispose() {
    _notificationAddedSubscription?.cancel();
    super.dispose();
  }
  
  /// Chamado quando o estado do app muda (foreground/background)
  /// Deve ser chamado manualmente nas classes que usam este mixin junto com WidgetsBindingObserver
  void onAppLifecycleStateChanged(AppLifecycleState state) {
    // Quando o app volta ao foreground, recarregar notificações
    if (state == AppLifecycleState.resumed) {
      print('🔄 [NOTIFICATIONS] App voltou ao foreground - recarregando notificações...');
      // Adicionar um pequeno delay para garantir que SharedPreferences esteja sincronizado
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _loadNotifications();
        }
      });
    }
  }
  
  /// Força o recarregamento das notificações (útil quando uma nova notificação é salva)
  Future<void> forceReload() async {
    print('🔄 [NOTIFICATIONS] Forçando recarregamento de notificações...');
    await _loadNotifications();
  }

  /// Carrega as notificações do armazenamento LOCAL (não busca do servidor)
  Future<void> _loadNotifications() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      // Carregar apenas notificações locais (armazenadas no celular)
      final localNotifications = await LocalNotificationsStorage.loadNotifications();
      print('💾 [NOTIFICATIONS] ${localNotifications.length} notificações carregadas do armazenamento local');
      
      if (mounted) {
        // Ordenar por data (mais recentes primeiro)
        final sortedNotifications = localNotifications.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Calcular contador de não lidas
        final unreadCount = sortedNotifications.where((n) => !n.isRead).length;
        
        setState(() {
          _notifications = sortedNotifications;
          _unreadCount = unreadCount;
          _isLoadingNotifications = false;
        });
        
        print('📱 [NOTIFICATIONS] Estado atualizado: ${_notifications.length} notificações, $_unreadCount não lidas');
      }
    } catch (e) {
      print('❌ [NOTIFICATIONS] Erro ao carregar notificações locais: $e');
      print('❌ [NOTIFICATIONS] StackTrace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _notifications = [];
          _unreadCount = 0;
          _isLoadingNotifications = false;
        });
      }
    }
  }

  /// Marca uma notificação como lida (apenas localmente)
  Future<void> markAsRead(String notificationId) async {
    try {
      // Atualizar estado local
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((notification) {
            if (notification.id == notificationId) {
              final updated = notification.copyWith(isRead: true);
              // Atualizar no armazenamento local
              LocalNotificationsStorage.updateNotification(updated);
              return updated;
            }
            return notification;
          }).toList();
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        });
      }
    } catch (e) {
      print('❌ [NOTIFICATIONS] Erro ao marcar como lida: $e');
    }
  }

  /// Remove uma notificação (apenas localmente)
  Future<void> deleteNotification(String notificationId) async {
    try {
      // Remover do armazenamento local
      await LocalNotificationsStorage.removeNotification(notificationId);
      
      // Atualizar estado local
      if (mounted) {
        setState(() {
          final wasUnread = _notifications.any((n) => n.id == notificationId && !n.isRead);
          _notifications.removeWhere((notification) => notification.id == notificationId);
          if (wasUnread) {
            _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
          }
        });
      }
    } catch (e) {
      print('❌ [NOTIFICATIONS] Erro ao remover notificação: $e');
    }
  }

  /// Limpa todas as notificações (apenas localmente)
  Future<void> clearAllNotifications() async {
    try {
      // Limpar armazenamento local
      await LocalNotificationsStorage.clearAll();
      
      if (mounted) {
        setState(() {
          _notifications.clear();
          _unreadCount = 0;
        });
      }
    } catch (e) {
      print('❌ [NOTIFICATIONS] Erro ao limpar notificações: $e');
    }
  }

  /// Marca todas as notificações como lidas (apenas localmente)
  Future<void> markAllAsRead() async {
    try {
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((notification) {
            final updated = notification.copyWith(isRead: true);
            LocalNotificationsStorage.updateNotification(updated);
            return updated;
          }).toList();
          _unreadCount = 0;
        });
      }
    } catch (e) {
      print('❌ [NOTIFICATIONS] Erro ao marcar todas como lidas: $e');
    }
  }

  /// Mostra o modal de notificações
  void showNotificationsModal() async {
    print('🔔 [NOTIFICATIONS] Abrindo modal de notificações...');
    print('🔔 [NOTIFICATIONS] Notificações atuais: ${_notifications.length}');
    print('🔔 [NOTIFICATIONS] Contador não lidas: $_unreadCount');
    
    // Recarregar notificações antes de exibir o modal para garantir dados atualizados
    // Adicionar um pequeno delay para garantir que SharedPreferences esteja sincronizado
    await Future.delayed(const Duration(milliseconds: 100));
    await _loadNotifications();
    
    if (!mounted) return;
    
    print('🔔 [NOTIFICATIONS] Após carregar - Notificações: ${_notifications.length}');
    print('🔔 [NOTIFICATIONS] Após carregar - Contador: $_unreadCount');
    
    if (!mounted) return;
    
    // Capturar a lista atual de notificações para passar ao modal
    final currentNotifications = List<NotificationModel>.from(_notifications);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        print('🔔 [NOTIFICATIONS] Construindo modal com ${currentNotifications.length} notificações');
        return NotificationsModal(
          notifications: currentNotifications,
          onClearAll: () {
            Navigator.of(context).pop();
            clearAllNotifications();
          },
          onMarkAsRead: (notificationId) {
            markAsRead(notificationId);
          },
          onDelete: (notificationId) {
            deleteNotification(notificationId);
          },
          onNotificationTap: (notification) {
            Navigator.of(context).pop(); // Fechar modal primeiro
            _handleNotificationTap(notification);
          },
        );
      },
    );
  }

  /// Handler para quando uma notificação é clicada
  void _handleNotificationTap(NotificationModel notification) {
    if (!mounted) return;

    final notificationType = notification.data?['type'] as String?;
    
    if (notificationType == null) {
      // Se não tiver tipo, apenas marca como lida
      markAsRead(notification.id);
      return;
    }

    switch (notificationType) {
      case 'new_message':
        _navigateToChat(notification);
        break;
      
      case 'class_reminder':
        _navigateToClassesPage(notification);
        break;
      
      case 'payment_received':
        // Apenas marca como lida, sem navegação
        markAsRead(notification.id);
        break;
      
      case 'dispute_created':
      case 'dispute_update':
        // Apenas marca como lida, sem navegação
        markAsRead(notification.id);
        break;
      
      case 'mission_completed':
        // Opcional: navegar para perfil/gamificação
        // Por enquanto, apenas marca como lida
        markAsRead(notification.id);
        break;
      
      default:
        // Para outros tipos, apenas marca como lida
        markAsRead(notification.id);
    }
  }

  /// Navega para a página de chat
  void _navigateToChat(NotificationModel notification) {
    final classId = notification.data?['classId'] as String?;
    final senderId = notification.data?['senderId'] as String?;
    final senderName = notification.data?['senderName'] as String? ?? 'Contato';

    if (classId == null || senderId == null) {
      print('❌ [NOTIFICATIONS] Dados insuficientes para navegar para chat');
      markAsRead(notification.id);
      return;
    }

    // Marcar como lida antes de navegar
    markAsRead(notification.id);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          classId: classId,
          receiverId: senderId,
          receiverName: senderName,
          location: notification.data?['location'] as String? ?? 'Local a definir',
          date: notification.data?['date'] as String? ?? '',
          time: notification.data?['time'] as String? ?? '',
          duration: notification.data?['duration'] as String? ?? '60min',
          currentUserIsStudent: false, // Será ajustado conforme necessário
        ),
      ),
    );
  }

  /// Navega para a página de aulas/treino
  void _navigateToClassesPage(NotificationModel notification) {
    markAsRead(notification.id);

    // Navegar para a página de Classes
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ClassesPage(),
      ),
    );
  }

  /// Recarrega as notificações
  Future<void> refreshNotifications() async {
    await _loadNotifications();
  }

  /// Adiciona uma notificação localmente (quando recebida via push/websocket)
  Future<void> addLocalNotification(NotificationModel notification) async {
    await LocalNotificationsStorage.addNotification(notification);
    
    if (mounted) {
      setState(() {
        // Remover duplicata se existir
        _notifications.removeWhere((n) => n.id == notification.id);
        // Adicionar no início (mais recente)
        _notifications.insert(0, notification);
        // Limitar a 20
        if (_notifications.length > 20) {
          _notifications = _notifications.take(20).toList();
        }
        // Atualizar contador
        if (!notification.isRead) {
          _unreadCount++;
        }
      });
    }
  }
}
