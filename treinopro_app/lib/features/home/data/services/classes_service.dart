import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';

/// Serviço para consumir APIs de classes/aulas
class ClassesService {
  final http.Client _client;
  final String _baseUrl;

  ClassesService({
    required http.Client client,
    String? baseUrl,
  }) : _client = client,
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  /// Obtém as próximas aulas do usuário
  Future<Map<String, dynamic>> getUpcomingClasses(String token, {int page = 1, int limit = 1}) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/classes?status=scheduled&page=$page&limit=$limit'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao carregar aulas: ${response.statusCode}');
    }
  }

  /// Obtém estatísticas das aulas
  Future<Map<String, dynamic>> getStats(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/classes/stats'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Falha ao carregar estatísticas das aulas: ${response.statusCode}');
    }
  }
}
