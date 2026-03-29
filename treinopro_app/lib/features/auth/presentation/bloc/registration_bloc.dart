import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/registration_steps_helper.dart';
import 'registration_event.dart';
import 'registration_state.dart';
import '../../domain/usecases/student_registration_usecases.dart';
import '../../domain/usecases/personal_registration_usecases.dart';
import '../../domain/usecases/validate_cref_usecase.dart';
import '../../domain/usecases/send_verification_code_usecase.dart';
import '../../domain/usecases/verify_code_usecase.dart';
import '../../domain/usecases/validate_email_usecase.dart';
import '../../domain/usecases/check_document_usecase.dart';
import '../../data/services/guardian_authorization_service.dart';

/// BLoC para gerenciar o fluxo de cadastro (estudantes e personal trainers)
class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  bool _isVerifying = false;
  int _emailValidationToken = 0; // Token para evitar stale responses
  int _documentValidationToken = 0; // Token para evitar stale responses de documento
  final StudentRegistrationUseCase _studentRegistrationUseCase;
  final PersonalRegistrationUseCase _personalRegistrationUseCase;
  final ValidateCrefUseCase _validateCrefUseCase;
  final SendVerificationCodeUseCase _sendVerificationCodeUseCase;
  final VerifyCodeUseCase _verifyCodeUseCase;
  final ValidateEmailUseCase _validateEmailUseCase;
  final CheckDocumentUseCase _checkDocumentUseCase;
  final GuardianAuthorizationService _guardianAuthorizationService;

  RegistrationBloc({
    required StudentRegistrationUseCase studentRegistrationUseCase,
    required PersonalRegistrationUseCase personalRegistrationUseCase,
    required ValidateCrefUseCase validateCrefUseCase,
    required SendVerificationCodeUseCase sendVerificationCodeUseCase,
    required VerifyCodeUseCase verifyCodeUseCase,
    required ValidateEmailUseCase validateEmailUseCase,
    required CheckDocumentUseCase checkDocumentUseCase,
    required GuardianAuthorizationService guardianAuthorizationService,
  }) : _studentRegistrationUseCase = studentRegistrationUseCase,
       _personalRegistrationUseCase = personalRegistrationUseCase,
       _validateCrefUseCase = validateCrefUseCase,
       _sendVerificationCodeUseCase = sendVerificationCodeUseCase,
       _verifyCodeUseCase = verifyCodeUseCase,
       _validateEmailUseCase = validateEmailUseCase,
       _checkDocumentUseCase = checkDocumentUseCase,
       _guardianAuthorizationService = guardianAuthorizationService,
       super(RegistrationInitial()) {
    on<NextStep>(_onNextStep);
    on<PreviousStep>(_onPreviousStep);
    on<GoToStep>(_onGoToStep);
    on<UpdatePersonalData>(_onUpdatePersonalData);
    on<UpdatePersonalDataAndNext>(_onUpdatePersonalDataAndNext);
    on<UpdateGuardianData>(_onUpdateGuardianData);
    on<SendGuardianAuthorizationEmail>(_onSendGuardianAuthorizationEmail);
    on<VerifyGuardianOtp>(_onVerifyGuardianOtp);
    on<ClearGuardianOtpError>(_onClearGuardianOtpError);
    on<UpdateDocuments>(_onUpdateDocuments);
    on<UpdateEmail>(_onUpdateEmail);
    on<ValidateEmail>(_onValidateEmail);
    on<CheckDocument>(_onCheckDocument);
    on<SendVerificationCode>(_onSendVerificationCode);
    on<VerifyCode>(_onVerifyCode);
    on<UpdatePassword>(_onUpdatePassword);
    on<CompleteRegistration>(_onCompleteRegistration);
    on<NavigateBack>(_onNavigateBack);
    // Personal Trainer specific events
    on<UpdateCref>(_onUpdateCref);
    on<ValidateCref>(_onValidateCref);
    on<UpdateModalities>(_onUpdateModalities);
    on<InitializePersonalTrainerFlow>(_onInitializePersonalTrainerFlow);
    on<InitializeStudentFlow>(_onInitializeStudentFlow);
  }

  void _onInitializePersonalTrainerFlow(
    InitializePersonalTrainerFlow event,
    Emitter<RegistrationState> emit,
  ) {
    emit(RegistrationStep(currentStep: 1, userType: UserType.personalTrainer));
  }

  void _onInitializeStudentFlow(
    InitializeStudentFlow event,
    Emitter<RegistrationState> emit,
  ) {
    emit(RegistrationStep(currentStep: 1, userType: UserType.student));
  }

  void _onNextStep(NextStep event, Emitter<RegistrationState> emit) {
    final currentState = state;
    print(
      'RegistrationBloc: NextStep chamado. Estado atual: ${currentState.runtimeType}',
    );

    if (currentState is RegistrationStep) {
      print(
        'RegistrationBloc: currentStep=${currentState.currentStep}, userType=${currentState.userType}',
      );
      print(
        'RegistrationBloc: isCodeSent=${currentState.isCodeSent}, email=${currentState.email}, isEmailVerified=${currentState.isEmailVerified}',
      );

      // Determinar próximo passo utilizando o helper
      final stepInfo = RegistrationStepsHelper.getStepInfo(
        currentState.currentStep + 1,
        currentState.userType,
        currentState.isMinor,
      );

      print('RegistrationBloc: stepInfo para step ${currentState.currentStep + 1}: $stepInfo');

      final nextStep = stepInfo.shouldShow
          ? currentState.currentStep + 1
          : currentState.currentStep + 2; // Pular para o próximo válido

      print('RegistrationBloc: próximo step será: $nextStep');

      // Emitir novo estado com o próximo step
      final nextStepState = currentState.copyWith(currentStep: nextStep);
      final isValid = _validateStep(nextStep, nextStepState);
      emit(nextStepState.copyWith(isValid: isValid));

      print(
        'RegistrationBloc: Avançado para step $nextStep com validação: $isValid',
      );
    } else {
      print(
        'RegistrationBloc: Não foi possível avançar, estado não é RegistrationStep',
      );
    }
  }

  void _onPreviousStep(PreviousStep event, Emitter<RegistrationState> emit) {
    final currentState = state;
    if (currentState is RegistrationStep) {
      // Usar o helper para determinar o step anterior válido
      final previousStep = RegistrationStepsHelper.getPreviousValidStep(
        currentState.currentStep,
        currentState.userType,
        currentState.isMinor,
      );

      print('RegistrationBloc: Voltando para step $previousStep');

      if (previousStep > 0) {
        final newState = currentState.copyWith(currentStep: previousStep);
        emit(newState.copyWith(isValid: _validateStep(previousStep, newState)));
      }
    }
  }

  void _onGoToStep(GoToStep event, Emitter<RegistrationState> emit) {
    final currentState = state;
    if (currentState is RegistrationStep) {
      final newState = currentState.copyWith(currentStep: event.step);
      emit(newState.copyWith(isValid: _validateStep(event.step, newState)));
    } else {
      emit(RegistrationStep(currentStep: event.step));
    }
  }

  void _onUpdatePersonalData(
    UpdatePersonalData event,
    Emitter<RegistrationState> emit,
  ) {
    final currentState = state;

    // Calcula a idade baseada na data de nascimento
    bool isMinor = false;
    if (event.birthDate != null) {
      final now = DateTime.now();
      final age = now.year - event.birthDate!.year;
      // Verifica se ainda não fez aniversário este ano
      if (now.month < event.birthDate!.month ||
          (now.month == event.birthDate!.month &&
              now.day < event.birthDate!.day)) {
        isMinor = (age - 1) < 18;
      } else {
        isMinor = age < 18;
      }
    }

    if (currentState is RegistrationStep) {
      emit(
        currentState.copyWith(
          firstName: event.firstName,
          lastName: event.lastName,
          birthDate: Nullable(event.birthDate),
          isMinor: isMinor,
          hasGuardianAuthorization: event.hasGuardianAuthorization,
          isValid: _validateStep(
            currentState.currentStep,
            currentState.copyWith(
              firstName: event.firstName,
              lastName: event.lastName,
              birthDate: Nullable(event.birthDate),
              isMinor: isMinor,
              hasGuardianAuthorization: event.hasGuardianAuthorization,
            ),
          ),
        ),
      );
    } else {
      emit(
        RegistrationStep(
          currentStep: 1,
          firstName: event.firstName,
          lastName: event.lastName,
          birthDate: event.birthDate,
          isMinor: isMinor,
          hasGuardianAuthorization: event.hasGuardianAuthorization,
          isValid:
              event.firstName.isNotEmpty &&
              event.lastName.isNotEmpty &&
              event.birthDate != null &&
              (!isMinor || event.hasGuardianAuthorization),
        ),
      );
    }
  }

  void _onUpdatePersonalDataAndNext(
    UpdatePersonalDataAndNext event,
    Emitter<RegistrationState> emit,
  ) {
    _onUpdatePersonalData(
      UpdatePersonalData(
        firstName: event.firstName,
        lastName: event.lastName,
        birthDate: event.birthDate,
        isMinor: event.isMinor,
        hasGuardianAuthorization: event.hasGuardianAuthorization,
      ),
      emit,
    );
    _onNextStep(const NextStep(), emit);
  }

  void _onUpdateGuardianData(
    UpdateGuardianData event,
    Emitter<RegistrationState> emit,
  ) {
    final currentState = state;
    if (currentState is RegistrationStep) {
      emit(
        currentState.copyWith(
          guardianName: event.guardianName,
          guardianEmail: event.guardianEmail,
          isValid: _validateStep(
            currentState.currentStep,
            currentState.copyWith(
              guardianName: event.guardianName,
              guardianEmail: event.guardianEmail,
            ),
          ),
        ),
      );
    }
  }

  void _onUpdateDocuments(
    UpdateDocuments event,
    Emitter<RegistrationState> emit,
  ) {
    final currentState = state;
    if (currentState is RegistrationStep) {
      // Incrementar token para invalidar validações pendentes se documento mudou
      if (event.document != currentState.document ||
          event.documentType != currentState.documentType) {
        _documentValidationToken++;
      }

      emit(
        currentState.copyWith(
          document: event.document,
          documentType: event.documentType,
          documentPhotoPath: event.documentPhotoPath != null
              ? Nullable(event.documentPhotoPath)
              : null,
          documentUpload: event.documentUpload != null
              ? Nullable(event.documentUpload)
              : null,
          // Limpar erro de documento duplicado quando documento muda
          documentExistsError: Nullable(null),
          isValid: _validateStep(
            currentState.currentStep,
            currentState.copyWith(
              document: event.document,
              documentType: event.documentType,
              documentPhotoPath: event.documentPhotoPath != null
                  ? Nullable(event.documentPhotoPath)
                  : null,
              documentUpload: event.documentUpload != null
                  ? Nullable(event.documentUpload)
                  : null,
            ),
          ),
        ),
      );
    }
  }

  void _onUpdateEmail(UpdateEmail event, Emitter<RegistrationState> emit) {
    final currentState = state;
    if (currentState is RegistrationStep) {
      // Normalizar email (trim + lowercase)
      final normalizedEmail = event.email.trim().toLowerCase();

      // Verificar se o email realmente mudou
      if (normalizedEmail == currentState.email) {
        print('📧 [UPDATE_EMAIL] Email não mudou, mantendo estado atual');
        return; // Email não mudou, não fazer nada
      }

      print('📧 [UPDATE_EMAIL] Email mudou de "${currentState.email}" para "$normalizedEmail"');

      // Incrementar token de validação para invalidar respostas antigas
      _emailValidationToken++;

      // ✅ Limpar erros e estados de envio imediatamente ao digitar
      emit(
        currentState.copyWith(
          email: normalizedEmail,
          isEmailValid: _isValidEmail(normalizedEmail),
          emailExistsError: Nullable(null),
          isCodeSent: false,
          verificationCodeSent: false,
          isEmailVerified: false, // Resetar verificação apenas se email mudou
          emailVerificationError: Nullable(null),
          verificationCodeError: Nullable(null),
          isValid: false, // Forçar re-validação do botão
        ),
      );
    }
  }

  void _onValidateEmail(ValidateEmail event, Emitter<RegistrationState> emit) async {
    final currentState = state;
    if (currentState is! RegistrationStep) return;

    // Normalizar email
    final normalizedEmail = event.email.trim().toLowerCase();
    if (!_isValidEmail(normalizedEmail)) return;

    // Capturar token atual para verificar se resposta ainda é válida
    final validationToken = _emailValidationToken;

    emit(currentState.copyWith(
      isEmailChecking: true,
      emailExistsError: Nullable(null),
    ));

    try {
      final exists = await _validateEmailUseCase(normalizedEmail);

      // Verificar se resposta ainda é válida (email não mudou durante validação)
      if (_emailValidationToken != validationToken) {
        print('📧 [REGISTRATION_BLOC] Descartando resposta de validação atrasada para email $normalizedEmail');
        return; // Descartar resposta atrasada
      }

      // Usar estado mais recente após await
      final latestState = state;
      if (latestState is! RegistrationStep) return;

      if (exists) {
        emit(latestState.copyWith(
          isEmailChecking: false,
          emailExistsError: Nullable('Este e-mail já está cadastrado.'),
          isValid: false,
        ));
      } else {
        emit(latestState.copyWith(
          isEmailChecking: false,
          emailExistsError: Nullable(null),
        ));
      }
    } catch (e) {
      // Verificar se resposta ainda é válida
      if (_emailValidationToken != validationToken) {
        return; // Descartar resposta atrasada
      }

      final latestState = state;
      if (latestState is! RegistrationStep) return;

      emit(latestState.copyWith(
        isEmailChecking: false,
        emailExistsError: Nullable('Erro ao verificar email: ${e.toString()}'),
      ));
      print('Error checking email existence: $e');
    }
  }

  void _onCheckDocument(CheckDocument event, Emitter<RegistrationState> emit) async {
    final currentState = state;
    if (currentState is! RegistrationStep) return;

    // Normalizar número do documento (remover caracteres especiais)
    final normalizedDocNumber = event.documentNumber.replaceAll(RegExp(r'\D'), '');
    if (normalizedDocNumber.isEmpty) return;

    // Capturar token atual para verificar se resposta ainda é válida
    final validationToken = ++_documentValidationToken;

    emit(currentState.copyWith(
      isDocumentChecking: true,
      documentExistsError: Nullable(null),
    ));

    try {
      final exists = await _checkDocumentUseCase(
        event.documentType,
        normalizedDocNumber,
      );

      // Verificar se resposta ainda é válida (documento não mudou durante validação)
      if (_documentValidationToken != validationToken) {
        print('📄 [REGISTRATION_BLOC] Descartando resposta de validação atrasada para documento $normalizedDocNumber');
        return; // Descartar resposta atrasada
      }

      // Usar estado mais recente após await
      final latestState = state;
      if (latestState is! RegistrationStep) return;

      if (exists) {
        emit(latestState.copyWith(
          isDocumentChecking: false,
          documentExistsError: Nullable('Este documento já está cadastrado. Cada CPF/RG/CNH pode ser usado apenas uma vez.'),
          isValid: false,
        ));
      } else {
        emit(latestState.copyWith(
          isDocumentChecking: false,
          documentExistsError: Nullable(null),
        ));
      }
    } catch (e) {
      // Verificar se resposta ainda é válida
      if (_documentValidationToken != validationToken) {
        return; // Descartar resposta atrasada
      }

      final latestState = state;
      if (latestState is! RegistrationStep) return;

      emit(latestState.copyWith(
        isDocumentChecking: false,
        documentExistsError: Nullable('Erro ao verificar documento: ${e.toString()}'),
      ));
      print('Error checking document existence: $e');
    }
  }

  void _onSendVerificationCode(
    SendVerificationCode event,
    Emitter<RegistrationState> emit,
  ) async {
    if (state is! RegistrationStep) return;

    final currentState = state as RegistrationStep;

    // Normalizar email
    final normalizedEmail = event.email.trim().toLowerCase();

    emit(currentState.copyWith(
      isSendingVerificationCode: true,
      verificationCodeError: Nullable(null),
    ));

    try {
      // 1. Verificar se o email já existe antes de enviar o código
      final exists = await _validateEmailUseCase(normalizedEmail);

      // Usar estado mais recente após await
      final latestState = state;
      if (latestState is! RegistrationStep) return;

      if (exists) {
        emit(latestState.copyWith(
          isSendingVerificationCode: false,
          emailExistsError: Nullable('Este e-mail já está cadastrado.'),
          isValid: false,
        ));
        return;
      }

      // 2. Se não existe, enviar o código
      await _sendVerificationCodeUseCase(normalizedEmail);

      // Usar estado mais recente após segundo await
      final finalState = state;
      if (finalState is! RegistrationStep) return;

      final updatedState = finalState.copyWith(
        isSendingVerificationCode: false,
        verificationCodeSent: true,
        verificationCodeError: Nullable(null),
        isCodeSent: true,
      );

      print('RegistrationBloc: Código enviado com sucesso, isCodeSent=${updatedState.isCodeSent}');
      emit(updatedState);

      // Avançar automaticamente para o próximo passo (verificação)
      add(const NextStep());
    } catch (e) {
      final errorMessage = e.toString();
      String? emailError;

      if (errorMessage.contains('email já está em uso') ||
          errorMessage.contains('Email já está em uso') ||
          errorMessage.contains('já está cadastrado')) {
        emailError = 'Este e-mail já está cadastrado.';
      }

      // Usar estado mais recente
      final latestState = state;
      if (latestState is! RegistrationStep) return;

      emit(latestState.copyWith(
        isSendingVerificationCode: false,
        verificationCodeSent: false,
        verificationCodeError: emailError == null ? Nullable(errorMessage) : Nullable(null),
        emailExistsError: emailError != null ? Nullable(emailError) : Nullable(null),
      ));
    }
  }

  void _onVerifyCode(VerifyCode event, Emitter<RegistrationState> emit) async {
    if (_isVerifying || state is! RegistrationStep) return;

    final currentState = state as RegistrationStep;
    _isVerifying = true;

    // Normalizar email
    final normalizedEmail = event.email.trim().toLowerCase();

    emit(currentState.copyWith(
      isVerifyingCode: true,
      emailVerificationError: Nullable(null),
    ));

    try {
      print('RegistrationBloc: Verificando código ${event.code} para email $normalizedEmail');

      final result = await _verifyCodeUseCase(normalizedEmail, event.code);

      // Usar estado mais recente após await
      final latestState = state;
      if (latestState is! RegistrationStep) {
        _isVerifying = false;
        return;
      }

      if (result.verified) {
        print('✅ [VERIFY_CODE] Código verificado com sucesso!');

        final updatedState = latestState.copyWith(
          isVerifyingCode: false,
          isEmailVerified: true,
          emailVerificationError: Nullable(null),
          isCodeVerified: true,
          verificationCode: event.code,
        );

        print('✅ [VERIFY_CODE] Estado atualizado - isEmailVerified: ${updatedState.isEmailVerified}');
        emit(updatedState);
        print('✅ [VERIFY_CODE] Estado emitido com isEmailVerified: ${updatedState.isEmailVerified}');

        // Calcular próximo step usando o helper
        final userType = updatedState.userType;
        final isMinor = updatedState.isMinor;
        final nextStep = RegistrationStepsHelper.getNextValidStep(
          updatedState.currentStep,
          userType,
          isMinor,
        );

        print(
          'RegistrationBloc: Avançando automaticamente para step $nextStep (userType=$userType, isMinor=$isMinor)',
        );

        // Emitir estado com novo step
        final nextStepState = updatedState.copyWith(
          currentStep: nextStep,
          isValid: true,
        );

        print('✅ [VERIFY_CODE] Avançando para step $nextStep - isEmailVerified preservado: ${nextStepState.isEmailVerified}');
        emit(nextStepState);
        print('✅ [VERIFY_CODE] Navegado com sucesso para step $nextStep com isEmailVerified: ${nextStepState.isEmailVerified}');
      } else {
        print('RegistrationBloc: Código inválido');
        emit(latestState.copyWith(
          isVerifyingCode: false,
          isEmailVerified: false,
          emailVerificationError: Nullable('Código inválido. Tente novamente.'),
        ));
      }
    } catch (e) {
      print('RegistrationBloc: Erro ao verificar código: $e');

      // Usar estado mais recente
      final latestState = state;
      if (latestState is! RegistrationStep) {
        _isVerifying = false;
        return;
      }

      emit(latestState.copyWith(
        isVerifyingCode: false,
        isEmailVerified: false,
        emailVerificationError: Nullable(e.toString()),
      ));
    } finally {
      _isVerifying = false;
    }
  }

  void _onUpdatePassword(
    UpdatePassword event,
    Emitter<RegistrationState> emit,
  ) {
    final currentState = state;
    if (currentState is RegistrationStep) {
      print('🔐 [UPDATE_PASSWORD] Atualizando senha. isEmailVerified antes: ${currentState.isEmailVerified}');

      // Apenas atualizar o estado sem validação automática
      final newState = currentState.copyWith(
        password: event.password,
        confirmPassword: event.confirmPassword,
        acceptedTerms: event.acceptedTerms,
        acceptedPrivacy: event.acceptedPrivacy,
      );

      print('🔐 [UPDATE_PASSWORD] isEmailVerified depois: ${newState.isEmailVerified}');
      emit(newState);
    }
  }

  void _onCompleteRegistration(
    CompleteRegistration event,
    Emitter<RegistrationState> emit,
  ) async {
    final currentState = state;
    if (currentState is RegistrationStep) {
      // Validar dados obrigatórios ANTES de mostrar loading
      if (!_validateRegistrationData(currentState)) {
        // Não mudar o estado - apenas emitir erro para mostrar SnackBar
        emit(RegistrationError('Verifique se todos os campos foram preenchidos corretamente. Veja os logs para detalhes.'));
        // Imediatamente voltar para o step atual para manter a tela
        emit(currentState);
        return;
      }

      try {
        emit(RegistrationLoading());

        // Usar use cases com payload correto da API
        // Determinar tipo e número do documento a partir do estado
        final String cleanedDocument = currentState.document.replaceAll(RegExp(r'[^0-9]'), '');
        // Usar o tipo de documento selecionado pelo usuário (armazenado no estado)
        // Converter o tipo interno para o formato da API
        final String resolvedDocumentType = _resolveDocumentTypeForApi(currentState.documentType);

        if (currentState.userType == UserType.student) {
          print('RegistrationBloc: Registrando aluno');
          await _studentRegistrationUseCase(
            firstName: currentState.firstName,
            lastName: currentState.lastName,
            email: currentState.email,
            password: currentState.password,
            birthDate: currentState.birthDate?.toIso8601String() ?? '1990-01-01',
            documentType: resolvedDocumentType,
            documentNumber: cleanedDocument,
            documentImageId: currentState.documentUpload?.id ?? 
                (throw Exception('Upload do documento é obrigatório')),
            isMinor: currentState.isMinor,
            guardianName: currentState.guardianName,
            guardianEmail: currentState.guardianEmail,
            guardianConsent: currentState.hasGuardianAuthorization,
            termsAccepted: currentState.acceptedTerms,
            privacyPolicyAccepted: currentState.acceptedPrivacy,
          );
        } else {
          // Personal Trainer
          print('RegistrationBloc: Registrando personal trainer');
          await _personalRegistrationUseCase(
            firstName: currentState.firstName,
            lastName: currentState.lastName,
            email: currentState.email,
            password: currentState.password,
            birthDate: currentState.birthDate?.toIso8601String() ?? '1990-01-01',
            documentType: resolvedDocumentType,
            documentNumber: cleanedDocument,
            documentImageId: currentState.documentUpload?.id ?? 
                (throw Exception('Upload do documento é obrigatório')),
            cref: currentState.cref.isNotEmpty ? currentState.cref : 'TEMP-CREF',
            crefImageId: currentState.crefUpload?.id ?? 
                (throw Exception('Upload do CREF é obrigatório')),
            specialties: currentState.selectedModalities.isNotEmpty ? 
                currentState.selectedModalities : ['Musculação'], // Padrão
            termsAccepted: currentState.acceptedTerms,
            privacyPolicyAccepted: currentState.acceptedPrivacy,
          );
        }

        // Sucesso - emitir estado de sucesso
        emit(RegistrationSuccess(currentState));
        
      } catch (e) {
        print('RegistrationBloc: Erro no registro: $e');
        emit(RegistrationError(_getErrorMessage(e.toString())));
      }
    }
  }

  /// Valida se todos os dados obrigatórios estão preenchidos (versão V2)
  bool _validateRegistrationData(RegistrationStep state) {
    print('🔍 [VALIDATION] Iniciando validação completa do registro...');
    print('🔍 [VALIDATION] UserType: ${state.userType}');

    // Dados pessoais obrigatórios (phone não é obrigatório)
    if (state.firstName.isEmpty) {
      print('❌ [VALIDATION] firstName vazio: "${state.firstName}"');
      return false;
    }
    if (state.lastName.isEmpty) {
      print('❌ [VALIDATION] lastName vazio: "${state.lastName}"');
      return false;
    }
    if (state.birthDate == null) {
      print('❌ [VALIDATION] birthDate null');
      return false;
    }
    print('✅ [VALIDATION] Dados pessoais OK (firstName: ${state.firstName}, lastName: ${state.lastName}, birthDate: ${state.birthDate})');

    // Upload de documento obrigatório
    if (state.documentUpload == null) {
      print('❌ [VALIDATION] documentUpload null');
      return false;
    }
    print('✅ [VALIDATION] Document upload OK (id: ${state.documentUpload?.id})');

    // Validações específicas por tipo de usuário
    if (state.userType == UserType.personalTrainer) {
      // Personal Trainer - CREF e upload obrigatórios
      if (state.cref.isEmpty) {
        print('❌ [VALIDATION] CREF vazio: "${state.cref}"');
        return false;
      }
      if (state.crefUpload == null) {
        print('❌ [VALIDATION] crefUpload null');
        return false;
      }
      if (!state.isCrefValid) {
        print('❌ [VALIDATION] isCrefValid false');
        return false;
      }
      print('✅ [VALIDATION] CREF OK (${state.cref}, valid: ${state.isCrefValid})');
    }

    // Email e verificação obrigatórios
    if (state.email.isEmpty) {
      print('❌ [VALIDATION] email vazio: "${state.email}"');
      return false;
    }
    if (!state.isEmailValid) {
      print('❌ [VALIDATION] isEmailValid false (email: ${state.email})');
      return false;
    }
    if (!state.isEmailVerified) {
      print('❌ [VALIDATION] isEmailVerified false (email: ${state.email})');
      return false;
    }
    print('✅ [VALIDATION] Email OK (${state.email}, verified: ${state.isEmailVerified})');

    // Senha obrigatória
    if (state.password.isEmpty) {
      print('❌ [VALIDATION] password vazio');
      return false;
    }
    if (state.password != state.confirmPassword) {
      print('❌ [VALIDATION] password != confirmPassword');
      return false;
    }
    print('✅ [VALIDATION] Senha OK (length: ${state.password.length})');

    // Termos obrigatórios
    if (!state.acceptedTerms) {
      print('❌ [VALIDATION] acceptedTerms false');
      return false;
    }
    if (!state.acceptedPrivacy) {
      print('❌ [VALIDATION] acceptedPrivacy false');
      return false;
    }
    print('✅ [VALIDATION] Termos aceitos OK');

    print('🎉 [VALIDATION] Validação completa PASSOU!');
    return true;
  }

  /// Converte o tipo de documento do estado interno para o formato da API
  String _resolveDocumentTypeForApi(String documentType) {
    switch (documentType.toUpperCase()) {
      case 'CPF':
        return 'CPF';
      case 'CNH':
        return 'CNH';
      case 'RG':
        return 'RG';
      default:
        // Fallback: se o documento tem máscara de CPF, usar CPF
        return 'RG';
    }
  }

  /// Converte mensagens de erro da API em mensagens amigáveis
  String _getErrorMessage(String error) {
    if (error.contains('Email já está em uso') || error.contains('email já está em uso')) {
      return 'E-mail já cadastrado. Tente fazer login ou use outro e-mail.';
    } else if (error.contains('CPF inválido') || error.contains('CNH inválida') || error.contains('documento inválido')) {
      return 'Documento inválido. Verifique o número informado.';
    } else if (error.contains('Dados inválidos')) {
      return 'Verifique os dados preenchidos e tente novamente.';
    } else if (error.contains('Erro de conexão')) {
      return 'Problema de conexão. Verifique sua internet e tente novamente.';
    } else {
      return 'Erro no cadastro. Tente novamente em alguns instantes.';
    }
  }

  void _onNavigateBack(NavigateBack event, Emitter<RegistrationState> emit) {
    // Implementação para navegação de volta
    emit(RegistrationInitial());
  }

  bool _validateStep(int step, RegistrationStep state) {
    print(
      'RegistrationBloc: _validateStep chamado para step $step, userType=${state.userType}',
    );

    // Validação específica para Personal Trainer
    if (state.userType == UserType.personalTrainer) {
      print('RegistrationBloc: Validando Personal Trainer step $step');
      switch (step) {
        case 1: // CREF
          final isValid = state.cref.isNotEmpty && 
                         state.crefUpload != null && 
                         state.isCrefValid;
          print(
            'RegistrationBloc: Step 1 (CREF) - cref="${state.cref}", crefUpload=${state.crefUpload?.id}, isCrefValid=${state.isCrefValid}, isValid=$isValid',
          );
          return isValid;

        case 2: // Dados pessoais
          final isValid =
              state.firstName.isNotEmpty &&
              state.lastName.isNotEmpty &&
              state.birthDate != null;
          print(
            'RegistrationBloc: Step 2 (Dados) - firstName="${state.firstName}", lastName="${state.lastName}", birthDate=${state.birthDate}, isValid=$isValid',
          );
          return isValid;

        case 3: // Documentos
          final documentValid =
              state.document.isNotEmpty && _isValidDocument(state.document, documentType: state.documentType);
          final photoValid = state.documentPhotoPath != null;
          final isValid = documentValid && photoValid;
          print(
            'RegistrationBloc: Step 3 (Docs) - document="${state.document}", documentType="${state.documentType}", documentValid=$documentValid, photoValid=$photoValid, isValid=$isValid',
          );
          return isValid;

        case 4: // Email
          final isValid =
              state.email.isNotEmpty &&
              _isValidEmail(state.email) &&
              (state.isCodeSent || state.verificationCodeSent);
          print(
            'RegistrationBloc: Step 4 (Email) - email="${state.email}", isValidEmail=${_isValidEmail(state.email)}, isCodeSent=${state.isCodeSent}, verificationCodeSent=${state.verificationCodeSent}, isValid=$isValid',
          );
          return isValid;

        case 5: // Verificação
          final isValid = (state.isCodeSent || state.verificationCodeSent); // Para acessar a tela de verificação, só precisa ter enviado o código
          print(
            'RegistrationBloc: Step 5 (Verification) - isCodeSent=${state.isCodeSent}, verificationCodeSent=${state.verificationCodeSent}, isValid=$isValid',
          );
          return isValid;

        case 6: // Modalidades
          final isValid = state.selectedModalities.isNotEmpty;
          print(
            'RegistrationBloc: Step 6 (Modalidades) - selectedModalities=${state.selectedModalities}, isValid=$isValid',
          );
          return isValid;

        case 7: // Senha
          return state.password.isNotEmpty &&
              state.confirmPassword.isNotEmpty &&
              state.password == state.confirmPassword &&
              _isPasswordValid(state.password) &&
              state.acceptedTerms &&
              state.acceptedPrivacy;

        default:
          return false;
      }
    }

    // Validação para estudantes (fluxo original)
    switch (step) {
      case 1: // Dados pessoais
        return state.firstName.isNotEmpty &&
            state.lastName.isNotEmpty &&
            state.birthDate != null &&
            (!state.isMinor || state.hasGuardianAuthorization);

      case 2: // Dados do responsável (se menor de idade)
        if (!state.isMinor) {
          return true; // Pula esta etapa se for maior de idade
        }
        final isValid = state.guardianName.isNotEmpty &&
            state.guardianEmail.isNotEmpty &&
            _isValidEmail(state.guardianEmail);
        print(
          'RegistrationBloc: Step 2 (Dados Responsável) - guardianName="${state.guardianName}", guardianEmail="${state.guardianEmail}", isValidEmail=${_isValidEmail(state.guardianEmail)}, isValid=$isValid',
        );
        return isValid;

      case 3: // OTP do responsável (se menor de idade) ou Documentos
        if (state.isMinor) {
          // Para menores, o step 3 é válido se tem dados do responsável (permite acessar a tela de OTP)
          final isValid = state.guardianName.isNotEmpty && 
                 state.guardianEmail.isNotEmpty && 
                 _isValidEmail(state.guardianEmail);
          print(
            'RegistrationBloc: Step 3 (OTP Responsável) - guardianName="${state.guardianName}", guardianEmail="${state.guardianEmail}", isValidEmail=${_isValidEmail(state.guardianEmail)}, isValid=$isValid',
          );
          return isValid;
        } else {
          final documentValid =
              state.document.isNotEmpty && _isValidDocument(state.document, documentType: state.documentType);
          final photoValid = state.documentPhotoPath != null;
          return documentValid && photoValid;
        }

      case 4: // Documentos (se menor) ou Email (se maior)
        if (state.isMinor) {
          final documentValid =
              state.document.isNotEmpty && _isValidDocument(state.document, documentType: state.documentType);
          final photoValid = state.documentPhotoPath != null;
          return documentValid && photoValid;
        } else {
          return state.email.isNotEmpty &&
              _isValidEmail(state.email) &&
              state.isCodeSent;
        }

      case 5: // Email (se menor) ou Verificação (se maior)
        if (state.isMinor) {
          return state.email.isNotEmpty &&
              _isValidEmail(state.email) &&
              state.isCodeSent;
        } else {
          // Para maiores, step 5 é Verificação - exigir que o email esteja verificado
          final isValid = state.isEmailVerified;
          print(
            'RegistrationBloc: Step 5 (Verificação - maior) - isEmailVerified=${state.isEmailVerified}, isValid=$isValid',
          );
          return isValid;
        }

      case 6: // Verificação (se menor) ou Senha (se maior)
        if (state.isMinor) {
          // Para menores, step 6 é Verificação - exigir que o email esteja verificado
          final isValid = state.isEmailVerified;
          print(
            'RegistrationBloc: Step 6 (Verificação - menor) - isEmailVerified=${state.isEmailVerified}, isValid=$isValid',
          );
          return isValid;
        } else {
          return state.password.isNotEmpty &&
              state.confirmPassword.isNotEmpty &&
              state.password == state.confirmPassword &&
              _isPasswordValid(state.password) &&
              state.acceptedTerms &&
              state.acceptedPrivacy;
        }

      case 7: // Senha (apenas para menores de idade)
        return state.password.isNotEmpty &&
            state.confirmPassword.isNotEmpty &&
            state.password == state.confirmPassword &&
            _isPasswordValid(state.password) &&
            state.acceptedTerms &&
            state.acceptedPrivacy;

      default:
        return false;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  bool _isPasswordValid(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) && // Pelo menos uma maiúscula
        password.contains(RegExp(r'[a-z]')) && // Pelo menos uma minúscula
        password.contains(RegExp(r'[0-9]')) && // Pelo menos um número
        password.contains(
          RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
        ); // Pelo menos um caractere especial
  }

  bool _isValidDocument(String document, {String? documentType}) {
    // Remove formatação
    final cleanDocument = document.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanDocument.length != 11) {
      return false;
    }

    // Determinar tipo de documento: se informado explicitamente, usar;
    // caso contrário, se tem máscara de CPF (pontos/traço), tratar como CPF.
    final bool isCpf = documentType == 'CPF' ||
        (documentType == null && (document.contains('.') || document.contains('-')));

    if (isCpf) {
      return _isValidCPF(cleanDocument);
    } else {
      // CNH: validação por dígitos verificadores (módulo 11)
      return _isValidCNH(cleanDocument);
    }
  }

  bool _isValidCPF(String cpf) {
    // Verifica se não é uma sequência de números repetidos
    if (_isRepeatedDigits(cpf)) return false;

    // Algoritmo de validação do CPF
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int firstVerifier = 11 - (sum % 11);
    if (firstVerifier >= 10) firstVerifier = 0;

    if (int.parse(cpf[9]) != firstVerifier) return false;

    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int secondVerifier = 11 - (sum % 11);
    if (secondVerifier >= 10) secondVerifier = 0;

    return int.parse(cpf[10]) == secondVerifier;
  }

  bool _isRepeatedDigits(String document) {
    return document.split('').every((digit) => digit == document[0]);
  }

  bool _isValidCNH(String cnh) {
    if (cnh.length != 11) return false;
    if (_isRepeatedDigits(cnh)) return false;

    // Dígitos base (9 primeiros)
    final digits = cnh.split('').map(int.parse).toList();

    // Calcular DV1 (pesos 9 -> 1)
    int sum1 = 0;
    for (int i = 0; i < 9; i++) {
      sum1 += digits[i] * (9 - i);
    }
    int resto1 = sum1 % 11;
    int desc = 0;
    int dv1;
    if (resto1 > 9) {
      dv1 = 0;
      desc = 2;
    } else {
      dv1 = resto1;
    }

    // Calcular DV2 (pesos 1 -> 9)
    int sum2 = 0;
    for (int i = 0; i < 9; i++) {
      sum2 += digits[i] * (1 + i);
    }
    int resto2 = sum2 % 11;
    int dv2 = resto2 - desc;
    if (dv2 < 0 || dv2 > 9) {
      dv2 = 0;
    }

    return digits[9] == dv1 && digits[10] == dv2;
  }

  // ===== MÉTODOS PARA PERSONAL TRAINER =====

  void _onUpdateCref(UpdateCref event, Emitter<RegistrationState> emit) {
    final currentState = state;
    if (currentState is RegistrationStep) {
      final updatedState = currentState.copyWith(
        cref: event.cref,
        crefPhotoPath: event.crefPhotoPath != null
            ? Nullable(event.crefPhotoPath)
            : Nullable(null),
        crefUpload: event.crefUpload != null
            ? Nullable(event.crefUpload)
            : Nullable(null),
        userType: UserType.personalTrainer,
        // Limpar estados de validação quando CREF é atualizado
        isCrefValidating: false,
        isCrefValid: false,
        crefValidationError: Nullable(null),
      );

      bool isValid = _validateStep(1, updatedState); // CREF é o primeiro passo

      emit(updatedState.copyWith(isValid: isValid));
    }
  }

  void _onValidateCref(ValidateCref event, Emitter<RegistrationState> emit) async {
    final currentState = state;
    if (currentState is RegistrationStep) {
      // Iniciar validação
      emit(currentState.copyWith(
        isCrefValidating: true,
        crefValidationError: Nullable(null),
      ));

      try {
        final result = await _validateCrefUseCase(event.cref);

        // Usar estado mais recente após await
        final latestState = state;
        if (latestState is! RegistrationStep) return;

        if (result.isValid && result.isBachelor) {
          // CREF válido e é bacharel - preencher nome automaticamente
          final nameParts = result.name?.split(' ') ?? [];
          final firstName = nameParts.isNotEmpty ? nameParts.first : '';
          final lastName = nameParts.length > 1
              ? nameParts.last  // Pega o último nome ao invés de todos os nomes do meio
              : '';

          final updatedState = latestState.copyWith(
            isCrefValidating: false,
            isCrefValid: true,
            crefValidationError: Nullable(null),
            // Preencher nome automaticamente do CREF
            firstName: firstName,
            lastName: lastName,
          );

          // Só permitir avanço se o upload do CREF também estiver presente
          final canAdvance = _validateStep(1, updatedState);
          emit(updatedState.copyWith(isValid: canAdvance));

          // Avançar automaticamente apenas se o upload já foi feito
          if (canAdvance) {
            await Future.delayed(const Duration(milliseconds: 1500));
            add(const NextStep());
          }
        } else {
          // CREF inválido ou não é bacharel
          emit(latestState.copyWith(
            isCrefValidating: false,
            isCrefValid: false,
            crefValidationError: Nullable(result.message ?? 'CREF inválido ou não é bacharel'),
            isValid: false,
          ));
        }
      } catch (e) {
        // Usar estado mais recente
        final latestState = state;
        if (latestState is! RegistrationStep) return;

        // Erro na validação
        emit(latestState.copyWith(
          isCrefValidating: false,
          isCrefValid: false,
          crefValidationError: Nullable(e.toString().replaceFirst('Exception: ', '')),
          isValid: false,
        ));
      }
    }
  }

  void _onUpdateModalities(
    UpdateModalities event,
    Emitter<RegistrationState> emit,
  ) {
    final currentState = state;
    if (currentState is RegistrationStep) {
      final updatedState = currentState.copyWith(
        selectedModalities: event.selectedModalities,
      );

      bool isValid = _validateStep(6, updatedState); // Modalidades é o 6º passo

      emit(updatedState.copyWith(isValid: isValid));
    }
  }

  void _onSendGuardianAuthorizationEmail(
    SendGuardianAuthorizationEmail event,
    Emitter<RegistrationState> emit,
  ) async {
    final stateBefore = state;
    if (stateBefore is RegistrationStep) {
      emit(stateBefore.copyWith(
        isSendingGuardianEmail: true,
        guardianEmailError: Nullable(null),
      ));

      try {
        // Enviar email real para o responsável
        final response = await _guardianAuthorizationService.sendGuardianAuthorizationEmail(
          guardianName: event.guardianName,
          guardianEmail: event.guardianEmail,
          studentName: event.studentName,
        );

        // Re-obter o estado mais recente após o await para não sobrescrever currentStep
        final latestState = state;
        if (latestState is! RegistrationStep) return;

        emit(latestState.copyWith(
          isSendingGuardianEmail: false,
          isGuardianEmailSent: true,
          guardianOtpCode: response['otpCode'] ?? '', // Para desenvolvimento/teste
          guardianEmailError: Nullable(null),
        ));
      } catch (e) {
        final latestState = state;
        if (latestState is! RegistrationStep) return;

        emit(latestState.copyWith(
          isSendingGuardianEmail: false,
          guardianEmailError: Nullable('Erro ao enviar email: ${e.toString()}'),
        ));
      }
    }
  }

  void _onVerifyGuardianOtp(
    VerifyGuardianOtp event,
    Emitter<RegistrationState> emit,
  ) async {
    print('RegistrationBloc: _onVerifyGuardianOtp chamado com código ${event.otpCode}');
    final stateBefore = state;
    if (stateBefore is RegistrationStep) {
      print('RegistrationBloc: Emitindo estado isVerifyingGuardianOtp=true');
      emit(stateBefore.copyWith(
        isVerifyingGuardianOtp: true,
        guardianOtpError: Nullable(null),
      ));

      try {
        // Verificar OTP real com a API
        print('RegistrationBloc: Chamando API para verificar OTP...');
        final response = await _guardianAuthorizationService.verifyGuardianOtp(
          guardianEmail: stateBefore.guardianEmail,
          otpCode: event.otpCode,
        );

        print('RegistrationBloc: Resposta da API: $response');

        // Re-obter o estado mais recente após o await para não sobrescrever currentStep
        final latestState = state;
        if (latestState is! RegistrationStep) return;

        print('RegistrationBloc: Estado mais recente após await - currentStep=${latestState.currentStep}');

        if (response['verified'] == true) {
          // Avançar automaticamente para o próximo step válido
          final nextStep = RegistrationStepsHelper.getNextValidStep(
            latestState.currentStep,
            latestState.userType,
            latestState.isMinor,
          );
          print('RegistrationBloc: OTP verificado! Avançando automaticamente para step $nextStep');

          emit(latestState.copyWith(
            isVerifyingGuardianOtp: false,
            isGuardianOtpVerified: true,
            guardianOtpError: Nullable(null),
            isValid: true,
            currentStep: nextStep,
          ));
        } else {
          print('RegistrationBloc: OTP inválido');
          emit(latestState.copyWith(
            isVerifyingGuardianOtp: false,
            guardianOtpError: Nullable('Código inválido. Tente novamente.'),
            isValid: false,
          ));
        }
      } catch (e) {
        print('RegistrationBloc: Erro ao verificar OTP: $e');
        final latestState = state;
        if (latestState is! RegistrationStep) return;

        emit(latestState.copyWith(
          isVerifyingGuardianOtp: false,
          guardianOtpError: Nullable('Erro ao verificar código: ${e.toString()}'),
          isValid: false,
        ));
      }
    }
  }

  void _onClearGuardianOtpError(
    ClearGuardianOtpError event,
    Emitter<RegistrationState> emit,
  ) {
    final currentState = state;
    if (currentState is RegistrationStep) {
      emit(currentState.copyWith(
        guardianOtpError: Nullable(null),
      ));
    }
  }

}
