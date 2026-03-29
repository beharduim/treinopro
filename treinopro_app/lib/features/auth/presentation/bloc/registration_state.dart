import 'package:equatable/equatable.dart';
import '../../data/models/upload_response.dart';

/// Wrapper para valores nullable que permite diferenciar entre "não fornecido" e "null"
class Nullable<T> {
  final T? value;
  const Nullable(this.value);
}

/// Tipo de usuário para o cadastro
enum UserType { student, personalTrainer }

/// Estados para o fluxo de cadastro (estudantes e personal trainers)
abstract class RegistrationState extends Equatable {
  const RegistrationState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class RegistrationInitial extends RegistrationState {}

/// Estado de loading
class RegistrationLoading extends RegistrationState {}

/// Estado com dados do cadastro
class RegistrationStep extends RegistrationState {
  final UserType userType;
  final int currentStep;
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final bool isMinor;
  final bool hasGuardianAuthorization;
  final String guardianName;
  final String guardianEmail;
  final bool isGuardianEmailSent;
  final String guardianOtpCode;
  final bool isGuardianOtpVerified;
  final bool isSendingGuardianEmail;
  final String? guardianEmailError;
  final bool isVerifyingGuardianOtp;
  final String? guardianOtpError;
  final String document;
  final String documentType;
  final String? documentPhotoPath;
  final UploadResponse? documentUpload;
  final String email;
  final bool isEmailValid;
  final bool isCodeSent;
  final String verificationCode;
  final bool isCodeVerified;
  final String password;
  final String confirmPassword;
  final bool acceptedTerms;
  final bool acceptedPrivacy;
  final bool isValid;

  // Campos específicos para Personal Trainer
  final String cref;
  final String? crefPhotoPath;
  final UploadResponse? crefUpload;
  final List<String> selectedModalities;
  final bool isCrefValidating;
  final bool isCrefValid;
  final String? crefValidationError;
  
  // Email verification fields
  final bool isSendingVerificationCode;
  final bool verificationCodeSent;
  final String? verificationCodeError;
  final bool isVerifyingCode;
  final bool isEmailVerified;
  final String? emailVerificationError;
  final bool isEmailChecking;
  final String? emailExistsError;
  final bool isDocumentChecking;
  final String? documentExistsError;

  const RegistrationStep({
    this.userType = UserType.student,
    required this.currentStep,
    this.firstName = '',
    this.lastName = '',
    this.birthDate,
    this.isMinor = false,
    this.hasGuardianAuthorization = false,
    this.guardianName = '',
    this.guardianEmail = '',
    this.isGuardianEmailSent = false,
    this.guardianOtpCode = '',
    this.isGuardianOtpVerified = false,
    this.isSendingGuardianEmail = false,
    this.guardianEmailError,
    this.isVerifyingGuardianOtp = false,
    this.guardianOtpError,
    this.document = '',
    this.documentType = 'cpf',
    this.documentPhotoPath,
    this.documentUpload,
    this.email = '',
    this.isEmailValid = false,
    this.isCodeSent = false,
    this.verificationCode = '',
    this.isCodeVerified = false,
    this.password = '',
    this.confirmPassword = '',
    this.acceptedTerms = false,
    this.acceptedPrivacy = false,
    this.isValid = false,
    // Personal Trainer fields
    this.cref = '',
    this.crefPhotoPath,
    this.crefUpload,
    this.selectedModalities = const [],
    this.isCrefValidating = false,
    this.isCrefValid = false,
    this.crefValidationError,
    this.isSendingVerificationCode = false,
    this.verificationCodeSent = false,
    this.verificationCodeError,
    this.isVerifyingCode = false,
    this.isEmailVerified = false,
    this.emailVerificationError,
    this.isEmailChecking = false,
    this.emailExistsError,
    this.isDocumentChecking = false,
    this.documentExistsError,
  });

  /// Retorna o número total de etapas baseado no tipo de usuário e idade
  int get totalSteps {
    if (userType == UserType.personalTrainer) {
      return 7; // CREF, Dados pessoais, Documentos, Email, Verificação, Modalidades, Senha
    }
    return isMinor ? 7 : 5; // Estudante maior: 5 (Dados, Docs, Email, Verificacao, Senha)
  }

  /// Cria uma cópia do estado com novos valores
  ///
  /// Para limpar campos nullable (erros, uploads, etc), use Nullable(null):
  /// ```dart
  /// state.copyWith(emailExistsError: Nullable(null))
  /// ```
  RegistrationStep copyWith({
    UserType? userType,
    int? currentStep,
    String? firstName,
    String? lastName,
    Nullable<DateTime>? birthDate,
    bool? isMinor,
    bool? hasGuardianAuthorization,
    String? guardianName,
    String? guardianEmail,
    bool? isGuardianEmailSent,
    String? guardianOtpCode,
    bool? isGuardianOtpVerified,
    bool? isSendingGuardianEmail,
    Nullable<String>? guardianEmailError,
    bool? isVerifyingGuardianOtp,
    Nullable<String>? guardianOtpError,
    String? document,
    String? documentType,
    Nullable<String>? documentPhotoPath,
    Nullable<UploadResponse>? documentUpload,
    String? email,
    bool? isEmailValid,
    bool? isCodeSent,
    String? verificationCode,
    bool? isCodeVerified,
    String? password,
    String? confirmPassword,
    bool? acceptedTerms,
    bool? acceptedPrivacy,
    bool? isValid,
    // Personal Trainer fields
    String? cref,
    Nullable<String>? crefPhotoPath,
    Nullable<UploadResponse>? crefUpload,
    List<String>? selectedModalities,
    bool? isCrefValidating,
    bool? isCrefValid,
    Nullable<String>? crefValidationError,
    bool? isSendingVerificationCode,
    bool? verificationCodeSent,
    Nullable<String>? verificationCodeError,
    bool? isVerifyingCode,
    bool? isEmailVerified,
    Nullable<String>? emailVerificationError,
    bool? isEmailChecking,
    Nullable<String>? emailExistsError,
    bool? isDocumentChecking,
    Nullable<String>? documentExistsError,
  }) {
    return RegistrationStep(
      userType: userType ?? this.userType,
      currentStep: currentStep ?? this.currentStep,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate != null ? birthDate.value : this.birthDate,
      isMinor: isMinor ?? this.isMinor,
      hasGuardianAuthorization:
          hasGuardianAuthorization ?? this.hasGuardianAuthorization,
      guardianName: guardianName ?? this.guardianName,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      isGuardianEmailSent: isGuardianEmailSent ?? this.isGuardianEmailSent,
      guardianOtpCode: guardianOtpCode ?? this.guardianOtpCode,
      isGuardianOtpVerified: isGuardianOtpVerified ?? this.isGuardianOtpVerified,
      isSendingGuardianEmail: isSendingGuardianEmail ?? this.isSendingGuardianEmail,
      guardianEmailError: guardianEmailError != null ? guardianEmailError.value : this.guardianEmailError,
      isVerifyingGuardianOtp: isVerifyingGuardianOtp ?? this.isVerifyingGuardianOtp,
      guardianOtpError: guardianOtpError != null ? guardianOtpError.value : this.guardianOtpError,
      document: document ?? this.document,
      documentType: documentType ?? this.documentType,
      documentPhotoPath: documentPhotoPath != null ? documentPhotoPath.value : this.documentPhotoPath,
      documentUpload: documentUpload != null ? documentUpload.value : this.documentUpload,
      email: email ?? this.email,
      isEmailValid: isEmailValid ?? this.isEmailValid,
      isCodeSent: isCodeSent ?? this.isCodeSent,
      verificationCode: verificationCode ?? this.verificationCode,
      isCodeVerified: isCodeVerified ?? this.isCodeVerified,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      acceptedPrivacy: acceptedPrivacy ?? this.acceptedPrivacy,
      isValid: isValid ?? this.isValid,
      // Personal Trainer fields
      cref: cref ?? this.cref,
      crefPhotoPath: crefPhotoPath != null ? crefPhotoPath.value : this.crefPhotoPath,
      crefUpload: crefUpload != null ? crefUpload.value : this.crefUpload,
      selectedModalities: selectedModalities ?? this.selectedModalities,
      isCrefValidating: isCrefValidating ?? this.isCrefValidating,
      isCrefValid: isCrefValid ?? this.isCrefValid,
      crefValidationError: crefValidationError != null ? crefValidationError.value : this.crefValidationError,
      isSendingVerificationCode: isSendingVerificationCode ?? this.isSendingVerificationCode,
      verificationCodeSent: verificationCodeSent ?? this.verificationCodeSent,
      verificationCodeError: verificationCodeError != null ? verificationCodeError.value : this.verificationCodeError,
      isVerifyingCode: isVerifyingCode ?? this.isVerifyingCode,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      emailVerificationError: emailVerificationError != null ? emailVerificationError.value : this.emailVerificationError,
      isEmailChecking: isEmailChecking ?? this.isEmailChecking,
      emailExistsError: emailExistsError != null ? emailExistsError.value : this.emailExistsError,
      isDocumentChecking: isDocumentChecking ?? this.isDocumentChecking,
      documentExistsError: documentExistsError != null ? documentExistsError.value : this.documentExistsError,
    );
  }

  @override
  List<Object?> get props => [
    userType,
    currentStep,
    firstName,
    lastName,
    birthDate,
    isMinor,
    hasGuardianAuthorization,
    guardianName,
    guardianEmail,
    document,
    documentType,
    documentPhotoPath,
    documentUpload,
    email,
    isEmailValid,
    isCodeSent,
    verificationCode,
    isCodeVerified,
    password,
    confirmPassword,
    acceptedTerms,
    acceptedPrivacy,
    isValid,
    // Personal Trainer fields
    cref,
    crefPhotoPath,
    crefUpload,
    selectedModalities,
    isCrefValidating,
    isCrefValid,
    crefValidationError,
    isSendingVerificationCode,
    verificationCodeSent,
    verificationCodeError,
    isVerifyingCode,
    isEmailVerified,
    emailVerificationError,
    isEmailChecking,
    emailExistsError,
    isDocumentChecking,
    documentExistsError,
  ];
}

/// Estado quando código de verificação foi enviado
class VerificationCodeSent extends RegistrationState {
  final String email;
  final DateTime sentAt;

  const VerificationCodeSent({required this.email, required this.sentAt});

  @override
  List<Object?> get props => [email, sentAt];
}

/// Estado de sucesso no cadastro
class RegistrationSuccess extends RegistrationState {
  final RegistrationStep registrationData;

  const RegistrationSuccess(this.registrationData);

  @override
  List<Object?> get props => [registrationData];
}

/// Estado de erro
class RegistrationError extends RegistrationState {
  final String message;

  const RegistrationError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado para navegar de volta para seleção de perfil
class NavigateBackToProfileSelection extends RegistrationState {}
