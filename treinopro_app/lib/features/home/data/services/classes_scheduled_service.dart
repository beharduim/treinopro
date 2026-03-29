import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../models/class_response_dto.dart';
import 'auth_service.dart';

/// Serviço para gerenciar aulas agendadas
class ClassesScheduledService {
  final http.Client _client;
  final NetworkInfo _networkInfo;
  final AuthService _authService;

  ClassesScheduledService({
    required http.Client client,
    required NetworkInfo networkInfo,
    required AuthService authService,
  }) : _client = client, 
       _networkInfo = networkInfo,
       _authService = authService;

  /// Busca aulas do usuário autenticado.
  /// O backend já filtra por `req.user.sub`, então evitamos depender de `studentId`
  /// vindo do estado local (que pode estar desatualizado e esconder aulas válidas).
  Future<List<ClassResponseDto>> getScheduledClasses() async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    final token = await _authService.getValidToken();
    if (token == null) {
      throw UnauthorizedException('Usuário não autenticado - token obrigatório');
    }
    
    print('🔑 DEBUG: Usando token para aulas: ${token.substring(0, 20)}...');

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/classes')
          .replace(queryParameters: {
        'limit': '50', // Buscar mais aulas para ter dados completos
      });

      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final classes = (data['classes'] as List)
            .map((json) => ClassResponseDto.fromJson(json))
            .toList();
        
        return classes;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token de autenticação inválido');
      } else if (response.statusCode == 403) {
        throw UnauthorizedException('Sem permissão para acessar aulas');
      } else {
        throw ServerException('Erro ao buscar aulas agendadas: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao buscar aulas: $e');
    }
  }

  /// Busca uma aula específica por ID
  Future<ClassResponseDto> getClassById(String classId) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    final token = await _authService.getValidToken();
    if (token == null) {
      throw UnauthorizedException('Usuário não autenticado');
    }

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/classes/$classId');

      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ClassResponseDto.fromJson(data);
      } else if (response.statusCode == 404) {
        throw ServerException('Aula não encontrada');
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token de autenticação inválido');
      } else if (response.statusCode == 403) {
        throw UnauthorizedException('Sem permissão para acessar esta aula');
      } else {
        throw ServerException('Erro ao buscar aula: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao buscar aula: $e');
    }
  }

  /// Cancela uma aula agendada
  Future<ClassResponseDto> cancelClass(String classId) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    final token = await _authService.getValidToken();
    if (token == null) {
      throw UnauthorizedException('Usuário não autenticado');
    }

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/classes/$classId/cancel');

      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ClassResponseDto.fromJson(data);
      } else if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ClassResponseDto.fromJson(data);
      } else if (response.statusCode == 404) {
        throw ServerException('Aula não encontrada');
      } else if (response.statusCode == 400) {
        throw ServerException('Aula não pode ser cancelada');
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token de autenticação inválido');
      } else if (response.statusCode == 403) {
        throw UnauthorizedException('Sem permissão para cancelar esta aula');
      } else {
        throw ServerException('Erro ao cancelar aula: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao cancelar aula: $e');
    }
  }

  /// Busca estatísticas das aulas do usuário
  Future<Map<String, dynamic>> getClassStats(String userId) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    final token = await _authService.getValidToken();
    if (token == null) {
      throw UnauthorizedException('Usuário não autenticado');
    }

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/classes/stats');

      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token de autenticação inválido');
      } else {
        throw ServerException('Erro ao buscar estatísticas: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao buscar estatísticas: $e');
    }
  }
}
