import '../../../auth/data/datasources/auth_api_datasource.dart';
import '../../../auth/data/models/email_verification_response.dart';

class VerifyCodeUseCase {
  final AuthApiDataSource _authApiDataSource;

  VerifyCodeUseCase(this._authApiDataSource);

  Future<VerifyCodeResponse> call(String email, String code) async {
    return await _authApiDataSource.verifyCode(email, code);
  }
}
