import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/onboarding_state.dart';
import '../../domain/repositories/onboarding_repository.dart';

/// Implementação do repositório de onboarding usando SharedPreferences
class OnboardingRepositoryImpl implements OnboardingRepository {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _onboardingCurrentPageKey = 'onboarding_current_page';

  @override
  Future<void> saveOnboardingState(OnboardingState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, state.isCompleted);
      await prefs.setInt(_onboardingCurrentPageKey, state.currentPage);
      print('OnboardingRepositoryImpl: Estado salvo - isCompleted: ${state.isCompleted}, currentPage: ${state.currentPage}');
    } catch (e) {
      print('OnboardingRepositoryImpl: Erro ao salvar estado: $e');
    }
  }

  @override
  Future<OnboardingState> getOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    final isCompleted = prefs.getBool(_onboardingCompletedKey) ?? false;
    final currentPage = prefs.getInt(_onboardingCurrentPageKey) ?? 0;
    
    return OnboardingState(
      currentPage: currentPage,
      isCompleted: isCompleted,
    );
  }

  @override
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  @override
  Future<void> updateCurrentPage(int page) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_onboardingCurrentPageKey, page);
      print('OnboardingRepositoryImpl: Página atual atualizada para $page');
    } catch (e) {
      print('OnboardingRepositoryImpl: Erro ao atualizar página: $e');
    }
  }

  @override
  Future<void> clearOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompletedKey);
      await prefs.remove(_onboardingCurrentPageKey);
      print('OnboardingRepositoryImpl: Status do onboarding limpo');
    } catch (e) {
      print('OnboardingRepositoryImpl: Erro ao limpar status: $e');
    }
  }

  @override
  Future<void> resetOnboardingForNewUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Garantir que o onboarding não está marcado como completado para novos usuários
      await prefs.setBool(_onboardingCompletedKey, false);
      await prefs.setInt(_onboardingCurrentPageKey, 0);
      print('OnboardingRepositoryImpl: Onboarding resetado para novo usuário');
    } catch (e) {
      print('OnboardingRepositoryImpl: Erro ao resetar onboarding: $e');
    }
  }
}
