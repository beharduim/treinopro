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

/// Primeira etapa: Informações Básicas
class HealthQuestionnaireStep1Page extends StatefulWidget {
  const HealthQuestionnaireStep1Page({super.key});

  @override
  State<HealthQuestionnaireStep1Page> createState() =>
      _HealthQuestionnaireStep1PageState();
}

class _HealthQuestionnaireStep1PageState
    extends State<HealthQuestionnaireStep1Page> {
  // seleção do dropdown (valor entre as opções) — pode ser 'Outras'
  String? _medicalConditionSelection;
  // controller para quando o usuário escolher 'Outras' e digitar o texto
  final TextEditingController _medicalConditionController =
      TextEditingController();

  String? _regularMedication;

  @override
  void initState() {
    super.initState();
    // Carregar valores salvos se existirem
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<HealthQuestionnaireBloc>().state;
      if (state is HealthQuestionnaireLoaded) {
        setState(() {
          final saved = state.questionnaire.medicalCondition;
          // Se o valor salvo corresponder a uma das opções, use como seleção;
          // caso contrário, marque 'Outras' e preencha o controller com o valor salvo.
          if (saved != null &&
              HealthQuestionnaireOptions.medicalConditions.contains(saved)) {
            _medicalConditionSelection = saved;
            _medicalConditionController.text = '';
          } else if (saved != null && saved.isNotEmpty) {
            _medicalConditionSelection = 'Outras';
            _medicalConditionController.text = saved;
          }

          _regularMedication = state.questionnaire.regularMedication;
        });
      }
    });
  }

  @override
  void dispose() {
    _medicalConditionController.dispose();
    super.dispose();
  }

  String? get _selectedMedicalConditionValue {
    if (_medicalConditionSelection == null) return null;
    if (_medicalConditionSelection == 'Outras') {
      return _medicalConditionController.text.isNotEmpty
          ? _medicalConditionController.text
          : null;
    }
    return _medicalConditionSelection;
  }

  bool get _isFormValid =>
      _selectedMedicalConditionValue != null && _regularMedication != null;

  void _updateData() {
    context.read<HealthQuestionnaireBloc>().add(
      UpdateStep1(
        medicalCondition: _selectedMedicalConditionValue,
        regularMedication: _regularMedication,
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
                    // Header informativo
                    const HealthQuestionnaireHeader(),

                    const SizedBox(height: 32),

                    // Perguntas
                    Column(
                      children: [
                        HealthQuestionDropdown(
                          question:
                              'Você possui alguma condição médica preexistente?',
                          selectedValue: _medicalConditionSelection,
                          options: HealthQuestionnaireOptions.medicalConditions,
                          onChanged: (value) {
                            setState(() {
                              _medicalConditionSelection = value;
                              // se o usuário mudou para uma opção distinta de 'Outras', limpa o controller
                              if (value != 'Outras') {
                                _medicalConditionController.text = '';
                              }
                            });
                            _updateData();
                          },
                        ),

                        // Se o usuário escolheu 'Outras', mostra um campo para digitar a condição
                        if (_medicalConditionSelection == 'Outras') ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _medicalConditionController,
                            cursorColor: AppColors.primaryOrange,
                            decoration: InputDecoration(
                              hintText: 'Descreva sua condição',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
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
                              // atualiza o BLoC enquanto digita
                              setState(() {});
                              _updateData();
                            },
                          ),
                        ],

                        const SizedBox(height: 24),

                        HealthQuestionDropdown(
                          question: 'Você toma algum medicamento regularmente?',
                          selectedValue: _regularMedication,
                          options: HealthQuestionnaireOptions.medicationOptions,
                          onChanged: (value) {
                            setState(() {
                              _regularMedication = value;
                            });
                            _updateData();
                          },
                        ),
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
