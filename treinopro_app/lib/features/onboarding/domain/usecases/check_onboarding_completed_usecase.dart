import '../repositories/onboarding_repository.dart';

/// Caso de uso para verificar se o onboarding foi completado
class CheckOnboardingCompletedUseCase {
  final OnboardingRepository repository;

  CheckOnboardingCompletedUseCase(this.repository);

  /// Executa o caso de uso
  Future<bool> call() async {
    return await repository.isOnboardingCompleted();
  }
}
