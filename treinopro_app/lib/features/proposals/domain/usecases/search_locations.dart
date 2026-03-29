import '../entities/training_location.dart';
import '../repositories/proposals_repository.dart';

/// Caso de uso para buscar locais de treino
class SearchLocations {
  final ProposalsRepository repository;

  SearchLocations(this.repository);

  Future<List<TrainingLocation>> call(String query) async {
    return await repository.searchLocations(query);
  }
}
