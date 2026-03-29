import '../../domain/entities/health_questionnaire.dart';
import '../../domain/repositories/health_questionnaire_repository.dart';
import '../services/health_questionnaire_api_service.dart';
import '../models/health_questionnaire_model.dart';

/// Implementação do repositório usando API
class HealthQuestionnaireRepositoryImpl implements HealthQuestionnaireRepository {
  final HealthQuestionnaireApiService _apiService;

  HealthQuestionnaireRepositoryImpl(this._apiService);

  @override
  Future<void> saveQuestionnaire(HealthQuestionnaire questionnaire) async {
    try {
      print('🏥 [HEALTH_REPO] Salvando questionário via API...');
      
      final model = HealthQuestionnaireModel(
        id: '', // Será gerado pela API
        userId: '', // Será preenchido pela API
        medicalCondition: questionnaire.medicalCondition,
        regularMedication: questionnaire.regularMedication,
        chronicInjury: questionnaire.chronicInjury,
        trainingGoal: questionnaire.trainingGoal,
        dietaryRestrictions: questionnaire.dietaryRestrictions,
        isCompleted: questionnaire.isCompleted,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _apiService.createOrUpdateQuestionnaire(model);
      print('✅ [HEALTH_REPO] Questionário salvo com sucesso via API');
    } catch (e) {
      print('❌ [HEALTH_REPO] Erro ao salvar questionário: $e');
      rethrow;
    }
  }

  @override
  Future<HealthQuestionnaire?> getQuestionnaire() async {
    try {
      print('🏥 [HEALTH_REPO] Buscando questionário via API...');
      
      final model = await _apiService.getQuestionnaire();
      if (model == null) {
        print('ℹ️ [HEALTH_REPO] Questionário não encontrado');
        return null;
      }

      final entity = HealthQuestionnaire(
        medicalCondition: model.medicalCondition,
        regularMedication: model.regularMedication,
        chronicInjury: model.chronicInjury,
        trainingGoal: model.trainingGoal,
        dietaryRestrictions: model.dietaryRestrictions,
        isCompleted: model.isCompleted,
      );

      print('✅ [HEALTH_REPO] Questionário encontrado via API');
      return entity;
    } catch (e) {
      print('❌ [HEALTH_REPO] Erro ao buscar questionário: $e');
      // Se for erro 404, retornar null (questionário não existe)
      if (e.toString().contains('404')) {
        print('ℹ️ [HEALTH_REPO] Questionário não encontrado (404)');
        return null;
      }
      return null;
    }
  }

  @override
  Future<bool> isQuestionnaireCompleted() async {
    try {
      print('🏥 [HEALTH_REPO] Verificando status via API...');
      
      final isCompleted = await _apiService.isQuestionnaireCompleted();
      print('✅ [HEALTH_REPO] Status: ${isCompleted ? "Completado" : "Não completado"}');
      return isCompleted;
    } catch (e) {
      print('❌ [HEALTH_REPO] Erro ao verificar status: $e');
      return false;
    }
  }
}
