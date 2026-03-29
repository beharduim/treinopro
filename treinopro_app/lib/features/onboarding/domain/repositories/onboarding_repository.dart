import '../entities/onboarding_state.dart';

/// Repositório para gerenciar o estado de onboarding
abstract class OnboardingRepository {
  /// Obtém o estado atual do onboarding
  Future<OnboardingState> getOnboardingState();

  /// Verifica se o onboarding foi completado
  Future<bool> isOnboardingCompleted();

  /// Marca o onboarding como completado
  Future<void> completeOnboarding();

  /// Atualiza a página atual do onboarding
  Future<void> updateCurrentPage(int page);

  /// Limpa o status do onboarding
  Future<void> clearOnboardingStatus();

  /// Reseta o onboarding para novos usuários
  Future<void> resetOnboardingForNewUser();
}
