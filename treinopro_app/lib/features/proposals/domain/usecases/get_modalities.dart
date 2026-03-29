import '../entities/training_modality.dart';
import '../repositories/proposals_repository.dart';

/// Caso de uso para obter modalidades de treino
class GetModalities {
  final ProposalsRepository repository;

  GetModalities(this.repository);

  Future<List<TrainingModality>> call() async {
    return await repository.getModalities();
  }
}
