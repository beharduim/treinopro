import 'package:json_annotation/json_annotation.dart';

part 'register_request.g.dart';

@JsonSerializable()
class RegisterRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String birthDate; // ISO 8601 date string
  final String userType; // "student" ou "personal"
  final String documentType; // "RG" ou "CNH"
  final String documentNumber;
  final String documentImageId;
  final String? cref; // Opcional, apenas para personal trainers
  final String? crefImageId; // Opcional, apenas para personal trainers
  final List<String>? specialties; // Opcional, apenas para personal trainers
  final bool isMinor;
  final String? guardianName; // Opcional, apenas para menores
  final String? guardianEmail; // Opcional, apenas para menores
  final bool guardianConsent;
  final bool termsAccepted;
  final bool privacyPolicyAccepted;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.userType,
    required this.documentType,
    required this.documentNumber,
    required this.documentImageId,
    this.cref,
    this.crefImageId,
    this.specialties,
    required this.isMinor,
    this.guardianName,
    this.guardianEmail,
    required this.guardianConsent,
    required this.termsAccepted,
    required this.privacyPolicyAccepted,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);

  /// Factory para criar request de estudante
  factory RegisterRequest.student({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
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
  }) {
    return RegisterRequest(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      userType: 'student',
      documentType: documentType,
      documentNumber: documentNumber,
      documentImageId: documentImageId,
      isMinor: isMinor,
      guardianName: guardianName,
      guardianEmail: guardianEmail,
      guardianConsent: guardianConsent,
      termsAccepted: termsAccepted,
      privacyPolicyAccepted: privacyPolicyAccepted,
    );
  }

  /// Factory para criar request de personal trainer
  factory RegisterRequest.personal({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String birthDate,
    required String documentType,
    required String documentNumber,
    required String documentImageId,
    required String cref,
    required String crefImageId,
    List<String>? specialties,
    required bool isMinor,
    String? guardianName,
    String? guardianEmail,
    required bool guardianConsent,
    required bool termsAccepted,
    required bool privacyPolicyAccepted,
  }) {
    return RegisterRequest(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      userType: 'personal',
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
  }
}