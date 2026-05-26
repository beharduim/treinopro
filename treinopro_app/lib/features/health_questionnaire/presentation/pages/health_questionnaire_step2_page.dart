import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/health_questionnaire_bloc.dart';
import '../bloc/health_questionnaire_event.dart';
import '../bloc/health_questionnaire_state.dart';
import '../../domain/entities/health_questionnaire.dart';
import '../widgets/health_question_dropdown.dart';

/// Etapa 2: Sintomas cardíacos + condição de saúde
class HealthQuestionnaireStep2Page extends StatefulWidget {
  const HealthQuestionnaireStep2Page({super.key});

  @override
  State<HealthQuestionnaireStep2Page> createState() =>
      _HealthQuestionnaireStep2PageState();
}

class _HealthQuestionnaireStep2PageState
    extends State<HealthQuestionnaireStep2Page> {
  String? _chestPainSymptoms;
  String? _healthCondition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<HealthQuestionnaireBloc>().state;
      if (state is HealthQuestionnaireLoaded) {
        setState(() {
          _chestPainSymptoms = state.questionnaire.dietaryRestrictions;
          _healthCondition = state.questionnaire.medicalCondition;
        });
      }
    });
  }

  bool get _isFormValid =>
      _chestPainSymptoms != null && _healthCondition != null;

  void _updateData() {
    context.read<HealthQuestionnaireBloc>().add(
          UpdateStep2(
            dietaryRestrictions: _chestPainSymptoms,
            medicalCondition: _healthCondition,
          ),
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
                    'Saúde cardiovascular',
                    style: AppTextStyles.h2.copyWith(color: AppColors.secondary),
                  ),
                  const SizedBox(height: 32),
                  HealthQuestionDropdown(
                    question:
                        'Sente dor no peito, falta de ar ou tontura durante esforço?',
                    selectedValue: _chestPainSymptoms,
                    options: HealthQuestionnaireOptions.chestPainSymptomsOptions,
                    onChanged: (value) {
                      setState(() => _chestPainSymptoms = value);
                      _updateData();
                    },
                  ),
                  const SizedBox(height: 24),
                  HealthQuestionDropdown(
                    question:
                        'Possui alguma condição de saúde (pressão, diabetes, etc.)?',
                    selectedValue: _healthCondition,
                    options: HealthQuestionnaireOptions.healthConditionOptions,
                    onChanged: (value) {
                      setState(() => _healthCondition = value);
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
                      onPressed: _isFormValid
                          ? () {
                              _updateData();
                              context.read<HealthQuestionnaireBloc>().add(
                                    const NextStep(),
                                  );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Continuar'),
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
