import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/health_questionnaire_bloc.dart';
import '../bloc/health_questionnaire_event.dart';
import '../bloc/health_questionnaire_state.dart';
import '../../domain/entities/health_questionnaire.dart';
import '../widgets/health_question_dropdown.dart';
import '../widgets/health_questionnaire_header.dart';

/// Etapa 1: Lesão/limitação + recomendação médica
class HealthQuestionnaireStep1Page extends StatefulWidget {
  const HealthQuestionnaireStep1Page({super.key});

  @override
  State<HealthQuestionnaireStep1Page> createState() =>
      _HealthQuestionnaireStep1PageState();
}

class _HealthQuestionnaireStep1PageState
    extends State<HealthQuestionnaireStep1Page> {
  String? _physicalLimitation;
  String? _medicalRecommendation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<HealthQuestionnaireBloc>().state;
      if (state is HealthQuestionnaireLoaded) {
        setState(() {
          _physicalLimitation = state.questionnaire.chronicInjury;
          _medicalRecommendation = state.questionnaire.regularMedication;
        });
      }
    });
  }

  bool get _isFormValid =>
      _physicalLimitation != null && _medicalRecommendation != null;

  void _updateData() {
    context.read<HealthQuestionnaireBloc>().add(
          UpdateStep1(
            chronicInjury: _physicalLimitation,
            regularMedication: _medicalRecommendation,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const HealthQuestionnaireHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Questionário de saúde',
                    style: AppTextStyles.h2.copyWith(color: AppColors.secondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Responda com atenção. Suas respostas ajudam o personal a conduzir o treino com segurança.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.secondaryDark.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  HealthQuestionDropdown(
                    question: 'Você possui alguma lesão ou limitação física?',
                    selectedValue: _physicalLimitation,
                    options: HealthQuestionnaireOptions.physicalLimitationOptions,
                    onChanged: (value) {
                      setState(() => _physicalLimitation = value);
                      _updateData();
                    },
                  ),
                  const SizedBox(height: 24),
                  HealthQuestionDropdown(
                    question:
                        'Possui recomendação médica para evitar exercícios?',
                    selectedValue: _medicalRecommendation,
                    options:
                        HealthQuestionnaireOptions.medicalRecommendationOptions,
                    onChanged: (value) {
                      setState(() => _medicalRecommendation = value);
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isFormValid
                      ? () {
                          _updateData();
                          context.read<HealthQuestionnaireBloc>().add(
                                const NextStep(),
                              );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? AppColors.primaryOrange
                        : AppColors.secondaryDark.withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Continuar'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
