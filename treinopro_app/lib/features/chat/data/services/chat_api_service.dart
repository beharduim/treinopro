import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/services/api_service.dart';
import '../models/chat_message.dart';
import '../../../../core/config/app_config.dart';

class ChatApiService {
  final ApiService _apiService;
  final http.Client _client = http.Client();
  final String _baseUrl = AppConfig.apiBaseUrl;

  ChatApiService({required ApiService apiService}) : _apiService = apiService;

  /// Enviar mensagem
  Future<ChatMessage> sendMessage(SendMessageDto messageDto) async {
    try {
      print('💬 [CHAT API] Enviando mensagem...');
      print('💬 [CHAT API] Dados: ${messageDto.toJson()}');

      final token = _apiService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final url = Uri.parse('$_baseUrl/chat/messages');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await _client.post(
        url,
        headers: headers,
        body: json.encode(messageDto.toJson()),
      );

      print('💬 [CHAT API] Status: ${response.statusCode}');
      print('💬 [CHAT API] Response: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        return ChatMessage.fromJson(responseData);
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        throw Exception('Erro ao enviar mensagem: ${errorData['message'] ?? 'Erro desconhecido'}');
      }
    } catch (e) {
      print('❌ [CHAT API] Erro ao enviar mensagem: $e');
      rethrow;
    }
  }

  /// Buscar mensagens de uma classe
  Future<List<ChatMessage>> getMessages(String classId, {int page = 1, int limit = 50}) async {
    try {
      print('💬 [CHAT API] Buscando mensagens da classe: $classId');

      final token = _apiService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final url = Uri.parse('$_baseUrl/chat/messages?classId=$classId&page=$page&limit=$limit');
      final headers = {
        'Authorization': 'Bearer $token',
      };

      final response = await _client.get(url, headers: headers);

      print('💬 [CHAT API] Status: ${response.statusCode}');
      print('💬 [CHAT API] Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final messagesData = responseData['messages'] as List<dynamic>;
        return messagesData.map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>)).toList();
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        throw Exception('Erro ao buscar mensagens: ${errorData['message'] ?? 'Erro desconhecido'}');
      }
    } catch (e) {
      print('❌ [CHAT API] Erro ao buscar mensagens: $e');
      rethrow;
    }
  }

  /// Marcar mensagem como lida
  Future<void> markAsRead(String messageId) async {
    try {
      print('💬 [CHAT API] Marcando mensagem como lida: $messageId');

      final token = _apiService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final url = Uri.parse('$_baseUrl/chat/messages/$messageId/read');
      final headers = {
        'Authorization': 'Bearer $token',
      };

      final response = await _client.put(url, headers: headers);

      print('💬 [CHAT API] Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        throw Exception('Erro ao marcar como lida: ${errorData['message'] ?? 'Erro desconhecido'}');
      }
    } catch (e) {
      print('❌ [CHAT API] Erro ao marcar como lida: $e');
      rethrow;
    }
  }

  /// Marcar todas as mensagens de uma classe como lidas
  Future<void> markAllAsRead(String classId) async {
    try {
      print('💬 [CHAT API] Marcando todas as mensagens como lidas da classe: $classId');

      final token = _apiService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final url = Uri.parse('$_baseUrl/chat/classes/$classId/read-all');
      final headers = {
        'Authorization': 'Bearer $token',
      };

      final response = await _client.put(url, headers: headers);

      print('💬 [CHAT API] Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        throw Exception('Erro ao marcar todas como lidas: ${errorData['message'] ?? 'Erro desconhecido'}');
      }
    } catch (e) {
      print('❌ [CHAT API] Erro ao marcar todas como lidas: $e');
      rethrow;
    }
  }

  /// Lista conversas (um chat por match/aula)
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final token = _apiService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final url = Uri.parse('$_baseUrl/chat/conversations');
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body is List) {
          return body
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        if (body is Map && body['data'] is List) {
          return (body['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        return [];
      }

      final errorData = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(
        errorData['message']?.toString() ?? 'Erro ao listar conversas',
      );
    } catch (e) {
      print('❌ [CHAT API] Erro ao listar conversas: $e');
      rethrow;
    }
  }

  /// Buscar estatísticas do chat
  Future<ChatStatsDto> getStats() async {
    try {
      print('💬 [CHAT API] Buscando estatísticas do chat...');

      final token = _apiService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final url = Uri.parse('$_baseUrl/chat/stats');
      final headers = {
        'Authorization': 'Bearer $token',
      };

      final response = await _client.get(url, headers: headers);

      print('💬 [CHAT API] Status: ${response.statusCode}');
      print('💬 [CHAT API] Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        return ChatStatsDto.fromJson(responseData);
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        throw Exception('Erro ao buscar estatísticas: ${errorData['message'] ?? 'Erro desconhecido'}');
      }
    } catch (e) {
      print('❌ [CHAT API] Erro ao buscar estatísticas: $e');
      rethrow;
    }
  }
}
