import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tela didática exibida antes do onboarding embutido do Stripe.
/// Replica visualmente a etapa de "negócio/site" para acalmar o personal
/// e explicar o que preencher na tela real do Stripe.
class StripeOnboardingGuidePage extends StatelessWidget {
  static const String treinoProWebsite = 'www.treinopro.com';

  const StripeOnboardingGuidePage({super.key});

  static Future<bool?> open(BuildContext context) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const StripeOnboardingGuidePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _StripeStyleHeader(onClose: () => Navigator.of(context).pop(false)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReassuranceBanner(),
                      const SizedBox(height: 20),
                      const _IntroText(),
                      const SizedBox(height: 28),
                      _Section(
                        title: 'Setor',
                        stripeDescription:
                            'Selecionar seu setor ajuda a atender a obrigações de risco e conformidade. Escolha a opção que melhor descreva os produtos ou serviços que seus clientes comprarão.',
                        tipTitle: 'O que escolher?',
                        tipBody:
                            'Escolha algo relacionado a fitness, educação física ou serviços de treinamento personalizado. '
                            'O Stripe usa isso apenas para conformidade — não muda nada no seu cadastro como personal no TreinoPro.',
                        child: const _MockDropdown(
                          placeholder: 'Selecione o seu setor...',
                        ),
                      ),
                      const SizedBox(height: 28),
                      _Section(
                        title: 'Renda mensal estimada',
                        titleTrailing: const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        stripeDescription:
                            'Selecione uma faixa da sua renda mensal atual para toda a empresa',
                        tipTitle: 'Não é uma empresa nova',
                        tipBody:
                            'O Stripe usa linguagem de "empresa", mas você está abrindo uma conta pessoal para receber repasses das suas aulas. '
                            'Se você está começando agora, pode marcar "Nova empresa (ainda sem receita)" ou a faixa que mais se aproxima do que você espera ganhar por mês com aulas no TreinoPro.',
                        child: const _MockRevenueOptions(),
                      ),
                      const SizedBox(height: 28),
                      _Section(
                        title: 'Seu site',
                        tipTitle: 'Use o site do TreinoPro',
                        tipBody:
                            'Na tela do Stripe, informe exatamente: $treinoProWebsite\n\n'
                            'É o site da plataforma onde você oferece suas aulas. Você não precisa ter site próprio — '
                            'o TreinoPro já é o canal oficial do seu serviço.',
                        tipHighlight: treinoProWebsite,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MockTextField(value: treinoProWebsite),
                            const SizedBox(height: 10),
                            Text(
                              'Compartilhe o site onde você vende ou promove produtos ou serviços. '
                              'O site deve fornecer informações sobre os produtos e serviços que você está vendendo. '
                              'URLs genéricos ou sites em construção não são válidos.',
                              style: _StripeTypography.bodySecondary,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Não tem um site? Adicione uma descrição de produto.',
                              style: _StripeTypography.link,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _ContinueButton(
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StripeStyleHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _StripeStyleHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Color(0xFF111827), size: 22),
            splashRadius: 22,
          ),
          const Expanded(
            child: Text(
              'connect.stripe.com',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
                letterSpacing: -0.1,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.menu, color: Color(0xFF111827), size: 22),
            splashRadius: 22,
          ),
        ],
      ),
    );
  }
}

class _ReassuranceBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, size: 20, color: Color(0xFF1D4ED8)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Você não está criando uma empresa',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Esta é uma prévia didática da próxima tela do Stripe. '
                  'Você vai abrir sua conta pessoal para receber os repasses das suas aulas — '
                  'como abrir uma conta bancária digital.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E40AF),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroText extends StatelessWidget {
  const _IntroText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Informe alguns dados sobre como você ganha ou recebe dinheiro com TreinoPro.',
      style: _StripeTypography.body.copyWith(
        color: const Color(0xFF6B7280),
        fontSize: 15,
        height: 1.45,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget? titleTrailing;
  final String? stripeDescription;
  final Widget child;
  final String tipTitle;
  final String tipBody;
  final String? tipHighlight;

  const _Section({
    required this.title,
    this.titleTrailing,
    this.stripeDescription,
    required this.child,
    required this.tipTitle,
    required this.tipBody,
    this.tipHighlight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: _StripeTypography.sectionTitle),
            if (titleTrailing != null) ...[
              const SizedBox(width: 4),
              titleTrailing!,
            ],
          ],
        ),
        if (stripeDescription != null) ...[
          const SizedBox(height: 8),
          Text(stripeDescription!, style: _StripeTypography.bodySecondary),
        ],
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 12),
        _TipBox(
          title: tipTitle,
          body: tipBody,
          highlight: tipHighlight,
        ),
      ],
    );
  }
}

class _TipBox extends StatelessWidget {
  final String title;
  final String body;
  final String? highlight;

  const _TipBox({
    required this.title,
    required this.body,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFF15803D)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF166534),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (highlight != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: SelectableText(
                highlight!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF14532D),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF166534),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockDropdown extends StatelessWidget {
  final String placeholder;

  const _MockDropdown({required this.placeholder});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFF6A00), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              placeholder,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
          const Icon(Icons.unfold_more, size: 18, color: Color(0xFF6B7280)),
        ],
      ),
    );
  }
}

class _MockRevenueOptions extends StatelessWidget {
  const _MockRevenueOptions();

  static const _options = [
    'Nova empresa (ainda sem receita)',
    'Menos de R\$ 5.000,00 BRL',
    'R\$ 5.000,00 a R\$ 10.000,00',
    'R\$ 10.100,01 a R\$ 20.000,00',
    'Mais de R\$ 20.000,00 BRL',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _options.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: i == 0 ? const Color(0xFFFF6A00) : const Color(0xFFD1D5DB),
                    width: i == 0 ? 6 : 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _options[i],
                  style: TextStyle(
                    fontSize: 15,
                    color: i == 0 ? const Color(0xFF111827) : const Color(0xFF374151),
                    fontWeight: i == 0 ? FontWeight.w500 : FontWeight.w400,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MockTextField extends StatelessWidget {
  final String value;

  const _MockTextField({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF111827),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ContinueButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB088), Color(0xFFFF6A00)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Continuar para o Stripe',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StripeTypography {
  static const sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF111827),
    height: 1.3,
  );

  static const body = TextStyle(
    fontSize: 14,
    color: Color(0xFF374151),
    height: 1.45,
  );

  static const bodySecondary = TextStyle(
    fontSize: 13,
    color: Color(0xFF6B7280),
    height: 1.45,
  );

  static const link = TextStyle(
    fontSize: 13,
    color: Color(0xFFFF6A00),
    height: 1.45,
    decoration: TextDecoration.underline,
    decorationColor: Color(0xFFFF6A00),
  );
}
