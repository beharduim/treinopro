import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../models/gamification_dto.dart';
import '../../../../core/config/app_config.dart';

/// Serviço para comunicação com a API de gamificação
class GamificationService {
  final http.Client _client;
  final NetworkInfo _networkInfo;
  final String _baseUrl;

  GamificationService({
    required http.Client client,
    required NetworkInfo networkInfo,
  }) : _client = client,
       _networkInfo = networkInfo,
       _baseUrl = AppConfig.apiBaseUrl;

  // ===== PERFIL DE USUÁRIO =====

  /// Busca o perfil de gamificação do usuário
  Future<UserProfileResponseDto> getUserProfile(String userId, String authToken) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/gamification/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserProfileResponseDto.fromJson(data);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token inválido');
      } else {
        throw ServerException('Erro ao buscar perfil: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao buscar perfil: $e');
    }
  }

  /// Busca estatísticas de gamificação do usuário
  Future<GamificationStatsResponseDto> getGamificationStats(String userId, String authToken) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/gamification/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GamificationStatsResponseDto.fromJson(data);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token inválido');
      } else {
        throw ServerException('Erro ao buscar estatísticas: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao buscar estatísticas: $e');
    }
  }

  // ===== MISSÕES =====

  /// Busca missões do usuário
  Future<List<UserMissionResponseDto>> getUserMissions(String userId, String authToken, {String? status}) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    try {
      final uri = Uri.parse('$_baseUrl/gamification/missions/user/my-missions').replace(
        queryParameters: status != null ? {'status': status} : null,
      );

      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((item) => UserMissionResponseDto.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token inválido');
      } else {
        throw ServerException('Erro ao buscar missões: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao buscar missões: $e');
    }
  }

  /// Atribui próxima missão automaticamente
  Future<UserMissionResponseDto?> autoAssignNextMission(String userId, String authToken) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/gamification/missions/auto-assign'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['mission'] != null) {
          return UserMissionResponseDto.fromJson(data['mission']);
        }
        return null;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token inválido');
      } else if (response.statusCode == 404) {
        return null; // Nenhuma missão disponível
      } else {
        throw ServerException('Erro ao atribuir missão: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao atribuir missão: $e');
    }
  }

  /// Atualiza progresso de missão
  Future<List<UserMissionResponseDto>> updateMissionProgress(
    String userId,
    String authToken,
    MissionProgressDto progressDto,
  ) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/gamification/missions/progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(progressDto.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as List;
        return data.map((item) => UserMissionResponseDto.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token inválido');
      } else {
        throw ServerException('Erro ao atualizar progresso: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao atualizar progresso: $e');
    }
  }

  // ===== XP =====

  /// Adiciona XP ao usuário
  Future<LevelUpResponseDto?> addXP(String userId, String authToken, AddXPDto addXPDto) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/gamification/xp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(addXPDto.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['levelUp'] == true) {
          return LevelUpResponseDto.fromJson(data);
        }
        return null;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token inválido');
      } else {
        throw ServerException('Erro ao adicionar XP: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao adicionar XP: $e');
    }
  }

  /// Busca histórico de XP
  Future<List<XPHistoryResponseDto>> getXPHistory(
    String userId,
    String authToken, {
    XPSource? source,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 10,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (source != null) queryParams['source'] = source.name;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final uri = Uri.parse('$_baseUrl/gamification/xp/history').replace(
        queryParameters: queryParams,
      );

      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final historyData = data['history'] as List;
        return historyData.map((item) => XPHistoryResponseDto.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token inválido');
      } else {
        throw ServerException('Erro ao buscar histórico: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao buscar histórico: $e');
    }
  }

  // ===== AÇÕES DE INTEGRAÇÃO =====

  /// Processa conclusão de aula para gamificação
  Future<void> processClassCompletion(String userId, String authToken, String classId) async {
    print('🌐 [SERVICE] ===== INICIANDO CHAMADA API =====');
    print('🌐 [SERVICE] UserId: $userId');
    print('🌐 [SERVICE] ClassId: $classId');
    print('🌐 [SERVICE] URL: $_baseUrl/gamification/actions/class-completion');
    
    if (!await _networkInfo.isConnected) {
      print('❌ [SERVICE] Sem conexão com a internet');
      throw NetworkException('Sem conexão com a internet');
    }
    print('🌐 [SERVICE] Conexão com internet verificada');

    try {
      final requestBody = {'classId': classId};
      print('🌐 [SERVICE] Request body: $requestBody');
      
      final response = await _client.post(
        Uri.parse('$_baseUrl/gamification/actions/class-completion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(requestBody),
      );

      print('🌐 [SERVICE] Response status: ${response.statusCode}');
      print('🌐 [SERVICE] Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ [SERVICE] API chamada com sucesso - Status 200');
        return;
      } else if (response.statusCode == 401) {
        print('❌ [SERVICE] Token inválido - Status 401');
        throw UnauthorizedException('Token inválido');
      } else {
        print('❌ [SERVICE] Erro do servidor - Status ${response.statusCode}');
        throw ServerException('Erro ao processar conclusão: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [SERVICE] Erro na chamada API: $e');
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao processar conclusão: $e');
    }
  }

  /// Processa login diário para gamificação
  Future<void> processDailyLogin(String userId, String authToken) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/gamification/actions/daily-login'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token inválido');
      } else {
        throw ServerException('Erro ao processar login: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao processar login: $e');
    }
  }
}
