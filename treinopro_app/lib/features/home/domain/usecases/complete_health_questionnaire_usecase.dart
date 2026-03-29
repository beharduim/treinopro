import '../repositories/home_repository.dart';

/// Use case para completar o questionário de saúde
class CompleteHealthQuestionnaireUseCase {
  final HomeRepository repository;

  CompleteHealthQuestionnaireUseCase(this.repository);

  Future<void> call() async {
    await repository.completeHealthQuestionnaire();
  }
}
