import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../domain/usecases/student_registration_usecases.dart';
import '../../domain/usecases/personal_registration_usecases.dart';
import '../../domain/usecases/validate_cref_usecase.dart';
import '../../domain/usecases/send_verification_code_usecase.dart';
import '../../domain/usecases/verify_code_usecase.dart';
import '../../domain/usecases/validate_email_usecase.dart';
import '../../domain/usecases/check_document_usecase.dart';
import '../../data/services/guardian_authorization_service.dart';
import '../../../../core/helpers/status_bar_helper.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../bloc/registration_bloc.dart';
import '../bloc/registration_event.dart' as registration_events;
import '../bloc/registration_state.dart' as registration_states;
import '../utils/registration_steps_helper.dart';
import '../../../onboarding/presentation/pages/student_onboarding_page.dart';
import '../../../onboarding/presentation/bloc/onboarding_bloc.dart';
import 'steps/personal_data_step.dart';
import 'steps/guardian_data_step.dart';
import 'steps/guardian_otp_step.dart';
import 'steps/documents_step.dart';
import 'steps/email_step.dart';
import 'steps/verification_step.dart';
import 'steps/password_step.dart';

/// Página principal de cadastro do Estudante
class StudentRegistrationPage extends StatefulWidget {
  const StudentRegistrationPage({super.key});

  @override
  State<StudentRegistrationPage> createState() =>
      _StudentRegistrationPageState();
}

class _StudentRegistrationPageState extends State<StudentRegistrationPage> {
  late final RegistrationBloc _registrationBloc;

  @override
  void initState() {
    super.initState();

    // Define ícones pretos para página clara
    StatusBarHelper.setDarkStatusBar();

    _registrationBloc = RegistrationBloc(
      studentRegistrationUseCase: sl<StudentRegistrationUseCase>(),
      personalRegistrationUseCase: sl<PersonalRegistrationUseCase>(),
      validateCrefUseCase: sl<ValidateCrefUseCase>(),
      sendVerificationCodeUseCase: sl<SendVerificationCodeUseCase>(),
      verifyCodeUseCase: sl<VerifyCodeUseCase>(),
      validateEmailUseCase: sl<ValidateEmailUseCase>(),
      checkDocumentUseCase: sl<CheckDocumentUseCase>(),
      guardianAuthorizationService: sl<GuardianAuthorizationService>(),
    );

    // Inicializar corretamente como estudante
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registrationBloc.add(const registration_events.InitializeStudentFlow());
    });
  }

  @override
  void dispose() {
    _registrationBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      isDarkBackground: false, // Página clara, ícones pretos
      child: BlocProvider<RegistrationBloc>.value(
        value: _registrationBloc,
        child: Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            title: Text(
              'Cadastro do aluno',
              style: AppTextStyles.h6Semibold.copyWith(
                color: AppColors.secondary,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.secondary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body:
              BlocListener<
                RegistrationBloc,
                registration_states.RegistrationState
              >(
                listener: (context, state) {
                  if (state is registration_states.RegistrationSuccess) {
                    // Navegar para o onboarding do aluno
                    _navigateToOnboarding();
                  } else if (state is registration_states.RegistrationError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child:
                    BlocBuilder<
                      RegistrationBloc,
                      registration_states.RegistrationState
                    >(
                      builder: (context, state) {
                        return SafeArea(child: _buildCurrentStep(state));
                      },
                    ),
              ),
        ), // fecha Scaffold
      ), // fecha BlocProvider
    ); // fecha StatusBarWrapper
  }

  /// Navega para o onboarding do aluno após cadastro bem-sucedido
  void _navigateToOnboarding() {
    print('StudentRegistrationPage: _navigateToOnboarding chamado');

    // Usar pushReplacement para evitar voltar para o cadastro
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          print('StudentRegistrationPage: Criando StudentOnboardingPage');
          return BlocProvider(
            create: (context) {
              print('StudentRegistrationPage: Criando OnboardingBloc');
              return sl<OnboardingBloc>();
            },
            child: const StudentOnboardingPage(),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Transição suave sem mostrar passos anteriores
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildCurrentStep(registration_states.RegistrationState state) {
    if (state is registration_states.RegistrationStep) {
      // Verificar se o estudante é menor de idade
      final isMinor = state.isMinor;

      print('StudentRegistrationPage: _buildCurrentStep - currentStep=${state.currentStep}, isMinor=$isMinor');

      // Usar helper para determinar se o step atual deve ser mostrado
      final stepInfo = RegistrationStepsHelper.getStepInfo(
        state.currentStep,
        registration_states.UserType.student,
        isMinor,
      );

      if (!stepInfo.shouldShow) {
        // Se o step atual não deve ser mostrado (ex: step 2 para maiores),
        // vamos pular para o próximo automaticamente
        print('StudentRegistrationPage: Step ${state.currentStep} não deve ser mostrado, pulando...');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<RegistrationBloc>().add(
            const registration_events.NextStep(),
          );
        });

        // Mostrar um indicador de carregamento enquanto avança
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
          ),
        );
      }

      print('StudentRegistrationPage: Renderizando step ${state.currentStep} usando helper');
      return RegistrationStepsHelper.getStepWidget(
        state.currentStep,
        registration_states.UserType.student,
        isMinor,
      );
    }

    // Estado inicial
    print('StudentRegistrationPage: Estado inicial, renderizando PersonalDataStep');
    return const PersonalDataStep();
  }
}
