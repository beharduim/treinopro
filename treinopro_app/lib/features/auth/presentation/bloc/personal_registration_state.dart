import 'package:equatable/equatable.dart';

abstract class PersonalRegistrationState extends Equatable {
  const PersonalRegistrationState();

  @override
  List<Object?> get props => [];
}

class PersonalRegistrationInitial extends PersonalRegistrationState {}

class PersonalRegistrationLoading extends PersonalRegistrationState {}

class PersonalRegistrationError extends PersonalRegistrationState {
  final String message;

  const PersonalRegistrationError(this.message);

  @override
  List<Object> get props => [message];
}

class PersonalRegistrationComplete extends PersonalRegistrationState {}

class PersonalRegistrationStep extends PersonalRegistrationState {
  final int currentStep;
  final bool isValid;

  // Dados do CREF
  final String cref;
  final String? crefPhotoPath;
  final bool isCrefValid;

  // Dados pessoais
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final String email;

  // Documentos
  final String document;
  final String documentType;
  final String? documentPhotoPath;

  // Verificação
  final String verificationCode;
  final bool isCodeSent;
  final bool isCodeVerified;

  // Modalidades
  final List<String> selectedModalities;
  final List<String> availableModalities;

  // Senha
  final String password;
  final String confirmPassword;
  final bool acceptedTerms;
  final bool acceptedPrivacy;

  const PersonalRegistrationStep({
    this.currentStep = 1,
    this.isValid = false,
    this.cref = '',
    this.crefPhotoPath,
    this.isCrefValid = false,
    this.firstName = '',
    this.lastName = '',
    this.birthDate,
    this.email = '',
    this.document = '',
    this.documentType = 'identity',
    this.documentPhotoPath,
    this.verificationCode = '',
    this.isCodeSent = false,
    this.isCodeVerified = false,
    this.selectedModalities = const [],
    this.availableModalities = const [
      'Musculação',
      'Funcional',
      'Cardio',
      'Crossfit',
      'Pilates',
    ],
    this.password = '',
    this.confirmPassword = '',
    this.acceptedTerms = false,
    this.acceptedPrivacy = false,
  });

  PersonalRegistrationStep copyWith({
    int? currentStep,
    bool? isValid,
    String? cref,
    String? crefPhotoPath,
    bool? isCrefValid,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? email,
    String? document,
    String? documentType,
    String? documentPhotoPath,
    String? verificationCode,
    bool? isCodeSent,
    bool? isCodeVerified,
    List<String>? selectedModalities,
    List<String>? availableModalities,
    String? password,
    String? confirmPassword,
    bool? acceptedTerms,
    bool? acceptedPrivacy,
  }) {
    return PersonalRegistrationStep(
      currentStep: currentStep ?? this.currentStep,
      isValid: isValid ?? this.isValid,
      cref: cref ?? this.cref,
      crefPhotoPath: crefPhotoPath ?? this.crefPhotoPath,
      isCrefValid: isCrefValid ?? this.isCrefValid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      email: email ?? this.email,
      document: document ?? this.document,
      documentType: documentType ?? this.documentType,
      documentPhotoPath: documentPhotoPath ?? this.documentPhotoPath,
      verificationCode: verificationCode ?? this.verificationCode,
      isCodeSent: isCodeSent ?? this.isCodeSent,
      isCodeVerified: isCodeVerified ?? this.isCodeVerified,
      selectedModalities: selectedModalities ?? this.selectedModalities,
      availableModalities: availableModalities ?? this.availableModalities,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      acceptedPrivacy: acceptedPrivacy ?? this.acceptedPrivacy,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    isValid,
    cref,
    crefPhotoPath,
    isCrefValid,
    firstName,
    lastName,
    birthDate,
    email,
    document,
    documentType,
    documentPhotoPath,
    verificationCode,
    isCodeSent,
    isCodeVerified,
    selectedModalities,
    availableModalities,
    password,
    confirmPassword,
    acceptedTerms,
    acceptedPrivacy,
  ];
}
