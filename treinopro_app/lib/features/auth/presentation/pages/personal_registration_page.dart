import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/registration_bloc.dart';
import '../bloc/registration_event.dart' as registration_events;
import '../bloc/registration_state.dart' as registration_states;
import '../utils/registration_steps_helper.dart';
import '../../../onboarding/presentation/pages/personal_onboarding_page.dart';
import '../../../onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/utils/approval_grace_period.dart';
import '../../../home/data/services/auth_service.dart';
import 'personal_approval_pending_page.dart';

/// Página principal de cadastro do Personal
class PersonalRegistrationPage extends StatefulWidget {
  const PersonalRegistrationPage({super.key});

  @override
  State<PersonalRegistrationPage> createState() =>
      _PersonalRegistrationPageState();
}

class _PersonalRegistrationPageState extends State<PersonalRegistrationPage> {
  @override
  void initState() {
    super.initState();

    // Inicializar com UserType.personalTrainer no primeiro step APENAS se necessário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = context.read<RegistrationBloc>().state;
      print(
        'PersonalRegistrationPage: initState - estado atual: ${currentState.runtimeType}',
      );

      if (currentState is! registration_states.RegistrationStep) {
        print('PersonalRegistrationPage: Inicializando fluxo personal trainer');
        context.read<RegistrationBloc>().add(
          const registration_events.InitializePersonalTrainerFlow(),
        );
      } else if (currentState.userType !=
          registration_states.UserType.personalTrainer) {
        print(
          'PersonalRegistrationPage: Convertendo para fluxo personal trainer',
        );
        context.read<RegistrationBloc>().add(
          const registration_events.InitializePersonalTrainerFlow(),
        );
      } else {
        print(
          'PersonalRegistrationPage: Fluxo personal trainer já ativo - step ${currentState.currentStep}',
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToApprovalPending(String approvalStatus) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PersonalApprovalPendingPage(approvalStatus: approvalStatus),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToPersonalOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return BlocProvider(
            create: (_) => sl<OnboardingBloc>(),
            child: const PersonalOnboardingPage(),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.secondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Cadastro Personal',
          style: AppTextStyles.h6Semibold.copyWith(color: AppColors.secondary),
        ),
        centerTitle: true,
      ),
      body: BlocListener<RegistrationBloc, registration_states.RegistrationState>(
        listener: (context, state) {
          print(
            'PersonalRegistrationPage: BlocListener - estado: ${state.runtimeType}',
          );
          if (state is registration_states.RegistrationSuccess) {
            print('PersonalRegistrationPage: RegistrationSuccess - verificando approvalStatus...');
            // Ler approvalStatus salvo pelo datasource durante o registro
            final approvalStatus = sl<AuthService>().currentApprovalStatus;
            final createdAtRaw = sl<AuthService>().currentUserCreatedAt;
            final createdAt = createdAtRaw != null && createdAtRaw.isNotEmpty
                ? DateTime.tryParse(createdAtRaw)
                : DateTime.now();

            if (shouldBlockPersonalForApproval(
              approvalStatus: approvalStatus,
              createdAt: createdAt,
            )) {
              print(
                'PersonalRegistrationPage: approvalStatus=$approvalStatus → tela de análise',
              );
              _navigateToApprovalPending(approvalStatus ?? 'pending_review');
            } else {
              print(
                'PersonalRegistrationPage: cadastro em análise — prazo de graça, segue onboarding',
              );
              _navigateToPersonalOnboarding();
            }
          } else if (state is registration_states.RegistrationError) {
            print('PersonalRegistrationPage: RegistrationError - ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<RegistrationBloc, registration_states.RegistrationState>(
          builder: (context, state) {
            print(
              'PersonalRegistrationPage: BlocBuilder rebuild. Estado: ${state.runtimeType}',
            );

            if (state is registration_states.RegistrationLoading) {
              print('PersonalRegistrationPage: Mostrando loading');
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryOrange,
                  ),
                ),
              );
            }

            if (state is registration_states.RegistrationStep) {
              print(
                'PersonalRegistrationPage: RegistrationStep - currentStep=${state.currentStep}, userType=${state.userType}, isValid=${state.isValid}',
              );
              
              print('PersonalRegistrationPage: Renderizando step ${state.currentStep} usando helper');
              return RegistrationStepsHelper.getStepWidget(
                state.currentStep,
                registration_states.UserType.personalTrainer,
                false,
              );
            }

            // Estado inicial - mostrar primeiro step
            print(
              'PersonalRegistrationPage: Estado inicial - mostrando step 1',
            );
            return RegistrationStepsHelper.getStepWidget(
              1,
              registration_states.UserType.personalTrainer,
              false,
            );
          },
        ),
      ),
    );
  }
}
