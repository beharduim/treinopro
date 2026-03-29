import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

/// Serviço para armazenar notificações localmente (em memória do usuário)
class LocalNotificationsStorage {
  static const String _storageKey = 'local_notifications';
  static const int _maxNotifications = 20;

  /// Salva notificações localmente
  static Future<void> saveNotifications(List<NotificationModel> notifications) async {
    try {
      print('💾 [LOCAL_NOTIFICATIONS] Iniciando salvamento de ${notifications.length} notificações...');
      final prefs = await SharedPreferences.getInstance();
      print('💾 [LOCAL_NOTIFICATIONS] SharedPreferences obtido para salvamento');
      
      // Limitar a 20 notificações (mais recentes primeiro)
      final limitedNotifications = notifications
          .take(_maxNotifications)
          .toList();
      
      print('💾 [LOCAL_NOTIFICATIONS] Notificações limitadas a $_maxNotifications: ${limitedNotifications.length}');
      
      final jsonList = limitedNotifications.map((n) => n.toJson()).toList();
      final jsonString = json.encode(jsonList);
      print('💾 [LOCAL_NOTIFICATIONS] JSON gerado: ${jsonString.length} caracteres');
      
      final saved = await prefs.setString(_storageKey, jsonString);
      print('💾 [LOCAL_NOTIFICATIONS] SharedPreferences.setString retornou: $saved');
      
      // Verificar se foi salvo corretamente
      final verification = prefs.getString(_storageKey);
      if (verification != null && verification == jsonString) {
        print('💾 [LOCAL_NOTIFICATIONS] ✅ Verificação: ${limitedNotifications.length} notificações salvas e confirmadas localmente');
      } else {
        print('⚠️ [LOCAL_NOTIFICATIONS] ⚠️ Verificação falhou: dados não correspondem');
      }
    } catch (e, stackTrace) {
      print('❌ [LOCAL_NOTIFICATIONS] Erro ao salvar notificações: $e');
      print('❌ [LOCAL_NOTIFICATIONS] StackTrace: $stackTrace');
    }
  }

  /// Carrega notificações do armazenamento local
  static Future<List<NotificationModel>> loadNotifications() async {
    try {
      print('💾 [LOCAL_NOTIFICATIONS] Iniciando carregamento de notificações...');
      final prefs = await SharedPreferences.getInstance();
      print('💾 [LOCAL_NOTIFICATIONS] SharedPreferences obtido');
      
      final jsonString = prefs.getString(_storageKey);
      print('💾 [LOCAL_NOTIFICATIONS] JSON string obtido: ${jsonString != null ? "${jsonString.length} caracteres" : "null"}');
      
      if (jsonString == null || jsonString.isEmpty) {
        print('💾 [LOCAL_NOTIFICATIONS] Nenhuma notificação encontrada no armazenamento local (chave: $_storageKey)');
        return [];
      }
      
      print('💾 [LOCAL_NOTIFICATIONS] Fazendo decode do JSON...');
      final jsonList = json.decode(jsonString) as List;
      print('💾 [LOCAL_NOTIFICATIONS] JSON decodificado: ${jsonList.length} itens encontrados');
      
      final notifications = jsonList
          .map((json) {
            try {
              return NotificationModel.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              print('❌ [LOCAL_NOTIFICATIONS] Erro ao parsear notificação: $e');
              print('❌ [LOCAL_NOTIFICATIONS] Dados: $json');
              return null;
            }
          })
          .whereType<NotificationModel>()
          .toList();
      
      print('💾 [LOCAL_NOTIFICATIONS] ${notifications.length} notificações carregadas do armazenamento local');
      if (notifications.isNotEmpty) {
        print('💾 [LOCAL_NOTIFICATIONS] Primeira notificação: ${notifications.first.title} (ID: ${notifications.first.id})');
        print('💾 [LOCAL_NOTIFICATIONS] Última notificação: ${notifications.last.title} (ID: ${notifications.last.id})');
      }
      return notifications;
    } catch (e, stackTrace) {
      print('❌ [LOCAL_NOTIFICATIONS] Erro ao carregar notificações: $e');
      print('❌ [LOCAL_NOTIFICATIONS] StackTrace: $stackTrace');
      return [];
    }
  }

  /// Adiciona uma nova notificação ao armazenamento local
  static Future<void> addNotification(NotificationModel notification) async {
    try {
      print('💾 [LOCAL_NOTIFICATIONS] Adicionando notificação: ${notification.title} (ID: ${notification.id})');
      final existing = await loadNotifications();
      print('💾 [LOCAL_NOTIFICATIONS] Notificações existentes: ${existing.length}');
      
      // Remover notificação com mesmo ID se existir (evitar duplicatas)
      final beforeRemove = existing.length;
      existing.removeWhere((n) => n.id == notification.id);
      if (beforeRemove != existing.length) {
        print('💾 [LOCAL_NOTIFICATIONS] Notificação duplicada removida (ID: ${notification.id})');
      }
      
      // Adicionar nova notificação no início (mais recente primeiro)
      final updated = [notification, ...existing];
      print('💾 [LOCAL_NOTIFICATIONS] Total de notificações após adicionar: ${updated.length}');
      
      await saveNotifications(updated);
      print('💾 [LOCAL_NOTIFICATIONS] Notificação salva com sucesso');
    } catch (e, stackTrace) {
      print('❌ [LOCAL_NOTIFICATIONS] Erro ao adicionar notificação: $e');
      print('❌ [LOCAL_NOTIFICATIONS] StackTrace: $stackTrace');
    }
  }

  /// Remove uma notificação do armazenamento local
  static Future<void> removeNotification(String notificationId) async {
    try {
      final existing = await loadNotifications();
      existing.removeWhere((n) => n.id == notificationId);
      await saveNotifications(existing);
    } catch (e) {
      print('❌ [LOCAL_NOTIFICATIONS] Erro ao remover notificação: $e');
    }
  }

  /// Atualiza uma notificação no armazenamento local
  static Future<void> updateNotification(NotificationModel notification) async {
    try {
      final existing = await loadNotifications();
      final index = existing.indexWhere((n) => n.id == notification.id);
      
      if (index != -1) {
        existing[index] = notification;
        await saveNotifications(existing);
      }
    } catch (e) {
      print('❌ [LOCAL_NOTIFICATIONS] Erro ao atualizar notificação: $e');
    }
  }

  /// Limpa todas as notificações do armazenamento local
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      print('💾 [LOCAL_NOTIFICATIONS] Todas as notificações locais foram limpas');
    } catch (e) {
      print('❌ [LOCAL_NOTIFICATIONS] Erro ao limpar notificações: $e');
    }
  }
}

