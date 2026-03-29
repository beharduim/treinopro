import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/health_questionnaire_bloc.dart';
import '../bloc/health_questionnaire_event.dart';
import '../bloc/health_questionnaire_state.dart';
import '../../domain/entities/health_questionnaire.dart';
import '../widgets/health_question_dropdown.dart';

/// Segunda etapa: Condições Físicas
class HealthQuestionnaireStep2Page extends StatefulWidget {
  const HealthQuestionnaireStep2Page({super.key});

  @override
  State<HealthQuestionnaireStep2Page> createState() =>
      _HealthQuestionnaireStep2PageState();
}

class _HealthQuestionnaireStep2PageState
    extends State<HealthQuestionnaireStep2Page> {
  // seleção separada e controllers para permitir 'Outros' + texto livre
  String? _chronicInjurySelection;
  final TextEditingController _chronicInjuryController =
      TextEditingController();

  String? _trainingGoalSelection;
  final TextEditingController _trainingGoalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Carregar valores salvos se existirem
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<HealthQuestionnaireBloc>().state;
      if (state is HealthQuestionnaireLoaded) {
        setState(() {
          final savedInjury = state.questionnaire.chronicInjury;
          if (savedInjury != null &&
              HealthQuestionnaireOptions.injuryOptions.contains(savedInjury)) {
            _chronicInjurySelection = savedInjury;
            _chronicInjuryController.text = '';
          } else if (savedInjury != null && savedInjury.isNotEmpty) {
            _chronicInjurySelection = 'Outras';
            _chronicInjuryController.text = savedInjury;
          }

          final savedGoal = state.questionnaire.trainingGoal;
          if (savedGoal != null &&
              HealthQuestionnaireOptions.trainingGoals.contains(savedGoal)) {
            _trainingGoalSelection = savedGoal;
            _trainingGoalController.text = '';
          } else if (savedGoal != null && savedGoal.isNotEmpty) {
            _trainingGoalSelection = 'Outras';
            _trainingGoalController.text = savedGoal;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _chronicInjuryController.dispose();
    _trainingGoalController.dispose();
    super.dispose();
  }

  String? get _selectedChronicInjuryValue {
    if (_chronicInjurySelection == null) return null;
    if (_chronicInjurySelection == 'Outras') {
      return _chronicInjuryController.text.isNotEmpty
          ? _chronicInjuryController.text
          : null;
    }
    return _chronicInjurySelection;
  }

  String? get _selectedTrainingGoalValue {
    if (_trainingGoalSelection == null) return null;
    if (_trainingGoalSelection == 'Outras') {
      return _trainingGoalController.text.isNotEmpty
          ? _trainingGoalController.text
          : null;
    }
    return _trainingGoalSelection;
  }

  bool get _isFormValid =>
      _selectedChronicInjuryValue != null && _selectedTrainingGoalValue != null;

  void _updateData() {
    context.read<HealthQuestionnaireBloc>().add(
      UpdateStep2(
        chronicInjury: _selectedChronicInjuryValue,
        trainingGoal: _selectedTrainingGoalValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Conteúdo principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Perguntas
                    Column(
                      children: [
                        HealthQuestionDropdown(
                          question: 'Você tem alguma lesão ou dor crônica?',
                          selectedValue: _chronicInjurySelection,
                          options: HealthQuestionnaireOptions.injuryOptions,
                          onChanged: (value) {
                            setState(() {
                              _chronicInjurySelection = value;
                              if (value != 'Outras')
                                _chronicInjuryController.text = '';
                            });
                            _updateData();
                          },
                        ),

                        if (_chronicInjurySelection == 'Outras') ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _chronicInjuryController,
                            cursorColor: AppColors.primaryOrange,
                            decoration: InputDecoration(
                              hintText: 'Descreva a lesão ou dor',
                              border: const UnderlineInputBorder(),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.secondaryDark,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primaryOrange,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (v) {
                              setState(() {});
                              _updateData();
                            },
                          ),
                        ],

                        const SizedBox(height: 24),

                        HealthQuestionDropdown(
                          question:
                              'Qual é o seu objetivo principal com o treino?',
                          selectedValue: _trainingGoalSelection,
                          options: HealthQuestionnaireOptions.trainingGoals,
                          onChanged: (value) {
                            setState(() {
                              _trainingGoalSelection = value;
                              if (value != 'Outras')
                                _trainingGoalController.text = '';
                            });
                            _updateData();
                          },
                        ),

                        if (_trainingGoalSelection == 'Outras') ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _trainingGoalController,
                            cursorColor: AppColors.primaryOrange,
                            decoration: InputDecoration(
                              hintText: 'Descreva seu objetivo',
                              border: const UnderlineInputBorder(),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.secondaryDark,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primaryOrange,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (v) {
                              setState(() {});
                              _updateData();
                            },
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Botão fixo na parte inferior
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isFormValid
                        ? () {
                            // Atualizar os dados no BLoC antes de avançar
                            _updateData();

                            // Pequeno delay para garantir que o estado foi atualizado
                            Future.delayed(
                              const Duration(milliseconds: 100),
                              () {
                                context.read<HealthQuestionnaireBloc>().add(
                                  const NextStep(),
                                );
                              },
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid
                          ? AppColors.primaryOrange
                          : AppColors.secondaryDark.withValues(alpha: 0.3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continuar',
                      style: AppTextStyles.buttonPrimary.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
