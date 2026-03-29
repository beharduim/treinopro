import '../entities/health_questionnaire.dart';
import '../repositories/health_questionnaire_repository.dart';

/// Caso de uso para recuperar o questionário de saúde
class GetHealthQuestionnaire {
  final HealthQuestionnaireRepository repository;

  GetHealthQuestionnaire(this.repository);

  Future<HealthQuestionnaire?> call() async {
    return await repository.getQuestionnaire();
  }
}
