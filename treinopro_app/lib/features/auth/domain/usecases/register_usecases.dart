import '../../data/datasources/auth_api_datasource.dart';
import '../../data/models/register_request.dart';
import '../../data/models/auth_response.dart';

/// Use case responsável por realizar o registro do usuário
class RegisterUserUseCase {
  final AuthApiDataSource _authApiDataSource;

  RegisterUserUseCase(this._authApiDataSource);

  /// Executa o registro com os dados do usuário
  Future<AuthResponse> call({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String birthDate,
    required String userType,
    required String documentType,
    required String documentNumber,
    required String documentImageId,
    String? cref,
    String? crefImageId,
    List<String>? specialties,
    required bool isMinor,
    String? guardianName,
    String? guardianEmail,
    required bool guardianConsent,
    required bool termsAccepted,
    required bool privacyPolicyAccepted,
  }) async {
    final request = RegisterRequest(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      userType: userType,
      documentType: documentType,
      documentNumber: documentNumber,
      documentImageId: documentImageId,
      cref: cref,
      crefImageId: crefImageId,
      specialties: specialties,
      isMinor: isMinor,
      guardianName: guardianName,
      guardianEmail: guardianEmail,
      guardianConsent: guardianConsent,
      termsAccepted: termsAccepted,
      privacyPolicyAccepted: privacyPolicyAccepted,
    );

    return await _authApiDataSource.register(request);
  }
}
