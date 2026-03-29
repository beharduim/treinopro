import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/helpers/status_bar_helper.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../core/di/dependency_injection.dart';
import '../bloc/profile_selection_bloc.dart';
import '../bloc/profile_selection_event.dart';
import '../bloc/profile_selection_state.dart';
import '../bloc/registration_bloc.dart';
import '../widgets/profile_selection_card.dart';
import '../../domain/usecases/student_registration_usecases.dart';
import '../../domain/usecases/personal_registration_usecases.dart';
import '../../domain/usecases/validate_cref_usecase.dart';
import '../../domain/usecases/send_verification_code_usecase.dart';
import '../../domain/usecases/verify_code_usecase.dart';
import '../../domain/usecases/validate_email_usecase.dart';
import '../../domain/usecases/check_document_usecase.dart';
import '../../data/services/guardian_authorization_service.dart';
import 'student_registration_page.dart';
import 'personal_registration_page.dart';

/// Tela de seleção de perfil seguindo exatamente o design do Figma
class ProfileSelectionPage extends StatefulWidget {
  const ProfileSelectionPage({super.key});

  @override
  State<ProfileSelectionPage> createState() => _ProfileSelectionPageState();
}

class _ProfileSelectionPageState extends State<ProfileSelectionPage> {
  bool _isNavigating = false;
  RegistrationBloc? _registrationBloc;

  @override
  void initState() {
    super.initState();

    // Define ícones pretos para página clara
    StatusBarHelper.setDarkStatusBar();

    _registrationBloc = RegistrationBloc(
      studentRegistrationUseCase: sl<StudentRegistrationUseCase>(),
      personalRegistrationUseCase: sl<PersonalRegistrationUseCase>(),
      validateCrefUseCase: sl<ValidateCrefUseCase>(),
      sendVerificationCodeUseCase: sl<SendVerificationCodeUseCase>(),
      verifyCodeUseCase: sl<VerifyCodeUseCase>(),
      validateEmailUseCase: sl<ValidateEmailUseCase>(),
      checkDocumentUseCase: sl<CheckDocumentUseCase>(),
      guardianAuthorizationService: sl<GuardianAuthorizationService>(),
    );
  }

  @override
  void dispose() {
    _registrationBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      isDarkBackground: false, // Página clara, ícones pretos
      child: BlocListener<ProfileSelectionBloc, ProfileSelectionState>(
        listener: (context, state) {
          if (state is NavigateToStudentRegistration) {
            _navigateToStudentRegistration(context);
          } else if (state is NavigateToTrainerRegistration) {
            _navigateToTrainerRegistration(context);
          } else if (state is NavigateBackToInitial) {
            _navigateBack(context);
          } else if (state is ProfileSelectionError) {
            _showErrorSnackBar(context, state.message);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.loginBackground,
          body: SafeArea(
            child: Column(
              children: [
                // Header com apenas o botão de voltar
                _buildHeader(context),

                // Conteúdo centralizado verticalmente
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 36,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Título
                                _buildTitle(),

                                const SizedBox(height: 24),

                                // Texto descritivo
                                _buildDescriptionText(),

                                const SizedBox(height: 50),

                                // Cards de seleção
                                _buildProfileCards(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ), // fecha Scaffold
      ), // fecha BlocListener
    ); // fecha StatusBarWrapper
  }

  /// Constrói o header com botão voltar
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          // Botão de voltar
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                context.read<ProfileSelectionBloc>().add(const NavigateBack());
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.chevron_left,
                  color: AppColors.secondaryDark,
                  size: 32, // Mesmo tamanho da tela de login
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o título
  Widget _buildTitle() {
    return Text(
      'Escolha seu perfil',
      style: AppTextStyles.h6Semibold.copyWith(color: AppColors.secondary),
      textAlign: TextAlign.center,
    );
  }

  /// Constrói o texto descritivo
  Widget _buildDescriptionText() {
    return SizedBox(
      width: 380,
      child: Text(
        'Selecione uma opção para continuar\ncom o registro',
        style: AppTextStyles.paragraph.copyWith(color: AppColors.secondaryDark),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Constrói os cards de seleção de perfil
  Widget _buildProfileCards() {
    return Column(
      children: [
        // Card do Aluno
        BlocBuilder<ProfileSelectionBloc, ProfileSelectionState>(
          builder: (context, state) {
            final isLoading = state is ProfileSelectionLoading;

            return ProfileSelectionCard(
              imagePath: AppAssets.studentProfile,
              title: 'Sou aluno',
              description: 'Encontre personal trainers qualificados',
              onTap: isLoading
                  ? () {} // Desabilita se estiver carregando
                  : () {
                      if (!_isNavigating) {
                        context.read<ProfileSelectionBloc>().add(
                          const SelectStudentProfile(),
                        );
                      }
                    },
            );
          },
        ),

        const SizedBox(height: 24),

        // Card do Personal Trainer
        BlocBuilder<ProfileSelectionBloc, ProfileSelectionState>(
          builder: (context, state) {
            final isLoading = state is ProfileSelectionLoading;

            return ProfileSelectionCard(
              imagePath: AppAssets.trainerProfile,
              title: 'Sou personal formado',
              description: 'Conecte-se com alunos e ofereça seus serviços',
              onTap: isLoading
                  ? () {} // Desabilita se estiver carregando
                  : () {
                      if (!_isNavigating) {
                        context.read<ProfileSelectionBloc>().add(
                          const SelectTrainerProfile(),
                        );
                      }
                    },
            );
          },
        ),

        const SizedBox(height: 32),

        // Aviso importante para Personais
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
                  'Atenção Personal: Para receber pagamentos na plataforma, é obrigatório possuir uma conta no Mercado Pago. O repasse será feito para a conta associada ao seu CPF/E-mail de cadastro.',
                  style: AppTextStyles.small.copyWith(
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Navega para cadastro de aluno
  void _navigateToStudentRegistration(BuildContext context) {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const StudentRegistrationPage(),
          ),
        )
        .then((_) {
          setState(() {
            _isNavigating = false;
          });
        });
  }

  /// Navega para cadastro de personal trainer
  void _navigateToTrainerRegistration(BuildContext context) {
    if (_isNavigating || _registrationBloc == null) return;

    setState(() {
      _isNavigating = true;
    });

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: _registrationBloc!,
              child: const PersonalRegistrationPage(),
            ),
          ),
        )
        .then((_) {
          setState(() {
            _isNavigating = false;
          });
        });
  }

  /// Navega de volta para a tela inicial
  void _navigateBack(BuildContext context) {
    if (_isNavigating) return;

    Navigator.of(context).pop();
  }

  /// Mostra snackbar de erro
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
