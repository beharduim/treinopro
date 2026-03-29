import '../entities/health_questionnaire.dart';

/// Repositório para o questionário de saúde
abstract class HealthQuestionnaireRepository {
  /// Salva as respostas do questionário
  Future<void> saveQuestionnaire(HealthQuestionnaire questionnaire);
  
  /// Recupera o questionário salvo
  Future<HealthQuestionnaire?> getQuestionnaire();
  
  /// Verifica se o questionário foi completado
  Future<bool> isQuestionnaireCompleted();
}
