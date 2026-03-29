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

/// Primeira etapa: Validação do CREF
class CrefStep extends StatefulWidget {
  final int? customCurrentStep;
  final int? customTotalSteps;

  const CrefStep({
    super.key,
    this.customCurrentStep,
    this.customTotalSteps,
  });

  @override
  State<CrefStep> createState() => _CrefStepState();
}

class _CrefStepState extends State<CrefStep> {
  final _ufController = TextEditingController();
  final _crefNumberController = TextEditingController();
  String? _crefPhotoPath;
  UploadResponse? _crefUpload;

  @override
  void initState() {
    super.initState();
    _ufController.addListener(_updateData);
    _crefNumberController.addListener(_updateData);
  }

  @override
  void dispose() {
    _ufController.dispose();
    _crefNumberController.dispose();
    super.dispose();
  }

  void _updateData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uf = _ufController.text.toUpperCase();
      final crefNumber = _crefNumberController.text;
      final cref = uf.isNotEmpty && crefNumber.isNotEmpty 
          ? '$uf-$crefNumber' 
          : '';

      context.read<RegistrationBloc>().add(
        registration_events.UpdateCref(
          cref: cref,
          crefPhotoPath: _crefPhotoPath,
          crefUpload: _crefUpload,
        ),
      );
    });
  }

  void _validateCref() {
    final uf = _ufController.text.toUpperCase();
    final crefNumber = _crefNumberController.text;
    final cref = uf.isNotEmpty && crefNumber.isNotEmpty 
        ? '$uf-$crefNumber' 
        : '';

    if (cref.isNotEmpty) {
      context.read<RegistrationBloc>().add(
        registration_events.ValidateCref(cref),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationBloc, registration_states.RegistrationState>(
      builder: (context, state) {
        final registrationState = state is registration_states.RegistrationStep
            ? state
            : null;

        // Calcular etapas usando o helper
        final stepInfo = RegistrationStepsHelper.getStepInfo(
          1, // CREF é sempre o primeiro passo para Personal
          registration_states.UserType.personalTrainer,
          false,
        );

        return Column(
          children: [
            // Barra de progresso
            RegistrationProgressBar(
              currentStep: widget.customCurrentStep ?? stepInfo.displayStep,
              totalSteps: widget.customTotalSteps ?? stepInfo.totalSteps,
            ),

            // Mensagem de erro da validação CREF
            if (registrationState?.crefValidationError != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        registrationState!.crefValidationError!,
                        style: AppTextStyles.small.copyWith(
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Mensagem de sucesso da validação CREF
            if (registrationState?.isCrefValid == true && registrationState?.crefValidationError == null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'CREF validado com sucesso!',
                        style: AppTextStyles.small.copyWith(
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Conteúdo principal com scroll
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Espaço para centralizar o título
                    const SizedBox(height: 40),
                    
                    // Título centralizado
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            'Validação CREF',
                            style: AppTextStyles.h6Semibold.copyWith(
                              color: AppColors.secondary,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Informe seu número do CREF para validação profissional',
                            style: AppTextStyles.paragraph.copyWith(
                              color: AppColors.secondaryDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Formulário
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                children: [
                  // Número do CREF
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Número do CREF',
                        style: AppTextStyles.paragraph.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Campo UF (pequeno e quadrado)
                          Container(
                            width: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F3F3),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF42464D),
                                width: 0.5,
                              ),
                            ),
                            child: TextFormField(
                              controller: _ufController,
                              keyboardType: TextInputType.text,
                              textAlign: TextAlign.center,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Z]'),
                                ),
                                LengthLimitingTextInputFormatter(2),
                              ],
                              style: AppTextStyles.paragraph.copyWith(
                                color: const Color(0xFF2D3748),
                              ),
                              decoration: InputDecoration(
                                hintText: 'UF',
                                hintStyle: AppTextStyles.paragraph.copyWith(
                                  color: const Color(0xFF9CA3AF),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 18,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                          // Hífen
                          Text(
                            '-',
                            style: AppTextStyles.paragraph.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                          // Campo número do CREF (maior)
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F3F3),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFF42464D),
                                  width: 0.5,
                                ),
                              ),
                              child: TextFormField(
                                controller: _crefNumberController,
                                keyboardType: TextInputType.text,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9A-Z]'),
                                  ),
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                style: AppTextStyles.paragraph.copyWith(
                                  color: const Color(0xFF2D3748),
                                ),
                                decoration: InputDecoration(
                                  hintText: '123456',
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
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Upload da foto da carteirinha CREF
                  ImageUploadWidget(
                    title: 'Foto da carteirinha CREF',
                    description: 'Tire uma foto clara da frente da sua carteirinha do CREF. Certifique-se de que o número e dados estejam legíveis.',
                    uploadType: 'cref',
                    currentUpload: _crefUpload,
                    onUploadSuccess: (uploadResponse) {
                      setState(() {
                        _crefUpload = uploadResponse;
                        _crefPhotoPath = uploadResponse.url; // Para compatibilidade
                      });
                      _updateData();
                    },
                    onUploadError: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro no upload do CREF: $error'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Informação sobre validação
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
                            'Apenas profissionais com bacharelado em Educação Física podem se cadastrar. Licenciaturas não são aceitas.',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Aviso Importante sobre Mercado Pago
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Atenção: Para receber pagamentos na plataforma, é obrigatório possuir uma conta no Mercado Pago. O repasse será feito para a conta associada ao seu CPF/E-mail.',
                            style: AppTextStyles.small.copyWith(
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24), // Espaço extra no final
                ],
              ),
                    ),
                  ],
                ),
              ),
            ),

            // Botões fixos na parte inferior
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Botão Voltar
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
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

                    // Botão Validar CREF
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: registrationState?.isCrefValidating == true || registrationState?.isCrefValid == true
                            ? null
                            : () {
                                // Validar CREF
                                _validateCref();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: registrationState?.isCrefValidating == true
                              ? AppColors.secondaryDark.withValues(alpha: 0.3)
                              : registrationState?.isCrefValid == true
                                  ? AppColors.primaryOrange
                                  : AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: registrationState?.isCrefValidating == true
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Validando...',
                                    style: AppTextStyles.paragraph.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : registrationState?.isCrefValid == true
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Validado! Avançando...',
                                        style: AppTextStyles.paragraph.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Validar CREF',
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
