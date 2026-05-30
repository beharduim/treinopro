import '../../../../core/constants/app_durations.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/errors/account_access_denied_exception.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/account_access_error_parser.dart';
import '../../../home/data/services/auth_service.dart';

/// Use case responsável por inicializar a aplicação durante a splash screen
class InitializeAppUseCase {
  final AuthService _authService = sl<AuthService>();
  final ApiService _apiService = sl<ApiService>();

  AccountAccessDeniedException? pendingAccountAccess;

  /// Inicializa a aplicação com delay para mostrar a splash screen
  Future<bool> call() async {
    pendingAccountAccess = null;

    await Future.delayed(AppDurations.splashDuration);

    if (!_authService.isAuthenticated) {
      print('Splash: Usuário não autenticado, redirecionando para login');
      return false;
    }

    final approvalStatus = _authService.currentApprovalStatus;
    if (approvalStatus == 'rejected') {
      print('Splash: Cadastro recusado — limpando sessão local');
      pendingAccountAccess = const AccountAccessDeniedException(
        message: 'Seu cadastro foi recusado.',
        reason: AccountAccessDeniedReason.rejected,
      );
      await _clearLocalSession();
      return false;
    }

    final sessionValid = await _validateRemoteSession();
    if (!sessionValid) {
      return false;
    }

    print('Splash: Usuário autenticado, token válido');
    print('Splash: Tipo de usuário: ${_authService.currentUserType}');
    return true;
  }

  Future<bool> _validateRemoteSession() async {
    try {
      await _apiService.dio
          .get('/users/profile/me')
          .timeout(const Duration(seconds: 6));
      return true;
    } catch (e) {
      final blocked = parseAccountAccessError(e);
      if (blocked != null) {
        print('Splash: Sessão bloqueada/recusada — limpando sessão local');
        pendingAccountAccess = blocked;
        await _clearLocalSession();
        return false;
      }

      print('Splash: Falha ao validar sessão remotamente, mantendo login local: $e');
      return _authService.isAuthenticated;
    }
  }

  Future<void> _clearLocalSession() async {
    await _apiService.clearTokens();
    await _authService.clearTokens();
  }
}
