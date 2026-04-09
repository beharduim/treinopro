import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';

/// Serviço para consumir APIs de notificações
class NotificationsApiService {
  final http.Client _client;
  final String _baseUrl;

  NotificationsApiService({
    required http.Client client,
    String? baseUrl,
  }) : _client = client,
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  /// Obtém todas as notificações do usuário
  Future<List<Map<String, dynamic>>> getNotifications(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/notifications/in-app'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('📡 [NOTIFICATIONS_API] Resposta do servidor: ${data.runtimeType}');
      print('📡 [NOTIFICATIONS_API] Dados brutos: $data');
      
      // O backend retorna um array diretamente, não um objeto com 'notifications'
      final notifications = List<Map<String, dynamic>>.from(data is List ? data : (data['notifications'] ?? []));
      print('📡 [NOTIFICATIONS_API] ${notifications.length} notificações parseadas da resposta');
      
      if (notifications.isNotEmpty) {
        print('📡 [NOTIFICATIONS_API] Primeira notificação: ${notifications[0]}');
      }
      
      return notifications;
    } else {
      print('❌ [NOTIFICATIONS_API] Erro ao buscar notificações: ${response.statusCode}');
      print('❌ [NOTIFICATIONS_API] Corpo da resposta: ${response.body}');
      throw Exception('Falha ao carregar notificações: ${response.statusCode}');
    }
  }

  /// Marca uma notificação como lida
  Future<void> markAsRead(String token, String notificationId) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/notifications/in-app/$notificationId/read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao marcar notificação como lida: ${response.statusCode}');
    }
  }

  /// Marca todas as notificações como lidas
  Future<void> markAllAsRead(String token) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/notifications/in-app/read-all'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao marcar todas as notificações como lidas: ${response.statusCode}');
    }
  }

  /// Remove uma notificação
  Future<void> deleteNotification(String token, String notificationId) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/notifications/in-app/$notificationId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao remover notificação: ${response.statusCode}');
    }
  }

  /// Remove todas as notificações
  Future<void> clearAllNotifications(String token) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/notifications/in-app'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      print('❌ [NOTIFICATIONS_API] Erro ao limpar todas as notificações: ${response.statusCode}');
      throw Exception('Falha ao limpar todas as notificações: ${response.statusCode}');
    }
    
    print('✅ [NOTIFICATIONS_API] Todas as notificações foram limpas no backend');
  }

  /// Obtém contagem de notificações não lidas
  Future<int> getUnreadCount(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/notifications/in-app/unread/count'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['count'] ?? 0;
    } else {
      throw Exception('Falha ao obter contagem de notificações: ${response.statusCode}');
    }
  }

  /// Obtém preferências de notificação do usuário
  Future<Map<String, dynamic>> getNotificationPreferences(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/notifications/preferences'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data);
    } else {
      throw Exception('Falha ao obter preferências de notificação: ${response.statusCode}');
    }
  }

  /// Atualiza preferências de notificação do usuário
  Future<void> updateNotificationPreferences(String token, Map<String, dynamic> preferences) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/notifications/preferences'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(preferences),
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao atualizar preferências de notificação: ${response.statusCode}');
    }
  }
}
