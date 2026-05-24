import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../core/constants/app_colors.dart';

class StripeCustomCardModal extends StatefulWidget {
  final String clientSecret;
  final String publishableKey;
  final double amount;
  final VoidCallback onSuccess;

  const StripeCustomCardModal({
    super.key,
    required this.clientSecret,
    required this.publishableKey,
    required this.amount,
    required this.onSuccess,
  });

  @override
  State<StripeCustomCardModal> createState() => _StripeCustomCardModalState();
}

class _StripeCustomCardModalState extends State<StripeCustomCardModal> {
  final CardFormEditController _cardController = CardFormEditController();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('🚀 STRIPE CUSTOM MODAL: Inicializado com sucesso em pt-BR!');
    _applyStripeKey();
    _cardController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _applyStripeKey() async {
    if (widget.publishableKey.isNotEmpty) {
      Stripe.publishableKey = widget.publishableKey;
      await Stripe.instance.applySettings();
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  bool get _isCardComplete => _cardController.details.complete == true;

  Future<void> _pay() async {
    if (!_isCardComplete || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      var intent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: widget.clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              address: Address(
                city: null,
                country: 'BR',
                line1: null,
                line2: null,
                postalCode: null,
                state: null,
              ),
            ),
          ),
        ),
      );

      if (intent.status == PaymentIntentsStatus.RequiresAction) {
        intent = await Stripe.instance.handleNextAction(widget.clientSecret);
      }

      if (intent.status == PaymentIntentsStatus.Succeeded ||
          intent.status == PaymentIntentsStatus.RequiresCapture) {
        if (mounted) {
          widget.onSuccess();
        }
      } else {
        setState(() {
          _errorMessage =
              'Pagamento não concluído. Status do banco: ${intent.status.name}';
        });
      }
    } on StripeException catch (e) {
      setState(() {
        _errorMessage = _translateStripeError(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro inesperado ao processar pagamento. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _translateStripeError(StripeException e) {
    final code = e.error.code;
    final declineCode = e.error.declineCode;

    if (declineCode != null) {
      switch (declineCode.toLowerCase()) {
        case 'insufficient_funds':
          return 'Saldo insuficiente no cartão.';
        case 'card_declined':
          return 'Cartão recusado pelo banco emissor.';
        case 'expired_card':
          return 'O cartão informado está vencido.';
        case 'incorrect_cvc':
          return 'O código de segurança (CVC) está incorreto.';
        case 'lost_card':
        case 'stolen_card':
          return 'Cartão bloqueado por perda ou roubo.';
        case 'do_not_honor':
          return 'Transação não autorizada pelo banco.';
        default:
          return 'Cartão recusado pelo banco ($declineCode).';
      }
    }

    switch (code) {
      case FailureCode.Failed:
        return 'A transação falhou ou foi recusada.';
      case FailureCode.Canceled:
        return 'O pagamento foi cancelado.';
      case FailureCode.Timeout:
        return 'Tempo limite esgotado ao conectar com o banco.';
      default:
        return e.error.localizedMessage ?? 'Erro ao processar cartão.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedPrice = widget.amount.toStringAsFixed(2).replaceAll('.', ',');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header e botão fechar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pagamento com Cartão',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
              IconButton(
                onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF718096)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Insira os dados do seu cartão para confirmar o agendamento.',
            style: TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 15,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 24),

          // Badge de segurança
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.lock_outline, size: 18, color: Color(0xFF2B6CB0)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Transação segura e criptografada via Stripe',
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2B6CB0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Título dos campos
          const Text(
            'Dados do Cartão',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),

          // Widget nativo da Stripe (Layout multi-linha dinâmico)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CardFormField(
              controller: _cardController,
              enablePostalCode: false,
              style: CardFormStyle(
                backgroundColor: const Color(0xFFF7FAFC),
                borderColor: Colors.transparent,
                borderRadius: 8,
                textColor: const Color(0xFF1A202C),
                placeholderColor: const Color(0xFFA0AEC0),
                textErrorColor: Colors.red,
                cursorColor: AppColors.primaryOrange,
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 14,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),

          // Botão Pagar
          ElevatedButton(
            onPressed: (_isCardComplete && !_isProcessing) ? _pay : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primaryOrange.withOpacity(0.4),
              disabledForegroundColor: Colors.white.withOpacity(0.8),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Pagar R\$ $formattedPrice',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
