import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';

class EvaluationApiService {
  final ApiService _apiService;

  EvaluationApiService({required ApiService apiService}) : _apiService = apiService;

  /// Criar avaliação do personal trainer (aluno avalia)
  Future<Map<String, dynamic>> createPersonalRating({
    required String classId,
    required int rating,
    String? comment,
    int? punctuality,
    int? communication,
    int? knowledge,
    int? motivation,
    int? equipment,
  }) async {
    try {
      // ✅ Debug: Log do payload antes de enviar
      final payload = {
        'classId': classId,
        'type': 'student_to_personal',
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        if (punctuality != null) 'punctuality': punctuality,
        if (communication != null) 'communication': communication,
        if (knowledge != null) 'knowledge': knowledge,
        if (motivation != null) 'motivation': motivation,
        if (equipment != null) 'equipment': equipment,
      };
      print('📤 [EVAL_API] Enviando createPersonalRating - payload: $payload');
      
      final response = await _apiService.dio.post(
        '/ratings',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{'ok': true};
      }
      throw Exception('Erro ao criar avaliação: $code');
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        final message = data is Map
            ? (data['message'] ?? data['error'] ?? 'Erro na requisição')
            : 'Erro na requisição';
        throw Exception(message.toString());
      }
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      throw Exception('Erro desconhecido: $e');
    }
  }

  /// Criar avaliação do aluno (personal trainer avalia)
  Future<Map<String, dynamic>> createStudentRating({
    required String classId,
    required int rating,
    String? comment,
    int? studentEngagement,
    int? studentEffort,
    int? studentProgress,
  }) async {
    try {
      // ✅ Debug: Log do payload antes de enviar
      final payload = {
        'classId': classId,
        'type': 'personal_to_student',
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        if (studentEngagement != null) 'studentEngagement': studentEngagement,
        if (studentEffort != null) 'studentEffort': studentEffort,
        if (studentProgress != null) 'studentProgress': studentProgress,
      };
      print('📤 [EVAL_API] Enviando createStudentRating - payload: $payload');
      
      final response = await _apiService.dio.post(
        '/ratings',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{'ok': true};
      }
      throw Exception('Erro ao criar avaliação: $code');
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        final message = data is Map
            ? (data['message'] ?? data['error'] ?? 'Erro na requisição')
            : 'Erro na requisição';
        throw Exception(message.toString());
      }
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      throw Exception('Erro desconhecido: $e');
    }
  }

  /// Verificar se já existe avaliação para uma aula
  Future<bool> hasExistingRating({
    required String classId,
    required String type,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/ratings',
        queryParameters: {
          'classId': classId,
          'type': type,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> ratings = response.data['data'] ?? [];
        return ratings.isNotEmpty;
      } else {
        return false;
      }
    } catch (e) {
      print('Erro ao verificar avaliação existente: $e');
      return false;
    }
  }

  /// Obter avaliação específica de uma aula
  /// ⚠️ WORKAROUND: O backend retorna a média geral do aluno no campo `studentRating` da classe.
  /// Este método busca a avaliação específica desta aula.
  Future<int?> getClassRating({
    required String classId,
    required String type,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/ratings',
        queryParameters: {
          'classId': classId,
          'type': type,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> ratings = response.data['data'] ?? [];
        if (ratings.isNotEmpty) {
          final rating = ratings.first as Map<String, dynamic>;
          final ratingValue = rating['rating'];
          if (ratingValue != null) {
            final parsed = int.tryParse(ratingValue.toString());
            print('⭐ [EVAL_API] Avaliação específica encontrada para aula $classId: $parsed');
            return parsed;
          }
        }
        print('⭐ [EVAL_API] Nenhuma avaliação específica encontrada para aula $classId');
        return null;
      } else {
        return null;
      }
    } catch (e) {
      print('❌ [EVAL_API] Erro ao buscar avaliação específica: $e');
      return null;
    }
  }

  /// Obter avaliações pendentes do usuário
  Future<List<Map<String, dynamic>>> getPendingRatings() async {
    try {
      final response = await _apiService.dio.get('/ratings/pending');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        throw Exception('Erro ao buscar avaliações pendentes: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Erro na requisição');
      } else {
        throw Exception('Erro de conexão: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro desconhecido: $e');
    }
  }
}
