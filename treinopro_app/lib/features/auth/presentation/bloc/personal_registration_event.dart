import 'package:equatable/equatable.dart';

abstract class PersonalRegistrationEvent extends Equatable {
  const PersonalRegistrationEvent();

  @override
  List<Object?> get props => [];
}

/// Navegar entre etapas
class NextStep extends PersonalRegistrationEvent {
  const NextStep();
}

class PreviousStep extends PersonalRegistrationEvent {
  const PreviousStep();
}

class GoToStep extends PersonalRegistrationEvent {
  final int step;

  const GoToStep(this.step);

  @override
  List<Object> get props => [step];
}

/// Eventos específicos do Personal

/// 1. CREF
class UpdateCref extends PersonalRegistrationEvent {
  final String cref;
  final String? crefPhotoPath;

  const UpdateCref({required this.cref, this.crefPhotoPath});

  @override
  List<Object?> get props => [cref, crefPhotoPath];
}

/// 2. Dados pessoais
class UpdatePersonalData extends PersonalRegistrationEvent {
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final String email;

  const UpdatePersonalData({
    required this.firstName,
    required this.lastName,
    this.birthDate,
    required this.email,
  });

  @override
  List<Object?> get props => [firstName, lastName, birthDate, email];
}

/// 3. Documentos
class UpdateDocuments extends PersonalRegistrationEvent {
  final String document;
  final String documentType;
  final String? documentPhotoPath;

  const UpdateDocuments({
    required this.document,
    required this.documentType,
    this.documentPhotoPath,
  });

  @override
  List<Object?> get props => [document, documentType, documentPhotoPath];
}

/// 4. Email (reutiliza UpdatePersonalData para email)

/// 5. Verificação
class UpdateVerificationCode extends PersonalRegistrationEvent {
  final String code;

  const UpdateVerificationCode(this.code);

  @override
  List<Object> get props => [code];
}

class SendVerificationCode extends PersonalRegistrationEvent {
  const SendVerificationCode();
}

class VerifyCode extends PersonalRegistrationEvent {
  const VerifyCode();
}

/// 6. Modalidades
class UpdateModalities extends PersonalRegistrationEvent {
  final List<String> selectedModalities;

  const UpdateModalities(this.selectedModalities);

  @override
  List<Object> get props => [selectedModalities];
}

/// 7. Senha
class UpdatePassword extends PersonalRegistrationEvent {
  final String password;
  final String confirmPassword;
  final bool acceptedTerms;
  final bool acceptedPrivacy;

  const UpdatePassword({
    required this.password,
    required this.confirmPassword,
    required this.acceptedTerms,
    required this.acceptedPrivacy,
  });

  @override
  List<Object> get props => [
    password,
    confirmPassword,
    acceptedTerms,
    acceptedPrivacy,
  ];
}

/// Finalizar cadastro
class CompleteRegistration extends PersonalRegistrationEvent {
  const CompleteRegistration();
}
