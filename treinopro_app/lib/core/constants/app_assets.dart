/// Caminhos dos assets do aplicativo
class AppAssets {
  AppAssets._();

  /// Pasta base dos assets de imagens
  static const String _imagesPath = 'assets/images/';

  /// Logo principal do aplicativo
  static const String logo = '${_imagesPath}logo.png';

  /// Logo variante para tela de login
  static const String logoVariant = '${_imagesPath}logo_variant.png';

  /// Imagem de fundo da tela de login
  static const String loginBackground = '${_imagesPath}initial-login-bg.jpg';

  /// Imagem do perfil de aluno
  static const String studentProfile =
      '${_imagesPath}student-profile-choice.jpg';

  /// Imagem do perfil de personal trainer
  static const String trainerProfile =
      '${_imagesPath}teacher-profile-choice.jpg';

  /// Ícone de seta para voltar
  static const String chevronLeft = '${_imagesPath}chevron_left.svg';
}
