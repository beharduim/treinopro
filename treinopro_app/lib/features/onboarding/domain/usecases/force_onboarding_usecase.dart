import '../repositories/onboarding_repository.dart';
import '../entities/onboarding_state.dart';

/// Use case para forçar o onboarding para novos usuários
class ForceOnboardingUseCase {
  final OnboardingRepository repository;

  ForceOnboardingUseCase(this.repository);

  /// Força o onboarding para aparecer, ignorando o status salvo
  Future<OnboardingState> call() async {
    try {
      // Limpar o status do onboarding para forçar aparecer
      await repository.clearOnboardingStatus();
      
      // Retornar um estado limpo para mostrar o onboarding
      return const OnboardingState(
        currentPage: 0,
        isCompleted: false,
      );
    } catch (e) {
      // Em caso de erro, retornar estado padrão
      return const OnboardingState(
        currentPage: 0,
        isCompleted: false,
      );
    }
  }
}
