import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../bloc/registration_bloc.dart';
import '../../bloc/registration_event.dart' as registration_events;
import '../../bloc/registration_state.dart' as registration_states;
import '../../widgets/registration_progress_bar.dart';
import '../../utils/registration_steps_helper.dart';

/// Sexta etapa: Senha
class PasswordStep extends StatefulWidget {
  final int? customCurrentStep;
  final int? customTotalSteps;

  const PasswordStep({
    super.key,
    this.customCurrentStep,
    this.customTotalSteps,
  });

  @override
  State<PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends State<PasswordStep> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

  bool _isMinor = false;

  void _showTermsOfUse() {
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
                          _section('13. AUSÊNCIA, CUSTÓDIA E DISPUTAS', '· Aula é considerada iniciada apenas quando o personal aciona “Iniciar aula” e o aluno confirma no aplicativo.\n· Se uma das partes marcar “não compareceu”, o valor ficará em custódia por até 48h.\n· Ambas as partes terão 24h para enviar evidências ao e-mail oficial (contato@treinopro.com).\n· Exemplos de evidências:\n  · Check-in em academia\n  · Foto no local com horário visível\n  · Prints do chat oficial\n· O TreinoPro poderá decidir por:\n  · Liberar pagamento ao personal\n  · Reembolsar integralmente o aluno\n  · Aplicar penalidades por má-fé ou reincidência\n· Ausência confirmada do aluno: valor não reembolsado, repassado ao personal e à plataforma.\n· Ausência confirmada do personal: reembolso integral ao aluno.\n· Se não houver evidências suficientes, a decisão poderá ser automática conforme política interna (benefício da dúvida a quem negou ausência ou análise de quem enviou provas).\n· A decisão do TreinoPro será definitiva e inquestionável, constituindo arbitragem privada aceita pelo usuário.\n· As evidências serão utilizadas exclusivamente para arbitragem e tratadas conforme a LGPD.'),
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

  void _showPrivacyPolicy() {
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

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateData);
    _confirmPasswordController.addListener(_updateData);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updateData() {
    // Apenas atualizar os estados locais sem chamar o BLoC
    // O BLoC será atualizado apenas quando o formulário for submetido
    setState(() {
      // Força rebuild do widget para atualizar validações visuais
    });
  }

  bool _isPasswordValid(String password) {
    return password.length >= 8 &&
        _hasUppercase(password) &&
        _hasLowercase(password) &&
        _hasDigit(password) &&
        _hasSpecial(password);
  }

  bool _hasUppercase(String s) => RegExp(r'[A-Z]').hasMatch(s);
  bool _hasLowercase(String s) => RegExp(r'[a-z]').hasMatch(s);
  bool _hasDigit(String s) => RegExp(r'[0-9]').hasMatch(s);
  bool _hasSpecial(String s) => RegExp(r'[!@#\$%\^&*(),.?":{}|<>]').hasMatch(s);

  bool _passwordsMatch() {
    return _passwordController.text == _confirmPasswordController.text &&
        _passwordController.text.isNotEmpty;
  }

  // Checklist é renderizado diretamente via _ruleRow; mantido sem função geradora de erros.

  Widget _ruleRow(String text, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: ok ? AppColors.primaryOrange : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.small.copyWith(
              color: ok ? AppColors.primaryOrange : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeRegistration() async {
    if (!_isFormValid()) return;

    // Primeiro, atualizar os dados da senha no BLoC
    context.read<RegistrationBloc>().add(
      registration_events.UpdatePassword(
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        acceptedTerms: _acceptedTerms,
        acceptedPrivacy: _acceptedPrivacy,
      ),
    );

    // Completar o registro imediatamente sem delay
    context.read<RegistrationBloc>().add(
      const registration_events.CompleteRegistration(),
    );
  }

  bool _isFormValid() {
    return _isPasswordValid(_passwordController.text) &&
        _passwordsMatch() &&
        _acceptedTerms &&
        _acceptedPrivacy;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationBloc, registration_states.RegistrationState>(
              builder: (context, state) {
                if (state is registration_states.RegistrationStep) {
                  _isMinor = state.isMinor;
                }
      
                // Calcular etapas usando o helper
                final int internalStep;
                if (state is registration_states.RegistrationStep) {
                  if (state.userType == registration_states.UserType.personalTrainer) {
                    internalStep = 7;
                  } else {
                    internalStep = _isMinor ? 7 : 6;
                  }
                } else {
                  internalStep = 6;
                }
      
                final stepInfo = RegistrationStepsHelper.getStepInfo(
                  internalStep,
                  state is registration_states.RegistrationStep
                      ? state.userType
                      : registration_states.UserType.student,
                  _isMinor,
                );
      
                return Column(
                  children: [
                    // Barra de progresso
                    RegistrationProgressBar(
                      currentStep: widget.customCurrentStep ?? stepInfo.displayStep,
                      totalSteps: widget.customTotalSteps ?? stepInfo.totalSteps,
                    ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Título
                  Text(
                    'Senha',
                    style: AppTextStyles.h6Semibold.copyWith(
                      color: AppColors.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Crie uma senha segura para sua conta',
                    style: AppTextStyles.paragraph.copyWith(
                      color: AppColors.secondaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Formulário (scrollável)
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo senha
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Senha',
                          style: AppTextStyles.paragraph.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: AppTextStyles.paragraph.copyWith(
                            color: const Color(0xFF2D3748),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Digite sua senha',
                            hintStyle: TextStyle(
                              fontSize: 16,
                              color: AppColors.secondaryDark,
                              fontFamily: 'Fira Sans',
                            ),
                            filled: true,
                            fillColor: AppColors.inputBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: AppColors.secondaryDark,
                                width: 0.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: AppColors.secondaryDark,
                                width: 0.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: AppColors.primaryOrange,
                                width: 1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 18,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.secondaryDark,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Requisitos da senha
                    if (_passwordController.text.isNotEmpty) ...[
                      Text(
                        'Sua senha deve conter:',
                        style: AppTextStyles.paragraph.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ruleRow('Pelo menos 8 caracteres', _passwordController.text.length >= 8),
                      _ruleRow('Uma letra maiúscula', _hasUppercase(_passwordController.text)),
                      _ruleRow('Uma letra minúscula', _hasLowercase(_passwordController.text)),
                      _ruleRow('Um número', _hasDigit(_passwordController.text)),
                      _ruleRow('Um caractere especial', _hasSpecial(_passwordController.text)),

                      const SizedBox(height: 16),
                    ],

                    // Campo confirmar senha
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confirmar senha',
                          style: AppTextStyles.paragraph.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: AppTextStyles.paragraph.copyWith(
                            color: const Color(0xFF2D3748),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Confirme sua senha',
                            hintStyle: TextStyle(
                              fontSize: 16,
                              color: AppColors.secondaryDark,
                              fontFamily: 'Fira Sans',
                            ),
                            filled: true,
                            fillColor: AppColors.inputBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color:
                                    _confirmPasswordController.text.isNotEmpty
                                    ? (_passwordsMatch()
                                          ? Colors.green
                                          : Colors.red)
                                    : AppColors.secondaryDark,
                                width:
                                    _confirmPasswordController.text.isNotEmpty
                                    ? 1
                                    : 0.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color:
                                    _confirmPasswordController.text.isNotEmpty
                                    ? (_passwordsMatch()
                                          ? Colors.green
                                          : Colors.red)
                                    : AppColors.secondaryDark,
                                width:
                                    _confirmPasswordController.text.isNotEmpty
                                    ? 1
                                    : 0.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: AppColors.primaryOrange,
                                width: 1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 18,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.secondaryDark,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _ruleRow(
                        'As senhas coincidem',
                        _confirmPasswordController.text.isNotEmpty && _passwordsMatch(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Termos e condições
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: _acceptedTerms,
                                onChanged: (value) {
                                  setState(() {
                                    _acceptedTerms = value ?? false;
                                  });
                                },
                                side: BorderSide(
                                  color: AppColors.primaryOrange,
                                  width: 2.0,
                                ),
                                activeColor: AppColors.primaryOrange,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(horizontal: -4, vertical: 0),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      'Aceito os ',
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _showTermsOfUse,
                                      child: Text(
                                        'termos de uso',
                                        style: AppTextStyles.small.copyWith(
                                          color: AppColors.primaryOrange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Reduzir espaçamento entre checkboxes
                        const SizedBox(height: 4),

                        Padding(
                          padding: const EdgeInsets.only(left: 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: _acceptedPrivacy,
                                onChanged: (value) {
                                  setState(() {
                                    _acceptedPrivacy = value ?? false;
                                  });
                                },
                                side: BorderSide(
                                  color: AppColors.primaryOrange,
                                  width: 2.0,
                                ),
                                activeColor: AppColors.primaryOrange,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(horizontal: -4, vertical: 0),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      'Aceito a ',
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _showPrivacyPolicy,
                                      child: Text(
                                        'política de privacidade',
                                        style: AppTextStyles.small.copyWith(
                                          color: AppColors.primaryOrange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Botões fixos no rodapé
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
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
                          side: BorderSide(
                            color: AppColors.secondary,
                          ),
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

                    // Botão Finalizar
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isFormValid() ? _completeRegistration : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFormValid()
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
                          'Finalizar cadastro',
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
