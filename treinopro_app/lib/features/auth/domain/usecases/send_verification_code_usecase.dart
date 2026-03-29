import '../../../auth/data/datasources/auth_api_datasource.dart';
import '../../../auth/data/models/email_verification_response.dart';

class SendVerificationCodeUseCase {
  final AuthApiDataSource _authApiDataSource;

  SendVerificationCodeUseCase(this._authApiDataSource);

  Future<SendVerificationCodeResponse> call(String email) async {
    return await _authApiDataSource.sendVerificationCode(email);
  }
}
