import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../models/gamification_profile_model.dart';
import '../models/weekly_mission_model.dart';
import '../models/achievement_model.dart';

/// Serviço para consumir APIs de gamificação
class GamificationService {
  final http.Client _client;
  final String _baseUrl;

  GamificationService({
    required http.Client client,
    String? baseUrl,
  }) : _client = client,
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  /// Obtém o perfil de gamificação do usuário
  Future<GamificationProfileModel> getProfile(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/gamification/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return GamificationProfileModel.fromJson(data);
    } else {
      throw Exception('Falha ao carregar perfil: ${response.statusCode}');
    }
  }

  /// Obtém as missões ativas do usuário
  Future<List<WeeklyMissionModel>> getActiveMissions(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/gamification/missions/user/my-missions?status=active'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> missions = json.decode(response.body) ?? [];
      return missions.map((mission) => WeeklyMissionModel.fromJson(mission)).toList();
    } else {
      throw Exception('Falha ao carregar missões: ${response.statusCode}');
    }
  }

  /// Obtém as conquistas do usuário
  Future<List<AchievementModel>> getAchievements(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/gamification/achievements/user/my-achievements'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> achievements = data['achievements'] ?? [];
      return achievements.map((achievement) => AchievementModel.fromJson(achievement)).toList();
    } else {
      throw Exception('Falha ao carregar conquistas: ${response.statusCode}');
    }
  }

  /// Atualiza progresso da missão
  Future<Map<String, dynamic>> updateMissionProgress(String token, String missionId, int progress) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/gamification/missions/update-progress'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'missionId': missionId,
        'progress': progress,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Falha ao atualizar progresso: ${response.statusCode}');
    }
  }

  /// Obtém estatísticas de gamificação
  Future<Map<String, dynamic>> getStats(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/gamification/stats'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao carregar estatísticas: ${response.statusCode}');
    }
  }
}
