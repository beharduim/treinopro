import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../bloc/registration_bloc.dart';
import '../../bloc/registration_event.dart' as registration_events;
import '../../bloc/registration_state.dart' as registration_states;
import '../../widgets/registration_progress_bar.dart';
import '../../utils/registration_steps_helper.dart';
import '../../widgets/image_upload_widget.dart';
import '../../../data/models/upload_response.dart';

/// Formatador inteligente que detecta CPF ou CNH automaticamente
class DocumentInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limita o máximo de caracteres
    if (text.length > 11) {
      return oldValue;
    }

    String formattedText = text;
    int selectionIndex = newValue.selection.end;

    // Aplicar máscara apenas se tiver menos de 11 dígitos (presumindo CPF)
    if (text.length < 11) {
      // Aplicar máscara de CPF progressivamente para menos de 11 dígitos
      if (text.length >= 4) {
        formattedText = '${text.substring(0, 3)}.${text.substring(3)}';
        if (selectionIndex > 3) selectionIndex++;
      }
      if (text.length >= 7) {
        formattedText =
            '${formattedText.substring(0, 7)}.${formattedText.substring(7)}';
        if (selectionIndex > 6) selectionIndex++;
      }
      if (text.length >= 10) {
        formattedText =
            '${formattedText.substring(0, 11)}-${formattedText.substring(11)}';
        if (selectionIndex > 9) selectionIndex++;
      }
    } else if (text.length == 11) {
      // 11 dígitos: verificar se é CPF baseado na presença de máscara no input anterior
      if (oldValue.text.contains('.') || oldValue.text.contains('-')) {
        // Continuar formatação de CPF
        formattedText =
            '${text.substring(0, 3)}.${text.substring(3, 6)}.${text.substring(6, 9)}-${text.substring(9)}';
        selectionIndex = formattedText.length;
      } else {
        // CNH: sem máscara
        formattedText = text;
        selectionIndex = text.length;
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

/// Terceira etapa: Documentos
class DocumentsStep extends StatefulWidget {
  final int? customCurrentStep;
  final int? customTotalSteps;
  final bool showButtons;

  const DocumentsStep({
    super.key,
    this.customCurrentStep,
    this.customTotalSteps,
    this.showButtons = true,
  });

  @override
  State<DocumentsStep> createState() => _DocumentsStepState();
}

class _DocumentsStepState extends State<DocumentsStep> {
  final _documentController = TextEditingController();
  String? _documentPhotoPath;
  UploadResponse? _documentUpload;
  bool _isMinor = false;
  String _selectedDocType = 'CPF'; // 'CPF' ou 'CNH'
  Timer? _debounceTimer; // Timer para validação de documento

  @override
  void initState() {
    super.initState();
    
    // Recuperar dados do BLoC
    final currentState = context.read<RegistrationBloc>().state;
    if (currentState is registration_states.RegistrationStep) {
      _documentController.text = currentState.document;
      _selectedDocType = currentState.documentType.isEmpty ? 'CPF' : currentState.documentType;
      _documentPhotoPath = currentState.documentPhotoPath;
      _documentUpload = currentState.documentUpload;
    }
    
    _documentController.addListener(_updateData);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _documentController.dispose();
    super.dispose();
  }

  void _updateData() {
    // Apenas fazer rebuild local, sem chamar o BLoC constantemente
    setState(() {
      // Forçar rebuild para validações visuais
    });

    // Cancelar timer anterior se existir
    _debounceTimer?.cancel();

    // Verificar documento duplicado após 800ms de inatividade
    final documentNumber = _documentController.text.trim();
    if (documentNumber.isNotEmpty && _isValidDocument(documentNumber)) {
      _debounceTimer = Timer(const Duration(milliseconds: 800), () {
        context.read<RegistrationBloc>().add(
          registration_events.CheckDocument(_selectedDocType, documentNumber),
        );
      });
    }
  }

  bool _isFormValid() {
    return _documentController.text.trim().isNotEmpty &&
        _isValidDocument(_documentController.text.trim()) &&
        _documentUpload != null;
  }

  bool _isValidDocument(String document) {
    final cleanDocument = document.replaceAll(RegExp(r'[^0-9]'), '');

    if (_selectedDocType == 'CPF') {
      return _isValidCPF(cleanDocument);
    } else if (_selectedDocType == 'CNH') {
      return _isValidCNH(cleanDocument);
    }
    return false;
  }

  bool _isValidCPF(String cpf) {
    if (cpf.length != 11) return false;
    if (cpf.split('').every((d) => d == cpf[0])) return false;

    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int dv1 = 11 - (sum % 11);
    if (dv1 >= 10) dv1 = 0;
    if (int.parse(cpf[9]) != dv1) return false;

    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int dv2 = 11 - (sum % 11);
    if (dv2 >= 10) dv2 = 0;
    return int.parse(cpf[10]) == dv2;
  }

  bool _isValidCNH(String cnh) {
    if (cnh.length != 11) return false;
    if (cnh.split('').every((d) => d == cnh[0])) return false;

    final digits = cnh.split('').map(int.parse).toList();

    int sum1 = 0;
    for (int i = 0; i < 9; i++) {
      sum1 += digits[i] * (9 - i);
    }
    int resto1 = sum1 % 11;
    int desc = 0;
    int dv1;
    if (resto1 > 9) {
      dv1 = 0;
      desc = 2;
    } else {
      dv1 = resto1;
    }

    int sum2 = 0;
    for (int i = 0; i < 9; i++) {
      sum2 += digits[i] * (1 + i);
    }
    int resto2 = sum2 % 11;
    int dv2 = resto2 - desc;
    if (dv2 < 0 || dv2 > 9) dv2 = 0;

    return digits[9] == dv1 && digits[10] == dv2;
  }


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationBloc, registration_states.RegistrationState>(
      builder: (context, state) {
        // Usar validação local em vez da do BLoC
        final isFormValid = _isFormValid();

        // Verificar se há erro de documento duplicado do BLoC
        final hasDocumentError = state is registration_states.RegistrationStep &&
                                  state.documentExistsError != null;

        final isValid = isFormValid && !hasDocumentError;

        if (state is registration_states.RegistrationStep) {
          _isMinor = state.isMinor;
        }

        // Calcular etapas usando o helper
        late final StepInfo stepInfo;

        if (state is registration_states.RegistrationStep) {
          if (state.userType == registration_states.UserType.personalTrainer) {
            stepInfo = RegistrationStepsHelper.getStepInfo(3, state.userType, false);
          } else {
            // Estudante: maior = 3, menor = 4
            stepInfo = RegistrationStepsHelper.getStepInfo(_isMinor ? 4 : 3, state.userType, _isMinor);
          }
        } else {
          // Valores padrão
          stepInfo = RegistrationStepsHelper.getStepInfo(3, registration_states.UserType.student, _isMinor);
        }

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
                      'Documentos',
                      style: AppTextStyles.h6Semibold.copyWith(
                        color: AppColors.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Vamos verificar sua identidade',
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
                    // Seletor de tipo de documento
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tipo de documento',
                          style: AppTextStyles.paragraph.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDocType = 'CPF';
                                    _documentController.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedDocType == 'CPF'
                                        ? AppColors.primaryOrange.withValues(alpha: 0.15)
                                        : const Color(0xFFF3F3F3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _selectedDocType == 'CPF'
                                          ? AppColors.primaryOrange
                                          : const Color(0xFF42464D),
                                      width: _selectedDocType == 'CPF' ? 1.5 : 0.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'CPF',
                                      style: AppTextStyles.paragraph.copyWith(
                                        color: _selectedDocType == 'CPF'
                                            ? AppColors.primaryOrange
                                            : AppColors.secondary,
                                        fontWeight: _selectedDocType == 'CPF'
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDocType = 'CNH';
                                    _documentController.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedDocType == 'CNH'
                                        ? AppColors.primaryOrange.withValues(alpha: 0.15)
                                        : const Color(0xFFF3F3F3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _selectedDocType == 'CNH'
                                          ? AppColors.primaryOrange
                                          : const Color(0xFF42464D),
                                      width: _selectedDocType == 'CNH' ? 1.5 : 0.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'CNH',
                                      style: AppTextStyles.paragraph.copyWith(
                                        color: _selectedDocType == 'CNH'
                                            ? AppColors.primaryOrange
                                            : AppColors.secondary,
                                        fontWeight: _selectedDocType == 'CNH'
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Número do documento
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDocType == 'CPF' ? 'Número do CPF' : 'Número de registro da CNH',
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
                          child: TextFormField(
                            controller: _documentController,
                            keyboardType: TextInputType.number,
                            inputFormatters: _selectedDocType == 'CPF'
                                ? [
                                    FilteringTextInputFormatter.digitsOnly,
                                    DocumentInputFormatter(),
                                  ]
                                : [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(11),
                                  ],
                            style: AppTextStyles.paragraph.copyWith(
                              color: const Color(0xFF2D3748),
                            ),
                            decoration: InputDecoration(
                              hintText: _selectedDocType == 'CPF'
                                  ? 'Digite seu CPF (11 dígitos)'
                                  : 'Digite o número de registro da CNH',
                              hintStyle: AppTextStyles.paragraph.copyWith(
                                color: const Color(0xFF9CA3AF),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Mensagem de erro de validação do documento
                    if (_documentController.text.isNotEmpty && !_isValidDocument(_documentController.text.trim()))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _selectedDocType == 'CPF'
                              ? 'CPF inválido. Verifique os dígitos e tente novamente.'
                              : 'CNH inválida. Verifique o número de registro.',
                          style: AppTextStyles.small.copyWith(
                            color: Colors.red[700],
                          ),
                        ),
                      ),

                    // Mensagem de erro de documento duplicado (do BLoC)
                    BlocBuilder<RegistrationBloc, registration_states.RegistrationState>(
                      builder: (context, state) {
                        if (state is registration_states.RegistrationStep && state.documentExistsError != null) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              state.documentExistsError!,
                              style: AppTextStyles.small.copyWith(
                                color: Colors.red[700],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    const SizedBox(height: 24),

                    // Upload da foto do documento
                    ImageUploadWidget(
                      title: 'Foto do documento',
                      description: 'Tire uma foto clara do seu documento de identidade. Certifique-se de que todas as informações estejam legíveis.',
                      uploadType: 'document',
                      documentType: _selectedDocType,
                      currentUpload: _documentUpload,
                      onUploadSuccess: (uploadResponse) {
                        setState(() {
                          _documentUpload = uploadResponse;
                          _documentPhotoPath = uploadResponse.url; // Para compatibilidade
                        });
                        _updateData();
                      },
                      onUploadError: (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro no upload: $error'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Informação sobre a foto
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primaryOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Certifique-se de que a foto está nítida e todos os dados estão visíveis.',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ), // Espaçamento extra no final do scroll
                  ],
                ),
              ),
            ),

            // Botões fixos na parte inferior (condicionais)
            if (widget.showButtons)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Row(
                    children: [
                      // Botão Voltar
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            context.read<RegistrationBloc>().add(
                              const registration_events.PreviousStep(),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                            side: BorderSide(color: AppColors.secondary),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Voltar',
                            style: AppTextStyles.paragraph.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Botão Continuar
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isValid
                              ? () {
                                  // Atualizar os dados no BLoC antes de avançar
                                  context.read<RegistrationBloc>().add(
                                    registration_events.UpdateDocuments(
                                      document: _documentController.text,
                                      documentType: _selectedDocType,
                                      documentPhotoPath: _documentPhotoPath,
                                      documentUpload: _documentUpload,
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
                                : AppColors.secondaryDark.withValues(
                                    alpha: 0.3,
                                  ),
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
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
