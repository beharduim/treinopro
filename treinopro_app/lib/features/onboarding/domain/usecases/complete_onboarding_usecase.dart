import '../repositories/onboarding_repository.dart';

/// Caso de uso para completar o onboarding
class CompleteOnboardingUseCase {
  final OnboardingRepository repository;

  CompleteOnboardingUseCase(this.repository);

  /// Executa o caso de uso
  Future<void> call() async {
    await repository.completeOnboarding();
  }
}
