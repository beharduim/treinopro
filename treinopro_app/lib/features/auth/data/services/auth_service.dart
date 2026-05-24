import '../datasources/auth_api_datasource.dart';
import '../models/forgot_password_request.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/services/api_service.dart';

/// Serviço de autenticação que encapsula as operações de recuperação de senha
class ForgotPasswordAuthService {
  final AuthApiDataSource _authApiDataSource;
  final ApiService _apiService = sl<ApiService>();

  ForgotPasswordAuthService(this._authApiDataSource);

  /// Envia código de reset de senha
  Future<void> sendPasswordResetCode(String email) async {
    print('ForgotPasswordAuthService: Enviando código de reset para $email');
    final request = ForgotPasswordRequest(email: email);
    print('ForgotPasswordAuthService: Request criado: ${request.toJson()}');
    await _authApiDataSource.forgotPassword(request);
    print('ForgotPasswordAuthService: Código enviado com sucesso');
  }

  /// Verifica código OTP de recuperação de senha
  Future<void> verifyPasswordResetCode(String email, String code) async {
    final response = await _apiService.dio.post(
      '/auth/verify-reset-code',
      data: {'email': email, 'code': code},
    );

    if (response.statusCode != 200) {
      throw Exception('Falha na verificação do código de recuperação');
    }
  }

  /// Reseta a senha do usuário
  Future<void> resetPassword(String email, String code, String newPassword) async {
    print('ForgotPasswordAuthService: Resetando senha para $email');
    
    final response = await _apiService.dio.post(
      '/auth/reset-password-with-code',
      data: {
        'email': email,
        'code': code,
        'newPassword': newPassword,
      },
    );

    print('ForgotPasswordAuthService: Resposta do reset - Status: ${response.statusCode}');
    print('ForgotPasswordAuthService: Resposta data: ${response.data}');

    if (response.statusCode != 200) {
      throw Exception('Falha ao resetar senha: ${response.statusMessage}');
    }
    
    print('ForgotPasswordAuthService: Senha resetada com sucesso');
  }
}
