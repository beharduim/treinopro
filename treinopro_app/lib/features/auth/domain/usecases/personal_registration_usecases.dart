import '../../data/datasources/auth_api_datasource.dart';
import '../../data/models/register_request.dart';
import '../../data/models/auth_response.dart';

/// Use case responsável por realizar o registro do personal trainer
class PersonalRegistrationUseCase {
  final AuthApiDataSource _authApiDataSource;

  PersonalRegistrationUseCase(this._authApiDataSource);

  /// Executa o registro do personal trainer com todos os dados coletados
  Future<AuthResponse> call({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String birthDate,
    required String documentType,
    required String documentNumber,
    required String documentImageId,
    required String cref,
    required String crefImageId,
    required List<String> specialties,
    required bool termsAccepted,
    required bool privacyPolicyAccepted,
  }) async {
    final request = RegisterRequest.personal(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      documentType: documentType,
      documentNumber: documentNumber,
      documentImageId: documentImageId,
      cref: cref,
      crefImageId: crefImageId,
      specialties: specialties,
      isMinor: false, // Personal trainers são sempre maiores de idade
      guardianConsent: false, // Personal trainers não precisam de consentimento
      termsAccepted: termsAccepted,
      privacyPolicyAccepted: privacyPolicyAccepted,
    );

    return await _authApiDataSource.register(request);
  }
}
