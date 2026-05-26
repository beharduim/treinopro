import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/health_questionnaire_bloc.dart';
import '../bloc/health_questionnaire_event.dart';
import '../bloc/health_questionnaire_state.dart';
import '../../domain/entities/health_questionnaire.dart';
import '../widgets/health_question_dropdown.dart';

/// Etapa 3: Nível de condicionamento
class HealthQuestionnaireStep3Page extends StatefulWidget {
  const HealthQuestionnaireStep3Page({super.key});

  @override
  State<HealthQuestionnaireStep3Page> createState() =>
      _HealthQuestionnaireStep3PageState();
}

class _HealthQuestionnaireStep3PageState
    extends State<HealthQuestionnaireStep3Page> {
  String? _fitnessLevel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<HealthQuestionnaireBloc>().state;
      if (state is HealthQuestionnaireLoaded) {
        setState(() => _fitnessLevel = state.questionnaire.trainingGoal);
      }
    });
  }

  void _updateData() {
    context.read<HealthQuestionnaireBloc>().add(
          UpdateStep3(trainingGoal: _fitnessLevel),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seu condicionamento',
                    style: AppTextStyles.h2.copyWith(color: AppColors.secondary),
                  ),
                  const SizedBox(height: 32),
                  HealthQuestionDropdown(
                    question: 'Qual é o seu nível de condicionamento físico?',
                    selectedValue: _fitnessLevel,
                    options: HealthQuestionnaireOptions.fitnessLevelOptions,
                    onChanged: (value) {
                      setState(() => _fitnessLevel = value);
                      _updateData();
                    },
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context
                          .read<HealthQuestionnaireBloc>()
                          .add(const PreviousStep()),
                      child: const Text('Voltar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _fitnessLevel != null
                          ? () {
                              _updateData();
                              context.read<HealthQuestionnaireBloc>().add(
                                    const SubmitQuestionnaire(),
                                  );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Finalizar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
