import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../bloc/registration_bloc.dart';
import '../../bloc/registration_event.dart' as registration_events;
import '../../bloc/registration_state.dart' as registration_states;
import '../../widgets/registration_progress_bar.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/registration_steps_helper.dart';

/// Formatador de data DD/MM/AAAA
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length > 10) {
      return oldValue;
    }

    String formattedText = '';
    int selectionIndex = newValue.selection.end;

    for (int i = 0; i < text.length; i++) {
      if (text[i].contains(RegExp(r'[0-9]'))) {
        formattedText += text[i];
        if ((formattedText.length == 2 || formattedText.length == 5) &&
            formattedText.length < 10) {
          formattedText += '/';
          if (i < selectionIndex) selectionIndex++;
        }
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

/// Primeira etapa: Dados Pessoais
class PersonalDataStep extends StatefulWidget {
  final int? customCurrentStep;
  final int? customTotalSteps;

  const PersonalDataStep({
    super.key,
    this.customCurrentStep,
    this.customTotalSteps,
  });

  @override
  State<PersonalDataStep> createState() => _PersonalDataStepState();
}

class _PersonalDataStepState extends State<PersonalDataStep> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _selectedDate;
  bool _hasGuardianAuthorization = false;
  bool _isMinor = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_updateData);
    _lastNameController.addListener(_updateData);
    
    // Preencher campos com dados do BLoC se disponíveis
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = context.read<RegistrationBloc>().state;
      if (currentState is registration_states.RegistrationStep) {
        if (currentState.firstName.isNotEmpty) {
          _firstNameController.text = currentState.firstName;
        }
        if (currentState.lastName.isNotEmpty) {
          _lastNameController.text = currentState.lastName;
        }
        if (currentState.birthDate != null) {
          _setSelectedDate(currentState.birthDate!);
        }
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _updateData() {
    // Apenas fazer rebuild local, sem chamar o BLoC constantemente
    // O BLoC será atualizado apenas quando necessário (botão continuar)
    setState(() {
      // Forçar rebuild para validações visuais
    });
  }

  bool _isFormValid() {
    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _selectedDate != null &&
        (!_isMinor || _hasGuardianAuthorization);
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _setSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _dateController.text = _formatDate(date);

      // Verifica se é menor de idade
      final now = DateTime.now();
      final age = now.year - date.year;
      final monthDiff = now.month - date.month;
      final dayDiff = now.day - date.day;

      if (monthDiff < 0 || (monthDiff == 0 && dayDiff < 0)) {
        _isMinor = (age - 1) < 18;
      } else {
        _isMinor = age < 18;
      }
    });
    _updateData();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
      initialDatePickerMode: DatePickerMode.day, // Força modo calendário
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryOrange,
              onPrimary: Colors.white,
              onSurface: AppColors.secondary,
              surface: Colors.white,
            ),
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: AppColors.primaryOrange,
              headerForegroundColor: Colors.white,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              headerHeadlineStyle: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.normal,
              ),
              headerHelpStyle: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              weekdayStyle: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppColors.secondary;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primaryOrange;
                }
                return Colors.transparent;
              }),
              todayForegroundColor: WidgetStateProperty.all(
                AppColors.primaryOrange,
              ),
              todayBackgroundColor: WidgetStateProperty.all(Colors.transparent),
              dayStyle: const TextStyle(
                color: AppColors.secondary,
                fontSize: 14,
              ),
              yearStyle: const TextStyle(
                color: AppColors.secondary,
                fontSize: 16,
              ),
              inputDecorationTheme: const InputDecorationTheme(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      _setSelectedDate(date);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationBloc, registration_states.RegistrationState>(
      builder: (context, state) {
        // Usar validação local em vez da do BLoC
        final isValid = _isFormValid();

        // Calcular etapas usando o helper
        final int internalStep;
        if (state is registration_states.RegistrationStep && 
            state.userType == registration_states.UserType.personalTrainer) {
          internalStep = 2; // Para Personal, Dados Pessoais é o segundo passo (após CREF)
        } else {
          internalStep = 1; // Para Estudante, Dados Pessoais é o primeiro passo
        }

        final stepInfo = RegistrationStepsHelper.getStepInfo(
          internalStep,
          state is registration_states.RegistrationStep
              ? state.userType
              : registration_states.UserType.student,
          _selectedDate != null && _calculateAge(_selectedDate!) < 18,
        );

        return Column(
          children: [
            // Barra de progresso
            RegistrationProgressBar(
              currentStep: widget.customCurrentStep ?? stepInfo.displayStep,
              totalSteps: widget.customTotalSteps ?? stepInfo.totalSteps,
            ),

            const SizedBox(height: 32),

            // Título e subtítulo centralizados
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Dados pessoais',
                      style: AppTextStyles.h6Semibold.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Vamos começar com suas informações básicas',
                      style: AppTextStyles.paragraph.copyWith(
                        color: AppColors.secondaryDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Formulário
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Nome e Sobrenome
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nome',
                                style: AppTextStyles.paragraph.copyWith(
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _firstNameController,
                                placeholder: '',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sobrenome',
                                style: AppTextStyles.paragraph.copyWith(
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _lastNameController,
                                placeholder: '',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Data de nascimento
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data de nascimento',
                          style: AppTextStyles.paragraph.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF42464D),
                              width: 0.5,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: _selectDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _dateController,
                                style: AppTextStyles.paragraph.copyWith(
                                  color: const Color(0xFF2D3748),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Selecione a data',
                                  hintStyle: AppTextStyles.paragraph.copyWith(
                                    color: const Color(
                                      0xFF9CA3AF,
                                    ), // Tom de cinza mais claro
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                  border: InputBorder.none,
                                  suffixIcon: const Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Checkbox para menores de idade
                    if (_isMinor) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryOrange.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Como você é menor de 18 anos, precisamos da autorização de um responsável.',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.secondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: _hasGuardianAuthorization,
                                  onChanged: (value) {
                                    setState(() {
                                      _hasGuardianAuthorization =
                                          value ?? false;
                                    });
                                    _updateData();
                                  },
                                  activeColor: AppColors.primaryOrange,
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _hasGuardianAuthorization =
                                            !_hasGuardianAuthorization;
                                      });
                                      _updateData();
                                    },
                                    child: Text(
                                      'Tenho autorização do meu responsável',
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 24,
                    ), // Espaçamento extra no final do scroll
                  ],
                ),
              ),
            ),

            // Botão fixo na parte inferior
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isValid
                        ? () {
                            // Atualizar os dados no BLoC antes de avançar
                            context.read<RegistrationBloc>().add(
                              registration_events.UpdatePersonalDataAndNext(
                                firstName: _firstNameController.text,
                                lastName: _lastNameController.text,
                                birthDate: _selectedDate,
                                isMinor: _isMinor,
                                hasGuardianAuthorization:
                                    _hasGuardianAuthorization,
                              ),
                            );

                            // Pequeno delay para garantir que o estado foi atualizado
                            Future.delayed(
                              const Duration(milliseconds: 100),
                              () {
                                context.read<RegistrationBloc>().add(
                                  const registration_events.NextStep(),
                                );
                              },
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isValid
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
                      style: AppTextStyles.paragraph.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
