import '../entities/onboarding_state.dart';
import '../repositories/onboarding_repository.dart';

/// Caso de uso para obter o estado de onboarding
class GetOnboardingStateUseCase {
  final OnboardingRepository repository;

  GetOnboardingStateUseCase(this.repository);

  /// Executa o caso de uso
  Future<OnboardingState> call() async {
    return await repository.getOnboardingState();
  }
}
