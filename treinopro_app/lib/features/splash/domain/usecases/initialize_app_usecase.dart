import '../../../../core/constants/app_durations.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../home/data/services/auth_service.dart';

/// Use case responsável por inicializar a aplicação durante a splash screen
class InitializeAppUseCase {
  final AuthService _authService = sl<AuthService>();

  /// Inicializa a aplicação com delay para mostrar a splash screen
  Future<bool> call() async {
    // Simula carregamento inicial da aplicação
    await Future.delayed(AppDurations.splashDuration);
    
    // Verificar se o usuário está autenticado
    final isAuthenticated = _authService.isAuthenticated;
    
    if (isAuthenticated) {
      final userType = _authService.currentUserType;
      print('Splash: Usuário já autenticado, token encontrado');
      print('Splash: Tipo de usuário: $userType');
      // Aqui poderia verificar se o token ainda é válido
      // mas por enquanto vamos assumir que está válido
    } else {
      print('Splash: Usuário não autenticado, redirecionando para login');
    }
    
    // Outras inicializações:
    // - Carregamento de configurações
    // - Verificação de conectividade
    // - Pré-carregamento de dados essenciais
    
    return isAuthenticated;
  }
}
