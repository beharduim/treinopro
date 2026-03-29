// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      birthDate: json['birthDate'] as String,
      userType: json['userType'] as String,
      documentType: json['documentType'] as String,
      documentNumber: json['documentNumber'] as String,
      documentImageId: json['documentImageId'] as String,
      cref: json['cref'] as String?,
      crefImageId: json['crefImageId'] as String?,
      specialties: (json['specialties'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isMinor: json['isMinor'] as bool,
      guardianName: json['guardianName'] as String?,
      guardianEmail: json['guardianEmail'] as String?,
      guardianConsent: json['guardianConsent'] as bool,
      termsAccepted: json['termsAccepted'] as bool,
      privacyPolicyAccepted: json['privacyPolicyAccepted'] as bool,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'birthDate': instance.birthDate,
      'userType': instance.userType,
      'documentType': instance.documentType,
      'documentNumber': instance.documentNumber,
      'documentImageId': instance.documentImageId,
      'cref': instance.cref,
      'crefImageId': instance.crefImageId,
      'specialties': instance.specialties,
      'isMinor': instance.isMinor,
      'guardianName': instance.guardianName,
      'guardianEmail': instance.guardianEmail,
      'guardianConsent': instance.guardianConsent,
      'termsAccepted': instance.termsAccepted,
      'privacyPolicyAccepted': instance.privacyPolicyAccepted,
    };
