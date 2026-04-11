import 'package:flutter/material.dart';
import '../bloc/registration_state.dart' as registration_states;
import '../pages/steps/cref_step.dart';
import '../pages/steps/personal_data_step.dart';
import '../pages/steps/guardian_data_step.dart';
import '../pages/steps/guardian_otp_step.dart';
import '../pages/steps/documents_step.dart';
import '../pages/steps/email_step.dart';
import '../pages/steps/verification_step.dart';
import '../pages/steps/modalities_step.dart';
import '../pages/steps/password_step.dart';

class RegistrationStepsHelper {
  /// Retorna o widget correspondente ao step interno
  static Widget getStepWidget(
    int internalStep,
    registration_states.UserType userType,
    bool isMinor,
  ) {
    final stepInfo = getStepInfo(internalStep, userType, isMinor);

    if (userType == registration_states.UserType.personalTrainer) {
      switch (internalStep) {
        case 1:
          return const CrefStep();
        case 2:
          return PersonalDataStep(
            customCurrentStep: stepInfo.displayStep,
            customTotalSteps: stepInfo.totalSteps,
          );
        case 3:
          return DocumentsStep(
            customCurrentStep: stepInfo.displayStep,
            customTotalSteps: stepInfo.totalSteps,
          );
        case 4:
          return EmailStep(
            customCurrentStep: stepInfo.displayStep,
            customTotalSteps: stepInfo.totalSteps,
          );
        case 5:
          return const VerificationStep();
        case 6:
          return const ModalitiesStep();
        case 7:
          return const PasswordStep();
        default:
          return const CrefStep();
      }
    } else {
      // Estudante
      switch (internalStep) {
        case 1:
          return const PersonalDataStep();
        case 2:
          return isMinor ? const GuardianDataStep() : const DocumentsStep();
        case 3:
          return isMinor ? const GuardianOtpStep() : const DocumentsStep();
        case 4:
          return isMinor ? const DocumentsStep() : const EmailStep();
        case 5:
          return isMinor ? const EmailStep() : const VerificationStep();
        case 6:
          return isMinor ? const VerificationStep() : const PasswordStep();
        case 7:
          return const PasswordStep();
        default:
          return const PersonalDataStep();
      }
    }
  }

  /// Calcula o número total de etapas baseado no tipo de usuário
  static int getTotalSteps(
    registration_states.UserType userType,
    bool isMinor,
  ) {
    switch (userType) {
      case registration_states.UserType.personalTrainer:
        return 7; // CREF → Dados → Documentos → Email → Verificação → Modalidades → Senha
      case registration_states.UserType.student:
        return isMinor ? 7 : 5; // Com/sem etapa de responsável e OTP
    }
  }

  /// Calcula a etapa atual para exibição na barra de progresso
  static int getCurrentStepForDisplay(
    int internalStep,
    registration_states.UserType userType,
    bool isMinor,
  ) {
    switch (userType) {
      case registration_states.UserType.personalTrainer:
        return _getPersonalTrainerDisplayStep(internalStep);
      case registration_states.UserType.student:
        return _getStudentDisplayStep(internalStep, isMinor);
    }
  }

  /// Mapeia etapas internas para etapas de exibição - Personal Trainer
  static int _getPersonalTrainerDisplayStep(int internalStep) {
    // Personal Trainer: 7 etapas
    // Step 1: CREF → Display 1
    // Step 2: Dados pessoais → Display 2
    // Step 3: Documentos → Display 3
    // Step 4: Email → Display 4
    // Step 5: Verificação → Display 5
    // Step 6: Modalidades → Display 6
    // Step 7: Senha → Display 7
    return internalStep.clamp(1, 7);
  }

  /// Mapeia etapas internas para etapas de exibição - Estudante
  static int _getStudentDisplayStep(int internalStep, bool isMinor) {
    if (isMinor) {
      // Estudante menor: 7 etapas
      // Step 1: Dados pessoais → Display 1
      // Step 2: Dados Responsável → Display 2
      // Step 3: OTP Responsável → Display 3
      // Step 4: Documentos → Display 4
      // Step 5: Email → Display 5
      // Step 6: Verificação → Display 6
      // Step 7: Senha → Display 7
      return internalStep.clamp(1, 7);
    } else {
      // Estudante maior: 5 etapas (pula responsável)
      // Step 1: Dados pessoais → Display 1
      // Step 3: Documentos → Display 2 (pula step 2)
      // Step 4: Email → Display 3
      // Step 5: Verificação → Display 4
      // Step 6: Senha → Display 5
      switch (internalStep) {
        case 1:
          return 1; // Dados Pessoais
        case 3:
          return 2; // Documentos
        case 4:
          return 3; // Email
        case 5:
          return 4; // Verificação
        case 6:
          return 5; // Senha
        default:
          return internalStep.clamp(1, 5);
      }
    }
  }

  /// Obtém o nome da etapa atual
  static String getStepName(
    int internalStep,
    registration_states.UserType userType,
    bool isMinor,
  ) {
    switch (userType) {
      case registration_states.UserType.personalTrainer:
        return _getPersonalTrainerStepName(internalStep);
      case registration_states.UserType.student:
        return _getStudentStepName(internalStep, isMinor);
    }
  }

  static String _getPersonalTrainerStepName(int internalStep) {
    switch (internalStep) {
      case 1:
        return 'CREF';
      case 2:
        return 'Dados pessoais';
      case 3:
        return 'Documentos';
      case 4:
        return 'Email';
      case 5:
        return 'Verificação';
      case 6:
        return 'Modalidades';
      case 7:
        return 'Senha';
      default:
        return 'Etapa $internalStep';
    }
  }

  static String _getStudentStepName(int internalStep, bool isMinor) {
    if (isMinor) {
      switch (internalStep) {
        case 1:
          return 'Dados pessoais';
        case 2:
          return 'Dados do Responsável';
        case 3:
          return 'Autorização';
        case 4:
          return 'Documentos';
        case 5:
          return 'Email';
        case 6:
          return 'Verificação';
        case 7:
          return 'Senha';
        default:
          return 'Etapa $internalStep';
      }
    } else {
      switch (internalStep) {
        case 1:
          return 'Dados pessoais';
        case 3:
          return 'Documentos';
        case 4:
          return 'Email';
        case 5:
          return 'Verificação';
        case 6:
          return 'Senha';
        default:
          return 'Etapa $internalStep';
      }
    }
  }

  /// Verifica se uma etapa específica deve ser exibida
  static bool shouldShowStep(
    int internalStep,
    registration_states.UserType userType,
    bool isMinor,
  ) {
    switch (userType) {
      case registration_states.UserType.personalTrainer:
        return internalStep >= 1 && internalStep <= 7;
      case registration_states.UserType.student:
        if (!isMinor && internalStep == 2) {
          return false; // Pula etapa de responsável se maior de idade
        }
        return internalStep >= 1 && internalStep <= 7;
    }
  }

  /// Obtém informações completas da etapa
  static StepInfo getStepInfo(
    int internalStep,
    registration_states.UserType userType,
    bool isMinor,
  ) {
    return StepInfo(
      internalStep: internalStep,
      displayStep: getCurrentStepForDisplay(internalStep, userType, isMinor),
      totalSteps: getTotalSteps(userType, isMinor),
      stepName: getStepName(internalStep, userType, isMinor),
      shouldShow: shouldShowStep(internalStep, userType, isMinor),
    );
  }

  /// Obtém o próximo step interno válido
  static int getNextValidStep(
    int currentStep,
    registration_states.UserType userType,
    bool isMinor,
  ) {
    // Tentar o próximo step
    final nextStep = currentStep + 1;

    // Verificar se o próximo step deve ser mostrado
    if (shouldShowStep(nextStep, userType, isMinor)) {
      return nextStep;
    }

    // Se não, tentar o step seguinte
    return nextStep + 1;
  }

  /// Obtém o step anterior válido
  static int getPreviousValidStep(
    int currentStep,
    registration_states.UserType userType,
    bool isMinor,
  ) {
    if (currentStep <= 1) return 1;

    // Tentar o step anterior
    final prevStep = currentStep - 1;

    // Verificar se o step anterior deve ser mostrado
    if (shouldShowStep(prevStep, userType, isMinor)) {
      return prevStep;
    }

    // Se não, tentar o step anterior a esse
    return prevStep - 1 > 0 ? prevStep - 1 : 1;
  }
}

class StepInfo {
  final int internalStep;
  final int displayStep;
  final int totalSteps;
  final String stepName;
  final bool shouldShow;

  const StepInfo({
    required this.internalStep,
    required this.displayStep,
    required this.totalSteps,
    required this.stepName,
    required this.shouldShow,
  });

  @override
  String toString() {
    return 'StepInfo(internal: $internalStep, display: $displayStep/$totalSteps, name: $stepName, show: $shouldShow)';
  }
}
