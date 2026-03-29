import '../../data/datasources/auth_api_datasource.dart';
import '../../data/models/login_request.dart';
import '../../data/models/auth_response.dart';
import '../../data/models/forgot_password_request.dart';

/// Use case responsável por realizar o login do usuário
class LoginUserUseCase {
  final AuthApiDataSource _authApiDataSource;

  LoginUserUseCase(this._authApiDataSource);

  /// Executa o login com email e senha
  Future<AuthResponse> call({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(
      email: email,
      password: password,
    );

    return await _authApiDataSource.login(request);
  }
}

/// Use case responsável por login com Google
class LoginWithGoogleUseCase {
  /// Executa o login com Google
  Future<void> call() async {
    // Aqui você integraria com o Google Sign In
    await Future.delayed(const Duration(seconds: 1));
  }
}

/// Use case responsável por login com Facebook
class LoginWithFacebookUseCase {
  /// Executa o login com Facebook
  Future<void> call() async {
    // Aqui você integraria com o Facebook Login
    await Future.delayed(const Duration(seconds: 1));
  }
}

/// Use case responsável por recuperação de senha
class ForgotPasswordUseCase {
  final AuthApiDataSource _authApiDataSource;

  ForgotPasswordUseCase(this._authApiDataSource);

  /// Executa a recuperação de senha
  Future<void> call({required String email}) async {
    final request = ForgotPasswordRequest(email: email);
    await _authApiDataSource.forgotPassword(request);
  }
}
