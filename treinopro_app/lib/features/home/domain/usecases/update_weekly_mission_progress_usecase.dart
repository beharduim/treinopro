import '../repositories/home_repository.dart';

/// Use case para atualizar o progresso da missão semanal
class UpdateWeeklyMissionProgressUseCase {
  final HomeRepository repository;

  UpdateWeeklyMissionProgressUseCase(this.repository);

  Future<void> call(int progress) async {
    await repository.updateWeeklyMissionProgress(progress);
  }
}
