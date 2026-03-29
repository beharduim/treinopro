import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/payment_method.dart';
import '../bloc/payment_methods_bloc.dart';
import 'card_form_widget.dart';
import 'pix_form_widget.dart';
import 'mercado_pago_form_widget.dart';

class AddPaymentMethodBottomSheet extends StatefulWidget {
  final CardType? cardType;
  final PaymentMethodType? paymentMethodType;
  final VoidCallback onCardSaved;
  final PaymentMethodsBloc bloc;
  final bool fromStep3;

  const AddPaymentMethodBottomSheet({
    super.key,
    this.cardType,
    this.paymentMethodType,
    required this.onCardSaved,
    required this.bloc,
    this.fromStep3 = false,
  });

  @override
  State<AddPaymentMethodBottomSheet> createState() => _AddPaymentMethodBottomSheetState();
}

class _AddPaymentMethodBottomSheetState extends State<AddPaymentMethodBottomSheet> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Se um método específico foi selecionado, inicia na página de preenchimento
    final hasSpecificMethod = widget.cardType != null || widget.paymentMethodType != null;
    _pageController = PageController(initialPage: hasSpecificMethod ? 1 : 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethodType = widget.paymentMethodType ?? 
        (widget.cardType == CardType.credit ? PaymentMethodType.creditCard : PaymentMethodType.debitCard);

    // Se um método específico foi selecionado, mostra apenas o formulário
    final hasSpecificMethod = widget.cardType != null || widget.paymentMethodType != null;

    // Ajustar altura baseada no tipo de pagamento
    final double heightMultiplier = paymentMethodType == PaymentMethodType.mercadoPago ? 0.8 : 0.7;

    return BlocProvider.value(
      value: widget.bloc,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * heightMultiplier,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Color(0xFF718096)),
                    ),
                    Expanded(
                      child: Text(
                        _getTitle(paymentMethodType),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Para centralizar o título
                  ],
                ),
              ),
              
              // Conteúdo
              Expanded(
                child: hasSpecificMethod 
                  ? _buildFormPage(paymentMethodType)
                  : PageView(
                      controller: _pageController,
                      children: [
                        _buildMethodSelectionPage(paymentMethodType),
                        _buildFormPage(paymentMethodType),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodSelectionPage(PaymentMethodType type) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escolha o método de pagamento',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A202C),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Selecione como você deseja pagar suas aulas',
            style: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 14,
              color: Color(0xFF718096),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Opções de método
          _buildMethodOption(
            title: 'Cartão de Crédito',
            subtitle: 'Visa, Mastercard, Elo, etc.',
            icon: Icons.credit_card,
            color: const Color(0xFF4F46E5),
            isSelected: type == PaymentMethodType.creditCard,
            onTap: () => _selectMethod(PaymentMethodType.creditCard),
          ),
          
          const SizedBox(height: 12),
          
          _buildMethodOption(
            title: 'Cartão de Débito',
            subtitle: 'Visa, Mastercard, Elo, etc.',
            icon: Icons.account_balance_wallet,
            color: const Color(0xFF059669),
            isSelected: type == PaymentMethodType.debitCard,
            onTap: () => _selectMethod(PaymentMethodType.debitCard),
          ),
          
          const SizedBox(height: 12),
          
          _buildMethodOption(
            title: 'PIX',
            subtitle: 'Pagamento instantâneo',
            icon: Icons.qr_code,
            color: const Color(0xFF7C3AED),
            isSelected: type == PaymentMethodType.pix,
            onTap: () => _selectMethod(PaymentMethodType.pix),
          ),
          
          const SizedBox(height: 12),
          
          _buildMethodOption(
            title: 'Mercado Pago',
            subtitle: 'Conta verificada',
            icon: Icons.payment,
            color: const Color(0xFF00AEEF),
            isSelected: type == PaymentMethodType.mercadoPago,
            onTap: () => _selectMethod(PaymentMethodType.mercadoPago),
          ),
          
          const Spacer(),
          
          // Botão continuar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPage(PaymentMethodType type) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: _buildSpecificForm(type),
    );
  }

  Widget _buildMethodOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : const Color(0xFF1A202C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 14,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
            
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryOrange,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificForm(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
        return CardFormWidget(
          cardType: CardType.credit,
          onCardSaved: widget.onCardSaved,
        );
      case PaymentMethodType.debitCard:
        return CardFormWidget(
          cardType: CardType.debit,
          onCardSaved: widget.onCardSaved,
        );
      case PaymentMethodType.pix:
        return PixFormWidget(
          onPixConfigured: widget.onCardSaved,
        );
      case PaymentMethodType.mercadoPago:
        return MercadoPagoFormWidget(
          onMercadoPagoConfigured: widget.onCardSaved,
        );
    }
  }

  String _getTitle(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
        return 'Adicionar Cartão de Crédito';
      case PaymentMethodType.debitCard:
        return 'Adicionar Cartão de Débito';
      case PaymentMethodType.pix:
        return 'Configurar PIX';
      case PaymentMethodType.mercadoPago:
        return 'Configurar Mercado Pago';
    }
  }

  void _selectMethod(PaymentMethodType type) {
    setState(() {
      // Atualizar o tipo selecionado
    });
  }
}
