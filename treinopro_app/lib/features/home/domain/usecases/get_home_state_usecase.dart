import '../entities/home_state.dart';
import '../repositories/home_repository.dart';

/// Use case para obter o estado da home
class GetHomeStateUseCase {
  final HomeRepository repository;

  GetHomeStateUseCase(this.repository);

  Future<HomeState> call() async {
    return await repository.getHomeState();
  }
}
