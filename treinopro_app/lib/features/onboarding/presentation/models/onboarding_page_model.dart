import '../constants/onboarding_images.dart';

/// Modelo para uma página de onboarding
class OnboardingPageModel {
  final String title;
  final String description;
  final String imagePath;
  final String? backgroundImagePath;

  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.imagePath,
    this.backgroundImagePath,
  });

  /// Obtém a imagem de background com fallback
  String get effectiveBackgroundImage => backgroundImagePath ?? OnboardingImages.getBackgroundImage();

  /// Obtém a imagem principal com fallback
  String get effectiveImage => OnboardingImages.getLogoImage(imagePath);
}

/// Dados das páginas de onboarding para alunos
class StudentOnboardingPages {
  static const List<OnboardingPageModel> pages = [
    OnboardingPageModel(
      title: 'Treine do seu jeito',
      description: 'Escolha o local, o horário e o valor. Liberdade total pra cuidar de você.',
      imagePath: OnboardingImages.studentLogo,
      backgroundImagePath: OnboardingImages.gymBackground1,
    ),
    OnboardingPageModel(
      title: 'Diversidade de personais',
      description: 'Explore diferentes estilos de treino e encontre o personal perfeito pra você.',
      imagePath: OnboardingImages.studentTraining,
      backgroundImagePath: OnboardingImages.gymBackground2,
    ),
    OnboardingPageModel(
      title: 'Resultados reais',
      description: 'Transforme esforço em evolução. Seu progresso agora tem propósito.',
      imagePath: OnboardingImages.studentProgress,
      backgroundImagePath: OnboardingImages.gymBackground3,
    ),
  ];
}

/// Dados das páginas de onboarding para professores (futuro)
class TeacherOnboardingPages {
  static const List<OnboardingPageModel> pages = [
    OnboardingPageModel(
      title: 'Controle total da sua agenda',
      description: 'Tenha autonomia completa sobre suas aulas, horários e alunos. Você no comando do seu tempo.',
      imagePath: OnboardingImages.teacherLogo,
      backgroundImagePath: OnboardingImages.gymBackground1,
    ),
    OnboardingPageModel(
      title: 'Conecte-se a novos alunos',
      description: 'Receba propostas em tempo real e aumente sua renda aproveitando seus horários ociosos.',
      imagePath: OnboardingImages.teacherTraining,
      backgroundImagePath: OnboardingImages.gymBackground2,
    ),
    OnboardingPageModel(
      title: 'Cresça com o TreinoPro',
      description: 'Suba de nível, conquiste XP e se torne referência no mundo fitness.',
      imagePath: OnboardingImages.teacherProgress,
      backgroundImagePath: OnboardingImages.gymBackground3,
    ),
  ];
}
