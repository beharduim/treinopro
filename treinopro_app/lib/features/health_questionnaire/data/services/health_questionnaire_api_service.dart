import '../../../../core/services/api_service.dart';
import '../models/health_questionnaire_model.dart';

class HealthQuestionnaireApiService {
  final ApiService _apiService;

  HealthQuestionnaireApiService(this._apiService);

  /// Criar ou atualizar questionário de saúde
  Future<HealthQuestionnaireModel> createOrUpdateQuestionnaire(
    HealthQuestionnaireModel questionnaire,
  ) async {
    try {
      print('🏥 [HEALTH_API] Criando/atualizando questionário...');
      
      final response = await _apiService.dio.post(
        '/health-questionnaire',
        data: questionnaire.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [HEALTH_API] Questionário salvo com sucesso');
        return HealthQuestionnaireModel.fromJson(response.data);
      } else {
        throw Exception('Erro ao salvar questionário: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [HEALTH_API] Erro ao salvar questionário: $e');
      throw Exception('Falha ao conectar com a API: $e');
    }
  }

  /// Obter questionário de saúde do usuário
  Future<HealthQuestionnaireModel?> getQuestionnaire() async {
    try {
      print('🏥 [HEALTH_API] Buscando questionário...');
      
      final response = await _apiService.dio.get('/health-questionnaire/me');

      if (response.statusCode == 200) {
        print('✅ [HEALTH_API] Questionário encontrado');
        return HealthQuestionnaireModel.fromJson(response.data);
      } else {
        throw Exception('Erro ao buscar questionário: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [HEALTH_API] Erro ao buscar questionário: $e');
      throw Exception('Falha ao conectar com a API: $e');
    }
  }

  /// Verificar se questionário foi completado
  Future<bool> isQuestionnaireCompleted() async {
    try {
      print('🏥 [HEALTH_API] Verificando status do questionário...');
      
      final response = await _apiService.dio.get('/health-questionnaire/me/status');

      if (response.statusCode == 200) {
        final data = response.data;
        final isCompleted = data['isCompleted'] ?? false;
        print('✅ [HEALTH_API] Status: ${isCompleted ? "Completado" : "Não completado"}');
        return isCompleted;
      } else {
        throw Exception('Erro ao verificar status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [HEALTH_API] Erro ao verificar status: $e');
      return false;
    }
  }

  /// Listar questionários de saúde dos alunos (para personal trainers)
  Future<List<StudentHealthQuestionnaireModel>> getStudentQuestionnaires({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('🏥 [HEALTH_API] Listando questionários dos alunos...');
      
      final response = await _apiService.dio.get(
        '/health-questionnaire/students',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final questionnaires = (data['questionnaires'] as List)
            .map((json) => StudentHealthQuestionnaireModel.fromJson(json))
            .toList();
        
        print('✅ [HEALTH_API] ${questionnaires.length} questionários encontrados');
        return questionnaires;
      } else {
        throw Exception('Erro ao listar questionários: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [HEALTH_API] Erro ao listar questionários: $e');
      throw Exception('Falha ao conectar com a API: $e');
    }
  }

  /// Obter questionário específico de um aluno (para personal trainer)
  Future<StudentHealthQuestionnaireModel?> getStudentQuestionnaire(String studentId) async {
    try {
      print('🏥 [HEALTH_API] Buscando questionário do aluno: $studentId');
      
      final response = await _apiService.dio.get('/health-questionnaire/students/$studentId');

      if (response.statusCode == 200) {
        print('✅ [HEALTH_API] Questionário do aluno encontrado');
        return StudentHealthQuestionnaireModel.fromJson(response.data);
      } else if (response.statusCode == 404) {
        print('ℹ️ [HEALTH_API] Questionário do aluno não encontrado');
        return null;
      } else {
        throw Exception('Erro ao buscar questionário do aluno: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [HEALTH_API] Erro ao buscar questionário do aluno: $e');
      throw Exception('Falha ao conectar com a API: $e');
    }
  }

  /// Deletar questionário de saúde
  Future<void> deleteQuestionnaire(String questionnaireId) async {
    try {
      print('🏥 [HEALTH_API] Deletando questionário: $questionnaireId');
      
      final response = await _apiService.dio.delete('/health-questionnaire/$questionnaireId');

      if (response.statusCode == 204) {
        print('✅ [HEALTH_API] Questionário deletado com sucesso');
      } else {
        throw Exception('Erro ao deletar questionário: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [HEALTH_API] Erro ao deletar questionário: $e');
      throw Exception('Falha ao conectar com a API: $e');
    }
  }
}
