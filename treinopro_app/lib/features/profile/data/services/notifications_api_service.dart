import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_service.dart';

class ProfileNotificationsApiService {
  final http.Client _httpClient;
  final ApiService _apiService;
  final String _baseUrl;

  ProfileNotificationsApiService({
    required http.Client client,
    required ApiService apiService,
    String? baseUrl,
  }) : _httpClient = client,
       _apiService = apiService,
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Map<String, String> get _headers {
    final token = _apiService.getAccessToken();
    if (token == null) {
      return {
        'Content-Type': 'application/json',
      };
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Busca preferências de notificação do usuário
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      print('🔔 [NOTIFICATIONS_API] Buscando preferências de notificação...');
      
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/notifications/preferences'),
        headers: _headers,
      );

      print('🔔 [NOTIFICATIONS_API] Status da resposta: ${response.statusCode}');
      print('🔔 [NOTIFICATIONS_API] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [NOTIFICATIONS_API] Preferências carregadas: $data');
        return data;
      } else if (response.statusCode == 404) {
        // Se não existir, retornar configurações padrão
        print('⚠️ [NOTIFICATIONS_API] Preferências não encontradas, usando padrão');
        return _getDefaultPreferences();
      } else {
        throw Exception('Erro ao buscar preferências: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [NOTIFICATIONS_API] Erro ao buscar preferências: $e');
      // Em caso de erro, retornar configurações padrão
      return _getDefaultPreferences();
    }
  }

  /// Atualiza preferências de notificação do usuário
  Future<Map<String, dynamic>> updateNotificationPreferences({
    required bool notificationsEnabled,
    required bool reminderEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
  }) async {
    try {
      print('🔔 [NOTIFICATIONS_API] Atualizando preferências de notificação...');
      
      final body = {
        'notificationsEnabled': notificationsEnabled,
        'reminderEnabled': reminderEnabled,
        if (emailNotifications != null) 'emailNotifications': emailNotifications,
        if (pushNotifications != null) 'pushNotifications': pushNotifications,
        if (smsNotifications != null) 'smsNotifications': smsNotifications,
      };

      print('🔔 [NOTIFICATIONS_API] Dados enviados: $body');

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/notifications/preferences'),
        headers: _headers,
        body: json.encode(body),
      );

      print('🔔 [NOTIFICATIONS_API] Status da resposta: ${response.statusCode}');
      print('🔔 [NOTIFICATIONS_API] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [NOTIFICATIONS_API] Preferências atualizadas: $data');
        return data;
      } else {
        throw Exception('Erro ao atualizar preferências: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [NOTIFICATIONS_API] Erro ao atualizar preferências: $e');
      rethrow;
    }
  }

  /// Retorna configurações padrão de notificação
  Map<String, dynamic> _getDefaultPreferences() {
    return {
      'notificationsEnabled': true,
      'reminderEnabled': true,
      'emailNotifications': true,
      'pushNotifications': true,
      'smsNotifications': false,
    };
  }

  /// Testa conectividade com a API de notificações
  Future<bool> testConnection() async {
    try {
      print('🔔 [NOTIFICATIONS_API] Testando conectividade...');
      
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/notifications/preferences'),
        headers: _headers,
      );

      final isConnected = response.statusCode == 200 || response.statusCode == 404;
      print('🔔 [NOTIFICATIONS_API] Conectividade: $isConnected (${response.statusCode})');
      return isConnected;
    } catch (e) {
      print('❌ [NOTIFICATIONS_API] Erro na conectividade: $e');
      return false;
    }
  }
}
