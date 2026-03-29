import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_service.dart';

class ProfileStatsService {
  final http.Client _httpClient;
  final ApiService _apiService;
  final String _baseUrl;

  ProfileStatsService({
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

  /// Busca estatísticas completas do perfil
  Future<Map<String, dynamic>> getProfileStats() async {
    try {
      print('📊 [PROFILE_STATS] Iniciando busca de estatísticas do perfil...');
      
      // Buscar dados de diferentes APIs em paralelo
      final results = await Future.wait<Map<String, dynamic>>([
        _getGamificationStats(),
        _getPaymentStats(),
        _getRatingStats(),
        _getClassStats(),
      ]);

      final gamificationData = results[0];
      final paymentData = results[1];
      final ratingData = results[2];
      final classData = results[3];

      print('🔍 [PROFILE_STATS] ===== DADOS RECEBIDOS DAS APIs =====');
      print('🔍 [PROFILE_STATS] Gamificação: $gamificationData');
      print('🔍 [PROFILE_STATS] Pagamentos: $paymentData');
      print('🔍 [PROFILE_STATS] Avaliações: $ratingData');
      print('🔍 [PROFILE_STATS] Aulas: $classData');

      // Agregar dados
      final stats = {
        'xpLevel': gamificationData['level'] ?? 0,
        'totalXp': gamificationData['totalXP'] ?? 0, // totalXP conforme backend
        'totalEarned': paymentData['totalEarned'] ?? 0.0,
        'walletBalance': paymentData['walletBalance'] ?? 0.0,
        'stars': ratingData['averageRating'] ?? 0.0,
        'totalRatings': ratingData['totalRatings'] ?? 0,
        'totalClasses': classData['totalClasses'] ?? 0,
        'completedClasses': classData['completedClasses'] ?? 0,
      };

      print('✅ [PROFILE_STATS] ===== ESTATÍSTICAS FINAIS =====');
      print('✅ [PROFILE_STATS] XP Level: ${stats['xpLevel']}');
      print('✅ [PROFILE_STATS] Total XP: ${stats['totalXp']}');
      print('✅ [PROFILE_STATS] Total Earned: ${stats['totalEarned']}');
      print('✅ [PROFILE_STATS] Stars: ${stats['stars']}');
      print('✅ [PROFILE_STATS] Total Classes: ${stats['totalClasses']}');
      print('✅ [PROFILE_STATS] Estatísticas completas: $stats');
      return stats;
    } catch (e) {
      print('❌ [PROFILE_STATS] Erro ao carregar estatísticas: $e');
      rethrow;
    }
  }

  /// Busca dados de gamificação (perfil consolidado)
  Future<Map<String, dynamic>> _getGamificationStats() async {
    try {
      print('🎮 [PROFILE_STATS] ===== INICIANDO BUSCA DE GAMIFICAÇÃO =====');
      print('🎮 [PROFILE_STATS] URL: $_baseUrl/gamification/profile');
      print('🎮 [PROFILE_STATS] Headers: $_headers');
      
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/gamification/profile'),
        headers: _headers,
      );

      print('🎮 [PROFILE_STATS] Status Code: ${response.statusCode}');
      print('🎮 [PROFILE_STATS] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [PROFILE_STATS] Dados de gamificação decodificados: $data');
        print('✅ [PROFILE_STATS] Level: ${data['level']}');
        print('✅ [PROFILE_STATS] Total XP: ${data['totalXP']}');
        return data as Map<String, dynamic>;
      } else {
        print('⚠️ [PROFILE_STATS] Erro na API de gamificação: ${response.statusCode}');
        print('⚠️ [PROFILE_STATS] Response: ${response.body}');
        return {'level': 0, 'totalXP': 0};
      }
    } catch (e) {
      print('❌ [PROFILE_STATS] Erro ao buscar gamificação: $e');
      print('❌ [PROFILE_STATS] Stack trace: ${e.toString()}');
      return {'level': 0, 'totalXP': 0};
    }
  }

  /// Busca dados de pagamentos
  Future<Map<String, dynamic>> _getPaymentStats() async {
    try {
      print('💰 [PROFILE_STATS] Buscando dados de pagamentos...');
      
      // Usar a nova rota de estatísticas financeiras do personal
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/payments/personal/financial/stats'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final statsData = data['data'];
        print('✅ [PROFILE_STATS] Dados de estatísticas financeiras: $statsData');
        return {
          'totalEarned': statsData['totalEarnings']?.toDouble() ?? 0.0,
          'walletBalance': statsData['wallet']['availableBalance']?.toDouble() ?? 0.0,
        };
      }

      print('⚠️ [PROFILE_STATS] Erro na API de estatísticas financeiras: ${response.statusCode}');
      return {'totalEarned': 0.0, 'walletBalance': 0.0};
    } catch (e) {
      print('❌ [PROFILE_STATS] Erro ao buscar pagamentos: $e');
      return {'totalEarned': 0.0, 'walletBalance': 0.0};
    }
  }

  /// Busca dados de avaliações
  Future<Map<String, dynamic>> _getRatingStats() async {
    try {
      print('⭐ [PROFILE_STATS] Buscando dados de avaliações...');
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/ratings/stats/received'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [PROFILE_STATS] Dados de avaliações: $data');
        return {
          'averageRating': data['averageRating']?.toDouble() ?? 0.0,
          'totalRatings': data['totalRatings'] ?? 0,
        };
      } else {
        print('⚠️ [PROFILE_STATS] Erro na API de avaliações: ${response.statusCode}');
        return {'averageRating': 0.0, 'totalRatings': 0};
      }
    } catch (e) {
      print('❌ [PROFILE_STATS] Erro ao buscar avaliações: $e');
      return {'averageRating': 0.0, 'totalRatings': 0};
    }
  }

  /// Busca dados de aulas
  Future<Map<String, dynamic>> _getClassStats() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/classes/stats'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final totalClasses = data['total'] ?? 0;
        final completedClasses = data['completed'] ?? 0;
        
        // Se a API de stats não retornar dados, tentar buscar do histórico
        if (totalClasses == 0) {
          return await _getClassStatsFromHistory();
        }
        
        return {
          'totalClasses': completedClasses, // Mostrar apenas aulas concluídas
          'completedClasses': completedClasses,
        };
      } else {
        return await _getClassStatsFromHistory();
      }
    } catch (e) {
      return await _getClassStatsFromHistory();
    }
  }

  /// Busca dados de aulas do histórico como fallback
  Future<Map<String, dynamic>> _getClassStatsFromHistory() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/classes'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final classes = data['classes'] as List? ?? [];
        final completedClasses = classes.where((c) => c['status'] == 'completed').length;
        
        return {
          'totalClasses': completedClasses, // Mostrar apenas aulas concluídas
          'completedClasses': completedClasses,
        };
      } else {
        return {'totalClasses': 0, 'completedClasses': 0};
      }
    } catch (e) {
      return {'totalClasses': 0, 'completedClasses': 0};
    }
  }

  /// Debug das estatísticas de ganhos
  Future<void> debugEarnings() async {
    try {
      print('🔍 [PROFILE_STATS] ===== DEBUG EARNINGS =====');
      
      // Testar todos os endpoints de pagamento
      final endpoints = [
        '$_baseUrl/payments/wallet/balance',
        '$_baseUrl/payments/stats/my',
        '$_baseUrl/payments/profile/financial/stats',
      ];

      for (final endpoint in endpoints) {
        try {
          print('🔍 [PROFILE_STATS] Testando endpoint: $endpoint');
          final response = await _httpClient.get(
            Uri.parse(endpoint),
            headers: _headers,
          );
          print('🔍 [PROFILE_STATS] Status: ${response.statusCode}');
          print('🔍 [PROFILE_STATS] Body: ${response.body}');
        } catch (e) {
          print('❌ [PROFILE_STATS] Erro no endpoint $endpoint: $e');
        }
      }
    } catch (e) {
      print('❌ [PROFILE_STATS] Erro no debug: $e');
    }
  }
}
