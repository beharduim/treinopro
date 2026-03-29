/// Constantes para as imagens do onboarding
class OnboardingImages {
  OnboardingImages._();

  // Imagens para alunos (usando fallbacks por enquanto)
  static const String studentLogo = 'assets/images/logo.png'; // Fallback para logo existente
  static const String studentTraining = 'assets/images/student_profile.png'; // Fallback para imagem existente
  static const String studentProgress = 'assets/images/student_profile.png'; // Fallback para imagem existente

  // Imagens para professores (usando fallbacks por enquanto)
  static const String teacherLogo = 'assets/images/logo.png'; // Fallback para logo existente
  static const String teacherTraining = 'assets/images/trainer_profile.png'; // Fallback para imagem existente
  static const String teacherProgress = 'assets/images/trainer_profile.png'; // Fallback para imagem existente

  // Imagens de fallback (caso as específicas não existam)
  static const String fallbackLogo = 'assets/images/logo.png';
  static const String fallbackBackground = 'assets/images/initial-login-bg.jpg';
  
  // Imagens de background reais do onboarding (uma por página)
  static const String gymBackground1 = 'assets/images/onboarding/onboarding_01.jpg';
  static const String gymBackground2 = 'assets/images/onboarding/onboarding_02.jpg';
  static const String gymBackground3 = 'assets/images/onboarding/onboarding_03.jpg';
  // Fallback
  static const String gymBackground = 'assets/images/initial-login-bg.jpg';

  /// Lista de todas as imagens necessárias para o onboarding
  static const List<String> requiredImages = [
    studentLogo,
    studentTraining,
    studentProgress,
    teacherLogo,
    teacherTraining,
    teacherProgress,
    gymBackground,
  ];

  /// Lista de imagens essenciais (sem as quais o onboarding não funciona)
  static const List<String> essentialImages = [
    studentLogo,
    studentTraining,
    studentProgress,
    gymBackground1,
    gymBackground2,
    gymBackground3,
  ];

  /// Verifica se uma imagem existe
  static bool hasImage(String imagePath) {
    // Em um caso real, você poderia verificar se o arquivo existe
    // Por enquanto, retornamos true para não quebrar o app
    return true;
  }

  /// Obtém a imagem com fallback
  static String getImageWithFallback(String imagePath, String fallbackPath) {
    if (hasImage(imagePath)) {
      return imagePath;
    }
    return fallbackPath;
  }

  /// Obtém a imagem de background com fallback
  static String getBackgroundImage({int pageIndex = 0}) {
    // Seleciona por página com fallback
    final candidates = [gymBackground1, gymBackground2, gymBackground3];
    final idx = (pageIndex >= 0 && pageIndex < candidates.length) ? pageIndex : 0;
    final selected = candidates[idx];
    if (hasImage(selected)) return selected;
    return fallbackBackground;
  }

  /// Obtém a imagem do logo com fallback
  static String getLogoImage(String specificLogo) {
    // Prioridade: logo específico > fallbackLogo
    if (hasImage(specificLogo)) {
      return specificLogo;
    }
    return fallbackLogo;
  }
}
