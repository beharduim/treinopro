import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/payment_method.dart';
import '../bloc/payment_methods_bloc.dart';
import '../bloc/payment_methods_event.dart';
import '../bloc/payment_methods_state.dart';

class CardFormWidget extends StatefulWidget {
  final CardType cardType;
  final VoidCallback onCardSaved;

  const CardFormWidget({
    super.key,
    required this.cardType,
    required this.onCardSaved,
  });

  @override
  State<CardFormWidget> createState() => _CardFormWidgetState();
}

class _CardFormWidgetState extends State<CardFormWidget> {
  bool _isLoading = false;
  bool _isSavingCard = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentMethodsBloc, PaymentMethodsState>(
      listenWhen: (previous, current) {
        if (!_isSavingCard) return false;
        return previous is PaymentMethodsLoaded &&
            previous.isUpdating &&
            current is PaymentMethodsLoaded;
      },
      listener: (context, state) {
        if (state is! PaymentMethodsLoaded) return;

        setState(() {
          _isLoading = false;
          _isSavingCard = false;
        });

        if (state.error == null) {
          widget.onCardSaved();
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível salvar o cartão.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryOrange.withOpacity(0.25),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cadastro seguro Stripe',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A202C),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Os dados do cartão são preenchidos na tela segura do provedor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Fira Sans',
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveCard,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Abrir Stripe',
                    style: const TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _saveCard() {
    setState(() {
      _isLoading = true;
      _isSavingCard = true;
    });

    context.read<PaymentMethodsBloc>().add(
      SaveCard(
        cardNumber: '4242424242424242',
        cardHolderName: 'Stripe Payment Sheet',
        expiryMonth: '12',
        expiryYear: '30',
        cvv: '123',
        cardType: widget.cardType,
      ),
    );
  }
}
