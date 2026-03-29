import '../../data/datasources/auth_api_datasource.dart';
import '../../data/models/register_request.dart';
import '../../data/models/auth_response.dart';

/// Use case responsável por realizar o registro do aluno
class StudentRegistrationUseCase {
  final AuthApiDataSource _authApiDataSource;

  StudentRegistrationUseCase(this._authApiDataSource);

  /// Executa o registro do aluno com todos os dados coletados
  Future<AuthResponse> call({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String birthDate,
    required String documentType,
    required String documentNumber,
    required String documentImageId,
    required bool isMinor,
    String? guardianName,
    String? guardianEmail,
    required bool guardianConsent,
    required bool termsAccepted,
    required bool privacyPolicyAccepted,
  }) async {
    final request = RegisterRequest.student(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      documentType: documentType,
      documentNumber: documentNumber,
      documentImageId: documentImageId,
      isMinor: isMinor,
      guardianName: isMinor ? guardianName : null,
      guardianEmail: isMinor ? guardianEmail : null,
      guardianConsent: isMinor ? guardianConsent : false,
      termsAccepted: termsAccepted,
      privacyPolicyAccepted: privacyPolicyAccepted,
    );

    return await _authApiDataSource.register(request);
  }
}
