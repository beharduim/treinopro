import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/health_questionnaire_bloc.dart';
import '../bloc/health_questionnaire_event.dart';
import '../bloc/health_questionnaire_state.dart';
import '../widgets/health_questionnaire_progress.dart';
import 'health_questionnaire_step1_page.dart';
import 'health_questionnaire_step2_page.dart';
import 'health_questionnaire_step3_page.dart';

/// Página principal do questionário de saúde que gerencia todas as etapas
class HealthQuestionnairePage extends StatefulWidget {
  const HealthQuestionnairePage({super.key});

  @override
  State<HealthQuestionnairePage> createState() => _HealthQuestionnairePageState();
}

class _HealthQuestionnairePageState extends State<HealthQuestionnairePage> {
  @override
  void initState() {
    super.initState();
    // Inicializar o questionário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthQuestionnaireBloc>().add(
        const InitializeQuestionnaire(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HealthQuestionnaireBloc, HealthQuestionnaireState>(
      listener: (context, state) {
        if (state is HealthQuestionnaireSuccess) {
          // Mostrar mensagem de sucesso e voltar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.primaryOrange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Voltar para a tela anterior
          Navigator.of(context).pop();
        } else if (state is HealthQuestionnaireError) {
          // Mostrar mensagem de erro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is HealthQuestionnaireLoading) {
          return const Scaffold(
            backgroundColor: AppColors.loginBackground,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryOrange,
              ),
            ),
          );
        }

        if (state is HealthQuestionnaireLoaded) {
          return _buildQuestionnaireContent(state);
        }

        if (state is HealthQuestionnaireError) {
          return _buildErrorState(state);
        }

        // Estado inicial
        return const Scaffold(
          backgroundColor: AppColors.loginBackground,
          body: Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryOrange,
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionnaireContent(HealthQuestionnaireLoaded state) {
    // Determinar qual página mostrar baseado na etapa atual
    Widget currentStepPage;
    
    switch (state.currentStep) {
      case 1:
        currentStepPage = const HealthQuestionnaireStep1Page();
        break;
      case 2:
        currentStepPage = const HealthQuestionnaireStep2Page();
        break;
      case 3:
        currentStepPage = const HealthQuestionnaireStep3Page();
        break;
      default:
        currentStepPage = const HealthQuestionnaireStep1Page();
    }

    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header com botão voltar e título
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.chevron_left,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Questionário de saúde',
                      style: AppTextStyles.h6Semibold.copyWith(
                        color: AppColors.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Para centralizar o título
                ],
              ),
            ),
            
            // Barra de progresso
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HealthQuestionnaireProgress(
                currentStep: state.currentStep,
                totalSteps: state.totalSteps,
              ),
            ),

            const SizedBox(height: 32),

            // Conteúdo da etapa atual
            Expanded(child: currentStepPage),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(HealthQuestionnaireError state) {
    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  'Erro ao carregar questionário',
                  style: AppTextStyles.h6Semibold.copyWith(
                    color: AppColors.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: AppTextStyles.paragraph.copyWith(
                    color: AppColors.secondaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    context.read<HealthQuestionnaireBloc>().add(
                      const InitializeQuestionnaire(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
