import '../entities/health_questionnaire.dart';
import '../repositories/health_questionnaire_repository.dart';

/// Caso de uso para salvar o questionário de saúde
class SaveHealthQuestionnaire {
  final HealthQuestionnaireRepository repository;

  SaveHealthQuestionnaire(this.repository);

  Future<void> call(HealthQuestionnaire questionnaire) async {
    await repository.saveQuestionnaire(questionnaire);
  }
}
