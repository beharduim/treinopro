import 'package:equatable/equatable.dart';
import '../../data/models/upload_response.dart';

/// Eventos para o fluxo de cadastro (estudantes e personal trainers)
abstract class RegistrationEvent extends Equatable {
  const RegistrationEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para inicializar o fluxo de estudante
class InitializeStudentFlow extends RegistrationEvent {
  const InitializeStudentFlow();
}

/// Evento para avançar para a próxima etapa
class NextStep extends RegistrationEvent {
  const NextStep();
}

/// Evento para voltar para a etapa anterior
class PreviousStep extends RegistrationEvent {
  const PreviousStep();
}

/// Evento para ir para uma etapa específica
class GoToStep extends RegistrationEvent {
  final int step;

  const GoToStep(this.step);

  @override
  List<Object?> get props => [step];
}

/// Evento para atualizar dados pessoais
class UpdatePersonalData extends RegistrationEvent {
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final bool isMinor;
  final bool hasGuardianAuthorization;

  const UpdatePersonalData({
    required this.firstName,
    required this.lastName,
    this.birthDate,
    required this.isMinor,
    required this.hasGuardianAuthorization,
  });

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    birthDate,
    isMinor,
    hasGuardianAuthorization,
  ];
}

/// Evento para atualizar dados pessoais e avançar para o próximo passo
class UpdatePersonalDataAndNext extends RegistrationEvent {
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final bool isMinor;
  final bool hasGuardianAuthorization;

  const UpdatePersonalDataAndNext({
    required this.firstName,
    required this.lastName,
    this.birthDate,
    required this.isMinor,
    required this.hasGuardianAuthorization,
  });

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    birthDate,
    isMinor,
    hasGuardianAuthorization,
  ];
}

/// Evento para atualizar dados do responsável
class UpdateGuardianData extends RegistrationEvent {
  final String guardianName;
  final String guardianEmail;

  const UpdateGuardianData({
    required this.guardianName,
    required this.guardianEmail,
  });

  @override
  List<Object?> get props => [guardianName, guardianEmail];
}

/// Evento para enviar email de autorização para o responsável
class SendGuardianAuthorizationEmail extends RegistrationEvent {
  final String guardianName;
  final String guardianEmail;
  final String studentName;

  const SendGuardianAuthorizationEmail({
    required this.guardianName,
    required this.guardianEmail,
    required this.studentName,
  });

  @override
  List<Object?> get props => [guardianName, guardianEmail, studentName];
}

/// Evento para verificar OTP do responsável
class VerifyGuardianOtp extends RegistrationEvent {
  final String otpCode;

  const VerifyGuardianOtp(this.otpCode);

  @override
  List<Object?> get props => [otpCode];
}

/// Evento para limpar erro do OTP do responsável
class ClearGuardianOtpError extends RegistrationEvent {
  const ClearGuardianOtpError();
}

/// Evento para atualizar documentos
class UpdateDocuments extends RegistrationEvent {
  final String document;
  final String documentType; // 'rg' ou 'cpf'
  final String? documentPhotoPath;
  final UploadResponse? documentUpload;

  const UpdateDocuments({
    required this.document,
    required this.documentType,
    this.documentPhotoPath,
    this.documentUpload,
  });

  @override
  List<Object?> get props => [document, documentType, documentPhotoPath, documentUpload];
}

/// Evento para atualizar email
class UpdateEmail extends RegistrationEvent {
  final String email;

  const UpdateEmail(this.email);

  @override
  List<Object?> get props => [email];
}

/// Evento para validar se o email já existe
class ValidateEmail extends RegistrationEvent {
  final String email;

  const ValidateEmail(this.email);

  @override
  List<Object?> get props => [email];
}

/// Evento para verificar se documento já existe
class CheckDocument extends RegistrationEvent {
  final String documentType;
  final String documentNumber;

  const CheckDocument(this.documentType, this.documentNumber);

  @override
  List<Object?> get props => [documentType, documentNumber];
}

/// Evento para enviar código de verificação
class SendVerificationCode extends RegistrationEvent {
  final String email;
  
  const SendVerificationCode(this.email);
  
  @override
  List<Object?> get props => [email];
}

/// Reenvio do código sem avançar etapa do cadastro
class ResendVerificationCode extends RegistrationEvent {
  final String email;

  const ResendVerificationCode(this.email);

  @override
  List<Object?> get props => [email];
}

/// Evento para verificar código
class VerifyCode extends RegistrationEvent {
  final String email;
  final String code;

  const VerifyCode(this.email, this.code);

  @override
  List<Object?> get props => [email, code];
}

/// Evento para atualizar senha
class UpdatePassword extends RegistrationEvent {
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
  List<Object?> get props => [
    password,
    confirmPassword,
    acceptedTerms,
    acceptedPrivacy,
  ];
}

/// Evento para finalizar cadastro
class CompleteRegistration extends RegistrationEvent {
  const CompleteRegistration();
}

/// Evento para navegar de volta
class NavigateBack extends RegistrationEvent {
  const NavigateBack();
}

// ===== EVENTOS ESPECÍFICOS PARA PERSONAL TRAINER =====

/// Evento para atualizar CREF
class UpdateCref extends RegistrationEvent {
  final String cref;
  final String? crefPhotoPath;
  final UploadResponse? crefUpload;

  const UpdateCref({
    required this.cref, 
    this.crefPhotoPath,
    this.crefUpload,
  });

  @override
  List<Object?> get props => [cref, crefPhotoPath, crefUpload];
}

/// Evento para atualizar modalidades
class UpdateModalities extends RegistrationEvent {
  final List<String> selectedModalities;

  const UpdateModalities(this.selectedModalities);

  @override
  List<Object> get props => [selectedModalities];
}

/// Evento para inicializar fluxo de personal trainer
class InitializePersonalTrainerFlow extends RegistrationEvent {
  const InitializePersonalTrainerFlow();
}

/// Evento para validar CREF
class ValidateCref extends RegistrationEvent {
  final String cref;

  const ValidateCref(this.cref);

  @override
  List<Object?> get props => [cref];
}

