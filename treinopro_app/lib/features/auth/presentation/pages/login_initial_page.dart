import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/helpers/status_bar_helper.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../bloc/login_initial_bloc.dart';
import '../bloc/login_initial_event.dart';
import '../bloc/login_initial_state.dart';
import '../bloc/profile_selection_bloc.dart';
import '../widgets/custom_button.dart';
import '../widgets/treino_pro_logo_variant.dart';
import '../../../../core/widgets/animation_primer.dart';
import '../../../../core/services/first_animation_fix.dart';
import '../../../../core/services/animation_preloader.dart';
import '../../../../core/services/transition_optimizer.dart';
import '../../../../core/services/app_permissions_service.dart';
import 'login_page.dart';
import 'profile_selection_page.dart';

/// Página de login inicial seguindo exatamente o design do Figma
class LoginInitialPage extends StatefulWidget {
  const LoginInitialPage({super.key});

  @override
  State<LoginInitialPage> createState() => _LoginInitialPageState();
}

class _LoginInitialPageState extends State<LoginInitialPage> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // Define ícones brancos para o login inicial (fundo escuro)
    StatusBarHelper.setLightStatusBar();

    // Pré-carrega animações logo após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _preloadAnimations();
      }
    });
    
    // ✅ Solicitar permissões obrigatórias quando a tela de login carregar
    // Isso acontece após a splash screen, na tela inicial de login
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // Aguardar um pouco para garantir que a tela está totalmente carregada
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await AppPermissionsService.requestAllPermissions(context, isRequired: true);
        }
      }
    });
  }

  /// Pré-carrega animações para garantir transições suaves
  Future<void> _preloadAnimations() async {
    try {
      debugPrint('🎬 LoginInitialPage: Iniciando pré-carregamento...');
      
      // Executa otimizações em paralelo (igual ao splash)
      await Future.wait([
        FirstAnimationFix().fixFirstAnimation(context),
        AnimationPreloader().preloadAnimations(context),
        TransitionOptimizer().optimizeTransitions(),
      ]);

      debugPrint('✅ LoginInitialPage: Pré-carregamento concluído');
    } catch (e) {
      debugPrint('⚠️ LoginInitialPage: Erro no pré-carregamento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      isDarkBackground: true, // LoginInitial tem fundo escuro
      child: BlocListener<LoginInitialBloc, LoginInitialState>(
        listener: (context, state) {
          if (state is NavigateToSignUpState) {
            _navigateToSignUp(context);
          } else if (state is NavigateToLoginState) {
            _navigateToLogin(context);
          } else if (state is OpenTermsState) {
            _openTermsOfUse(context);
          } else if (state is LoginInitialError) {
            _showErrorSnackBar(context, state.message);
          }
        },
        child: AnimationPrimer(
          child: Scaffold(
            body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              // Imagem de fundo com overlay conforme Figma
              image: DecorationImage(
                image: AssetImage(AppAssets.loginBackground),
                fit: BoxFit.cover,
                colorFilter: const ColorFilter.mode(
                  Color(
                    0xCC0F131A,
                  ), // #0F131A com 80% de opacidade (0xCC = 204/255 ≈ 80%)
                  BlendMode.srcOver,
                ),
                onError: (exception, stackTrace) {
                  // Debug: caso a imagem não carregue
                  debugPrint('Erro ao carregar imagem: $exception');
                },
              ),
              // Fallback: gradiente caso a imagem não carregue
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.background, Color(0xFF1A1F2E)],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Conteúdo principal centralizado
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          const TreinoProLogoVariant(),
                          const SizedBox(height: 8),
                          Text(
                            'Você escolhe. A gente conecta.',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 48),

                          // Botões de ação
                          Column(
                            children: [
                              BlocBuilder<LoginInitialBloc, LoginInitialState>(
                                builder: (context, state) {
                                  return CustomButton(
                                    text: 'Começar agora',
                                    isPrimary: true,
                                    onPressed: () {
                                      context.read<LoginInitialBloc>().add(
                                        const NavigateToSignUp(),
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              BlocBuilder<LoginInitialBloc, LoginInitialState>(
                                builder: (context, state) {
                                  return CustomButton(
                                    text: 'Já tenho conta',
                                    isPrimary: false,
                                    onPressed: () {
                                      context.read<LoginInitialBloc>().add(
                                        const NavigateToLogin(),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Termos de uso e política de privacidade na parte inferior
                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                        onTap: () {
                          context.read<LoginInitialBloc>().add(
                            const OpenTermsOfUse(),
                          );
                        },
                        child: Text(
                                  'Termos de uso',
                                  style: AppTextStyles.helpText.copyWith(
                                    color: AppColors.primaryOrange,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              Text(
                                ' e ',
                          style: AppTextStyles.helpText,
                              ),
                              GestureDetector(
                                onTap: () {
                                  _showPrivacyPolicy(context);
                                },
                                child: Text(
                                  'política de privacidade',
                                  style: AppTextStyles.helpText.copyWith(
                                    color: AppColors.primaryOrange,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ), // fecha Scaffold
        ), // fecha AnimationPrimer
      ), // fecha BlocListener
    ); // fecha StatusBarWrapper
  }

  /// Navega para a tela de cadastro
  void _navigateToSignUp(BuildContext context) async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    // Preparar status bar para tela clara
    StatusBarHelper.setDarkStatusBar();

    // Otimizar transição antes da navegação
    await TransitionOptimizer().optimizeForNavigation();

    if (!mounted) return;

    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                BlocProvider(
                  create: (context) => ProfileSelectionBloc(),
                  child: const ProfileSelectionPage(),
                ),
            transitionDuration: const Duration(milliseconds: 450),
            opaque: false, // Mantém a tela anterior visível durante a transição
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve =
                      Curves.easeInOutCubic; // Curva mais suave e consistente

                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: Container(
                      color: const Color(0xFFFCFDFE), // Fundo da nova tela
                      child: child,
                    ),
                  );
                },
          ),
        )
        .then((_) {
          // Restaurar status bar ao voltar para tela escura
          if (mounted) {
            StatusBarHelper.setLightStatusBar();
            setState(() {
              _isNavigating = false;
            });
          }
        });
  }

  /// Navega para a tela de login
  void _navigateToLogin(BuildContext context) async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    try {
      debugPrint('🎯 Preparando navegação para LoginPage...');
      
      // Preparar status bar para tela clara
      StatusBarHelper.setDarkStatusBar();

      // Aplicar otimizações ANTES da navegação (como no splash)
      await Future.wait([
        TransitionOptimizer().optimizeForNavigation(),
        // Garantir que as animações estão pré-carregadas
        AnimationPreloader().preloadAnimations(context),
      ]);

      debugPrint('✅ Otimizações aplicadas, iniciando navegação...');
    } catch (e) {
      debugPrint('⚠️ Erro nas otimizações: $e');
    }

    if (!mounted) return;

    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginPage(),
            transitionDuration: const Duration(milliseconds: 450),
            opaque: false, // Mantém a tela anterior visível durante a transição
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve =
                      Curves.easeInOutCubic; // Curva mais suave e consistente

                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: Container(
                      color: const Color(0xFFFCFDFE), // Fundo da nova tela
                      child: child,
                    ),
                  );
                },
          ),
        )
        .then((_) {
          // Restaurar status bar ao voltar para tela escura
          if (mounted) {
            StatusBarHelper.setLightStatusBar();
            setState(() {
              _isNavigating = false;
            });
          }
        });
  }

  /// Abre os termos de uso
  void _openTermsOfUse(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Text(
          'Termos de Uso',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.h6Semibold.copyWith(
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _section('1. ACEITAÇÃO DOS TERMOS', 'Ao acessar, se cadastrar ou utilizar o aplicativo TreinoPro, você declara ter lido, compreendido e concordado integralmente com os presentes Termos de Uso, bem como com a Política de Privacidade associada.\nEstes termos constituem um contrato eletrônico com validade jurídica plena, firmado mediante aceite digital, nos termos da legislação brasileira. Caso o usuário seja menor de idade, declara também que obteve autorização expressa de seu responsável legal, conforme solicitado no momento do cadastro.\n\nO TreinoPro é uma plataforma de intermediação tecnológica e não substitui acompanhamento médico ou nutricional. Recomenda-se que todo usuário consulte profissionais de saúde antes de iniciar qualquer atividade física.'),
                          _section('2. SOBRE O APLICATIVO', 'O TreinoPro conecta alunos a profissionais de educação física (personal trainers), permitindo a marcação e pagamento de aulas presenciais.\nO funcionamento é baseado em propostas, aceite e agendamento.\nA plataforma não estabelece vínculo empregatício ou societário entre os usuários.'),
                          _section('3. REGRAS PARA USUÁRIOS (ALUNOS)', '· Uso permitido a maiores de 18 anos ou menores com autorização formal dos responsáveis legais.\n· Caso o usuário seja menor de 18 anos, deverá informar dados do responsável, que será notificado para confirmar a autorização.\n· Ao enviar uma proposta de aula, o valor poderá ser pré-autorizado e efetivado após o aceite de um profissional.\n· A proposta pode ser cancelada sem custos enquanto estiver pendente (sem aceite).\n· Cancelamentos com menos de 2 (duas) horas de antecedência não darão direito a reembolso, salvo disposição específica na Seção 5 e na Seção 13.\n· O aluno é responsável por comparecer no local, data e horário combinados, utilizando sempre o chat do aplicativo como canal oficial de comunicação.\n· Em disputas de horário, prevalecerá sempre o relógio oficial do servidor da TreinoPro.\n· Em caso de divergência sobre comparecimento, aplica-se o procedimento da Seção 13.'),
                          _section('4. REGRAS PARA PROFISSIONAIS (PERSONAL TRAINERS)', '· É obrigatório possuir registro válido no CREF e da natureza BACHAREL.\n· O profissional deve marcar disponibilidade, selecionar academia onde deseja atuar e limitar um raio de atuação.\n· Ao aceitar uma proposta, assume o compromisso de comparecimento no local, data e horário combinados.\n· Cancelamentos não justificados ou ausência podem gerar penalidades, conforme Seção 6 e Seção 13.\n· O valor da aula será liberado após finalização no aplicativo e inexistência de disputa ativa.\n· Toda comunicação deve ocorrer exclusivamente pelo chat do aplicativo.\n· É proibido trocar ou compartilhar contatos (telefone, e-mail, redes sociais etc.) no ambiente do aplicativo.\n· O não cumprimento dessa regra poderá resultar em advertência, suspensão temporária ou banimento definitivo da plataforma.\n· Responsabilidade exclusiva sobre taxas cobradas por academias.'),
                          _section('5. PAGAMENTOS, COMISSÕES E TAXAS', '· Pagamentos processados por parceiros homologados pela plataforma, como Stripe.\n· A plataforma retém automaticamente uma comissão percentual definida por split, sendo cada parte responsável pela taxa aplicável conforme a política vigente.\n· O percentual da comissão poderá variar, sendo sempre informado de forma clara no aplicativo antes da contratação.\n· Valores podem ser retidos em custódia em disputas (Seção 13).\n· Os saques do saldo do profissional podem ser solicitados a qualquer momento pelo aplicativo.\n· O processamento poderá levar até 1 (um) dia útil para análise e liberação.\n· Eventuais taxas de saque, quando aplicáveis, serão informadas de forma clara no aplicativo antes da confirmação.\n· Cancelamentos realizados com menos de 2 (duas) horas de antecedência poderão gerar retenção de parte do valor ou taxa fixa, informada no aplicativo.\n· Em caso de falhas técnicas comprovadas (ex.: erro de cobrança duplicada), haverá reembolso integral.'),
                          _section('6. AVALIAÇÕES, CONDUTA E PENALIDADES', '· Após cada aula, alunos e profissionais deverão se avaliar mutuamente.\n· Comentários ofensivos, discriminatórios ou abusivos poderão ser removidos pela plataforma.\n· Usuários podem solicitar revisão de avaliações por meio do canal oficial.\n· Ausências recorrentes, falsidade de informações ou descumprimento das regras podem gerar advertência, redução de visibilidade, suspensão ou banimento.'),
                          _section('7. RESPONSABILIDADES DA PLATAFORMA', '· O TreinoPro é intermediadora tecnológica e não garante resultados de saúde.\n· Não se responsabiliza por qualidade técnica das aulas, conduta de usuários, taxas de academias ou informações incorretas fornecidas.\n· O plataforma poderá ficar indisponível temporariamente devido a manutenção, falhas de sistema ou força maior.\n· O TreinoPro não se responsabiliza por perdas ou danos decorrentes dessas situações, exceto em casos de erro comprovado de cobrança.'),
                          _section('8. PROPRIEDADE INTELECTUAL', '· Todo o conteúdo da plataforma é de titularidade exclusiva do TreinoPro, sendo vedada sua cópia, modificação ou distribuição sem autorização prévia por escrito.'),
                          _section('9. PRIVACIDADE E DADOS PESSOAIS', '· Dados tratados conforme a LGPD (Lei 13.709/18).\n· Coleta de dados para operação da plataforma, pagamento, comunicação, segurança e melhorias.\n· O usuário pode solicitar correção, acesso, exclusão ou portabilidade de seus dados em até 15 (quinze) dias pelo canal oficial.\n· Armazenamento poderá ocorrer em servidores de terceiros (ex.: AWS, Firebase), inclusive fora do Brasil, com garantias contratuais de proteção internacional de dados.\n· Evidências enviadas em disputas (Seção 13) serão usadas exclusivamente para arbitragem e armazenadas apenas pelo prazo mínimo necessário.'),
                          _section('10. MODIFICAÇÕES DOS TERMOS', '· Estes Termos poderão ser alterados a qualquer momento.\n· O usuário será notificado no app ou por e-mail.\n· O uso contínuo dos serviços após a alteração será considerado aceite.'),
                          _section('11. LEGISLAÇÃO APLICÁVEL E FORO', '· Estes termos são regidos pelas leis brasileiras.\n· Fica eleito o foro da comarca de Niterói/RJ para dirimir eventuais disputas.'),
                          _section('12. CONTATO', 'Dúvidas, sugestões ou denúncias:\n📧 contato@treinopro.com'),
                          _section('13. AUSÊNCIA, CUSTÓDIA E DISPUTAS', '· Aula é considerada iniciada apenas quando o personal aciona "Iniciar aula" e o aluno confirma no aplicativo.\n· Se uma das partes marcar "não compareceu", o valor ficará em custódia por até 48h.\n· Ambas as partes terão 24h para enviar evidências ao e-mail oficial (contato@treinopro.com).\n· Exemplos de evidências:\n  · Check-in em academia\n  · Foto no local com horário visível\n  · Prints do chat oficial\n· O TreinoPro poderá decidir por:\n  · Liberar pagamento ao personal\n  · Reembolsar integralmente o aluno\n  · Aplicar penalidades por má-fé ou reincidência\n· Ausência confirmada do aluno: valor não reembolsado, repassado ao personal e à plataforma.\n· Ausência confirmada do personal: reembolso integral ao aluno.\n· Se não houver evidências suficientes, a decisão poderá ser automática conforme política interna (benefício da dúvida a quem negou ausência ou análise de quem enviou provas).\n· A decisão do TreinoPro será definitiva e inquestionável, constituindo arbitragem privada aceita pelo usuário.\n· As evidências serão utilizadas exclusivamente para arbitragem e tratadas conforme a LGPD.'),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Abre a política de privacidade
  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
            child: Text(
                            'Política de Privacidade',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.h6Semibold.copyWith(
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Última atualização: 27 de Agosto de 2025',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Esta Política de Privacidade descreve como o TreinoPro coleta, utiliza, compartilha e protege os dados pessoais dos usuários (alunos e profissionais) que utilizam nossa plataforma.\n\nAo se cadastrar e utilizar o aplicativo TreinoPro, você declara estar ciente e concorda com os termos abaixo.\nEsta política está em conformidade com a Lei Geral de Proteção de Dados (LGPD) – Lei nº 13.709/2018.',
              style: AppTextStyles.small.copyWith(
                              color: AppColors.secondary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _section('RESUMO RÁPIDO (TL;DR)', '· Coletamos dados pessoais para operar o app, realizar pagamentos, garantir segurança e melhorar sua experiência.\n· Não vendemos seus dados. Compartilhamos apenas com parceiros essenciais.\n· Você tem total controle sobre suas informações: pode acessá-las, corrigi-las ou solicitar exclusão.\n· Menores de idade precisam de autorização do responsável.\n· Armazenamos os dados de forma segura e criptografada.\n· Você pode revogar o uso dos dados ou tirar dúvidas pelo e-mail: contato@treinopro.com'),
                          _section('1. QUEM SOMOS', 'O TreinoPro é um aplicativo que conecta alunos a profissionais de educação física para a marcação e realização de aulas presenciais.\nAtuamos como intermediador digital, oferecendo um sistema de propostas, aceite, chat e pagamento.'),
                          _section('2. DADOS COLETADOS', 'Coletamos os seguintes tipos de dados:'),
                          _section('Durante o cadastro', '· Nome completo\n· Data de nascimento\n· Documento de identidade (RG ou CPF)\n· E-mail\n· Nome e e-mail do responsável legal (para menores de idade)\n· Número do CREF (para profissionais)'),
                          _section('Durante o uso da plataforma', '· Propostas de aula (local, horário, valor)\n· Mensagens via chat interno\n· Avaliações enviadas e recebidas\n· Histórico de aulas\n· Dados de gamificação e XP'),
                          _section('Dados financeiros', '· Informações do cartão de crédito (armazenadas via gateway seguro)\n· Valores pagos e recebidos\n· Dados bancários para saques\n· Notas fiscais e comprovantes'),
                          _section('Dados técnicos', '· Endereço IP\n· Tipo de dispositivo e sistema operacional\n· Cookies e identificadores únicos\n· Permissões de localização (se autorizadas)\n· Logs de uso (horários, ações, erros)'),
                          _section('3. BASE LEGAL PARA O TRATAMENTO DOS DADOS', 'Coletamos e tratamos os dados com base nas seguintes bases legais da LGPD:\n· Execução de contrato: para viabilizar aulas, pagamentos e comunicação entre usuários\n· Consentimento: para uso de localização, marketing e autorização de menores\n· Legítimo interesse: para melhorar a experiência de uso, segurança e gamificação\n· Obrigação legal: para emissão de notas fiscais e cumprimento de normas regulatórias'),
                          _section('4. USO DOS DADOS', 'Utilizamos seus dados para:\n· Operar e melhorar a plataforma\n· Realizar intermediações de aula e pagamento\n· Garantir segurança das transações e interações\n· Executar o sistema de XP, avaliações e conquistas\n· Enviar notificações e comunicados importantes\n· Prevenir fraudes e abusos\n· Cumprir obrigações fiscais e legais\n· Enviar conteúdos promocionais ou educativos (com seu consentimento)'),
                          _section('5. USO POR MENORES DE IDADE', 'O TreinoPro pode ser utilizado por menores de 18 anos somente com autorização formal do responsável legal.\n\nSe detectarmos idade inferior a 18 anos no momento do cadastro, solicitamos:\n✅ Nome completo do responsável\n✅ E-mail do responsável\n✅ Confirmação eletrônica da autorização via e-mail\n\nEsses dados são usados exclusivamente para validação da autorização, em conformidade com a legislação brasileira.'),
                          _section('6. COMPARTILHAMENTO DE DADOS', 'Nunca vendemos seus dados. Compartilhamos apenas com:\n🏦 Gateways de pagamento homologados (ex: Stripe)\n☁️ Provedores de hospedagem e armazenamento (ex: AWS, Google Cloud)\n📬 Ferramentas de envio de e-mail e notificações push\n🔍 Serviços de verificação de identidade, quando aplicável\n\nTodos os parceiros seguem contratos com cláusulas de proteção de dados compatíveis com a LGPD.'),
                          _section('7. ARMAZENAMENTO E SEGURANÇA', 'Seus dados são armazenados em servidores seguros, com:\n🔐 Criptografia em repouso e em trânsito\n🔐 Controle de acesso interno com níveis de permissão\n🔄 Backups automáticos e regulares\n👁️ Monitoramento e alertas contra acessos indevidos\n📂 Logs armazenados por até 12 meses\n\nUtilizamos datacenters localizados no Brasil ou com garantias de conformidade com a legislação nacional.'),
                          _section('8. DIREITOS DOS USUÁRIOS', 'Você tem direito de:\n📥 Acessar seus dados pessoais\n✏️ Corrigir dados incompletos ou desatualizados\n🧹 Solicitar anonimização ou exclusão (exceto quando há obrigação legal de retenção)\n🔄 Solicitar portabilidade dos dados\n❌ Revogar consentimentos previamente concedidos\n\nPara exercer seus direitos, envie um e-mail para: 📧 contato@treinopro.com'),
                          _section('9. RETENÇÃO DOS DADOS', 'Mantemos seus dados:\n· Enquanto durar sua relação com a plataforma\n· Pelo tempo necessário para obrigações legais e fiscais\n· Ou até que você solicite a exclusão, se permitido'),
                          _section('10. COMUNICAÇÃO E MARKETING', 'Com sua autorização, poderemos:\n· Enviar newsletters, campanhas, convites e conteúdos relacionados ao seu perfil (aluno ou personal)\n· Personalizar sua experiência com base no seu uso e comportamento no app\n\nVocê poderá cancelar o recebimento a qualquer momento pelos próprios e-mails ou nas configurações do aplicativo.'),
                          _section('11. ALTERAÇÕES NESTA POLÍTICA', 'A Política de Privacidade poderá ser atualizada. Informaremos você por:\n· Notificação no aplicativo\n· E-mail cadastrado\n\nO uso contínuo do TreinoPro após a atualização será considerado aceitação dos novos termos.'),
                          _section('12. CONTATO', 'Dúvidas, sugestões ou solicitações:\n📧 contato@treinopro.com'),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Widget helper para seções dos termos
  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.paragraph.copyWith(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppTextStyles.small.copyWith(
              color: AppColors.secondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Mostra snackbar de erro
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
