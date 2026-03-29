import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/health_questionnaire_bloc.dart';
import '../bloc/health_questionnaire_event.dart';
import '../bloc/health_questionnaire_state.dart';
import '../../domain/entities/health_questionnaire.dart';
import '../widgets/health_question_dropdown.dart';

/// Terceira etapa: Alimentação
class HealthQuestionnaireStep3Page extends StatefulWidget {
  const HealthQuestionnaireStep3Page({super.key});

  @override
  State<HealthQuestionnaireStep3Page> createState() =>
      _HealthQuestionnaireStep3PageState();
}

class _HealthQuestionnaireStep3PageState
    extends State<HealthQuestionnaireStep3Page> {
  // seleção separada para permitir opção 'Outras' com campo livre
  String? _dietaryRestrictionsSelection;
  final TextEditingController _dietaryRestrictionsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // Carregar valores salvos se existirem
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<HealthQuestionnaireBloc>().state;
      if (state is HealthQuestionnaireLoaded) {
        setState(() {
          final saved = state.questionnaire.dietaryRestrictions;
          if (saved != null &&
              HealthQuestionnaireOptions.dietaryOptions.contains(saved)) {
            _dietaryRestrictionsSelection = saved;
            _dietaryRestrictionsController.text = '';
          } else if (saved != null && saved.isNotEmpty) {
            _dietaryRestrictionsSelection = 'Outras restrições';
            _dietaryRestrictionsController.text = saved;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _dietaryRestrictionsController.dispose();
    super.dispose();
  }

  String? get _selectedDietaryRestrictionsValue {
    if (_dietaryRestrictionsSelection == null) return null;
    // usamos 'Outras restrições' como label para diferenciar das opções
    if (_dietaryRestrictionsSelection == 'Outras restrições') {
      return _dietaryRestrictionsController.text.isNotEmpty
          ? _dietaryRestrictionsController.text
          : null;
    }
    return _dietaryRestrictionsSelection;
  }

  bool get _isFormValid => _selectedDietaryRestrictionsValue != null;

  void _updateData() {
    context.read<HealthQuestionnaireBloc>().add(
      UpdateStep3(dietaryRestrictions: _selectedDietaryRestrictionsValue),
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
                          question:
                              'Você tem alguma restrição alimentar ou alergia?',
                          selectedValue: _dietaryRestrictionsSelection,
                          options: HealthQuestionnaireOptions.dietaryOptions,
                          onChanged: (value) {
                            setState(() {
                              _dietaryRestrictionsSelection = value;
                              if (value != 'Outras restrições')
                                _dietaryRestrictionsController.text = '';
                            });
                            _updateData();
                          },
                        ),

                        if (_dietaryRestrictionsSelection ==
                            'Outras restrições') ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _dietaryRestrictionsController,
                            cursorColor: AppColors.primaryOrange,
                            decoration: InputDecoration(
                              hintText: 'Descreva suas restrições',
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
                                  const SubmitQuestionnaire(),
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
                      'Enviar respostas',
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
