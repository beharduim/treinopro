import 'package:flutter_bloc/flutter_bloc.dart';
import 'personal_registration_event.dart';
import 'personal_registration_state.dart';

class PersonalRegistrationBloc
    extends Bloc<PersonalRegistrationEvent, PersonalRegistrationState> {
  PersonalRegistrationBloc() : super(const PersonalRegistrationStep()) {
    on<NextStep>(_onNextStep);
    on<PreviousStep>(_onPreviousStep);
    on<GoToStep>(_onGoToStep);
    on<UpdateCref>(_onUpdateCref);
    on<UpdatePersonalData>(_onUpdatePersonalData);
    on<UpdateDocuments>(_onUpdateDocuments);
    on<UpdateVerificationCode>(_onUpdateVerificationCode);
    on<SendVerificationCode>(_onSendVerificationCode);
    on<VerifyCode>(_onVerifyCode);
    on<UpdateModalities>(_onUpdateModalities);
    on<UpdatePassword>(_onUpdatePassword);
    on<CompleteRegistration>(_onCompleteRegistration);
  }

  void _onNextStep(NextStep event, Emitter<PersonalRegistrationState> emit) {
    if (state is PersonalRegistrationStep) {
      final currentState = state as PersonalRegistrationStep;
      final nextStep = currentState.currentStep + 1;

      if (nextStep <= 7) {
        emit(
          currentState.copyWith(
            currentStep: nextStep,
            isValid: _validateStep(nextStep, currentState),
          ),
        );
      }
    }
  }

  void _onPreviousStep(
    PreviousStep event,
    Emitter<PersonalRegistrationState> emit,
  ) {
    if (state is PersonalRegistrationStep) {
      final currentState = state as PersonalRegistrationStep;
      final previousStep = currentState.currentStep - 1;

      if (previousStep >= 1) {
        emit(
          currentState.copyWith(
            currentStep: previousStep,
            isValid: _validateStep(previousStep, currentState),
          ),
        );
      }
    }
  }

  void _onGoToStep(GoToStep event, Emitter<PersonalRegistrationState> emit) {
    if (state is PersonalRegistrationStep) {
      final currentState = state as PersonalRegistrationStep;

      if (event.step >= 1 && event.step <= 7) {
        emit(
          currentState.copyWith(
            currentStep: event.step,
            isValid: _validateStep(event.step, currentState),
          ),
        );
      }
    }
  }

  void _onUpdateCref(
    UpdateCref event,
    Emitter<PersonalRegistrationState> emit,
  ) {
    if (state is PersonalRegistrationStep) {
      final currentState = state as PersonalRegistrationStep;

      // Simulação de validação do CREF
      final isCrefValid = _isValidCref(event.cref);

      final updatedState = currentState.copyWith(
        cref: event.cref,
        crefPhotoPath: event.crefPhotoPath,
        isCrefValid: isCrefValid,
      );

      emit(
        updatedState.copyWith(
          isValid: _validateStep(currentState.currentStep, updatedState),
        ),
      );
    }
  }

  void _onUpdatePersonalData(
    UpdatePersonalData event,
    Emitter<PersonalRegistrationState> emit,
  ) {
    if (state is PersonalRegistrationStep) {
      final currentState = state as PersonalRegistrationStep;

      final updatedState = currentState.copyWith(
        firstName: event.firstName,
        lastName: event.lastName,
        birthDate: event.birthDate,
        email: event.email,
      );

      emit(
        updatedState.copyWith(
          isValid: _validateStep(currentState.currentStep, updatedState),
        ),
      );
    }
  }

  void _onUpdateDocuments(
    UpdateDocuments event,
    Emitter<PersonalRegistrationState> emit,
  ) {
    if (state is PersonalRegistrationStep) {
      final currentState = state as PersonalRegistrationStep;

      final updatedState = currentState.copyWith(
        document: event.document,
        documentType: event.documentType,
        documentPhotoPath: event.documentPhotoPath,
      );

      emit(
        updatedState.copyWith(
          isValid: _validateStep(currentState.currentStep, updatedState),
        ),
      );
    }
  }

  void _onUpdateVerificationCode(
    UpdateVerificationCode event,
    Emitter<PersonalRegistrationState> emit,
  ) {
    if (state is PersonalRegistrationStep) {
      final currentState = state as PersonalRegistrationStep;

      final updatedState = currentState.copyWith(verificationCode: event.code);

      emit(
        updatedState.copyWith(
          isValid: _validateStep(currentState.currentStep, updatedState),
        ),
      );
    }
  }

  void _onSendVerificationCode(
    SendVerificationCode event,
    Emitter<PersonalRegistrationState> emit,
  ) {
    if (state is PersonalRegistrationStep) {
      final currentState = state as PersonalRegistrationStep;

      emit(currentState.copyWith(isCodeSent: true, isCodeVerified: false));
    }
  }

  void _onVerifyCode(
    VerifyCode event,
    Emitter<PersonalRegistrationState> emit,
  ) {
    if (state is PersonalRegistrationStep) {
      final currentState = state as PersonalRegistrationStep;

      // Simulação de verificação (qualquer código de 6 dígitos)
      final isCodeValid = currentState.verificationCode.length == 6;

      emit(
        currentState.copyWith(
          isCodeVerified: isCodeValid,
          isValid: isCodeValid,
        ),
      );
    }
  }

  void _onUpdateModalities(
    UpdateModalities event,
    Emitter<PersonalRegistrationState> emit,
  ) {
    if (state is PersonalRegistrationStep) {
      final currentState = state as PersonalRegistrationStep;

      final updatedState = currentState.copyWith(
        selectedModalities: event.selectedModalities,
      );

      emit(
        updatedState.copyWith(
          isValid: _validateStep(currentState.currentStep, updatedState),
        ),
      );
    }
  }

  void _onUpdatePassword(
    UpdatePassword event,
    Emitter<PersonalRegistrationState> emit,
  ) {
    if (state is PersonalRegistrationStep) {
      final currentState = state as PersonalRegistrationStep;

      final updatedState = currentState.copyWith(
        password: event.password,
        confirmPassword: event.confirmPassword,
        acceptedTerms: event.acceptedTerms,
        acceptedPrivacy: event.acceptedPrivacy,
      );

      emit(
        updatedState.copyWith(
          isValid: _validateStep(currentState.currentStep, updatedState),
        ),
      );
    }
  }

  void _onCompleteRegistration(
    CompleteRegistration event,
    Emitter<PersonalRegistrationState> emit,
  ) {
    emit(PersonalRegistrationComplete());
  }

  /// Validação por etapa
  bool _validateStep(int step, PersonalRegistrationStep state) {
    switch (step) {
      case 1: // CREF
        return state.cref.isNotEmpty &&
            state.crefPhotoPath != null &&
            state.isCrefValid;

      case 2: // Dados pessoais
        return state.firstName.isNotEmpty &&
            state.lastName.isNotEmpty &&
            state.birthDate != null &&
            state.email.isNotEmpty &&
            _isValidEmail(state.email);

      case 3: // Documentos
        return state.document.isNotEmpty &&
            state.documentPhotoPath != null &&
            _isValidDocument(state.document, state.documentType);

      case 4: // Confirmação Email
        return state.email.isNotEmpty && _isValidEmail(state.email);

      case 5: // Verificação OTP
        return state.isCodeVerified;

      case 6: // Modalidades
        return state.selectedModalities.isNotEmpty;

      case 7: // Senha
        return state.password.isNotEmpty &&
            state.confirmPassword.isNotEmpty &&
            state.password == state.confirmPassword &&
            _isValidPassword(state.password) &&
            state.acceptedTerms &&
            state.acceptedPrivacy;

      default:
        return false;
    }
  }

  /// Validações auxiliares
  bool _isValidCref(String cref) {
    // Simulação: aceitar CREFs que não sejam licenciatura (terminados em -L)
    // e tenham pelo menos 6 caracteres
    return cref.length >= 6 && !cref.toUpperCase().contains('-L');
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidDocument(String document, String type) {
    String cleanDocument = document.replaceAll(RegExp(r'[^0-9]'), '');

    if (type == 'identity') {
      if (cleanDocument.length == 11) {
        if (document.contains('.') && document.contains('-')) {
          return _isValidCPF(document);
        } else {
          if (RegExp(r'^(\d)\1*$').hasMatch(cleanDocument)) {
            return false;
          }
          return true;
        }
      } else {
        return false;
      }
    } else if (type == 'cpf') {
      return _isValidCPF(document);
    } else {
      return _isValidRG(document);
    }
  }

  bool _isValidCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int remainder = sum % 11;
    int digit1 = remainder < 2 ? 0 : 11 - remainder;

    if (int.parse(cpf[9]) != digit1) return false;

    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    remainder = sum % 11;
    int digit2 = remainder < 2 ? 0 : 11 - remainder;

    return int.parse(cpf[10]) == digit2;
  }

  bool _isValidRG(String rg) {
    rg = rg.replaceAll(RegExp(r'[^0-9Xx]'), '');
    return rg.length >= 7 && rg.length <= 9;
  }

  bool _isValidPassword(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }
}
