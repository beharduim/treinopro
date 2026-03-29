import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';

/// Widget para seleção de método de pagamento
class PaymentMethodSelector extends StatelessWidget {
  final List<PaymentMethod> availableMethods;
  final String? selectedMethodId;
  final bool isLoading;
  final Function(String methodId, String methodName) onMethodSelected;

  const PaymentMethodSelector({
    super.key,
    required this.availableMethods,
    this.selectedMethodId,
    this.isLoading = false,
    required this.onMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.payment,
                color: AppColors.primaryOrange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Método de pagamento',
                    style: AppTextStyles.paragraph.copyWith(
                      color: AppColors.secondaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Escolha como deseja pagar:',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.secondaryDark.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Lista de métodos de pagamento
        if (availableMethods.isNotEmpty)
          _buildMethodsList()
        else if (isLoading)
          _buildLoadingState()
        else if (availableMethods.isEmpty)
          _buildEmptyState()
        else
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.secondaryDark.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.secondaryDark.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.payment_outlined,
            size: 48,
            color: AppColors.secondaryDark.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhum método de pagamento cadastrado',
            style: AppTextStyles.paragraph.copyWith(
              color: AppColors.secondaryDark,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Cadastre um método de pagamento no seu perfil para continuar',
            style: AppTextStyles.small.copyWith(
              color: AppColors.secondaryDark.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodsList() {
    // Criar lista apenas com métodos salvos (sem PIX)
    final List<Widget> methodWidgets = [];

    // Adicionar métodos salvos
    methodWidgets.addAll(
      availableMethods.map((method) {
        final isSelected = selectedMethodId == method.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onMethodSelected(
                method.id,
                _getPaymentMethodDisplayName(method),
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryOrange.withOpacity(0.1)
                      : AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryOrange
                        : AppColors.secondaryDark.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Ícone do método
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryOrange
                            : AppColors.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPaymentMethodIcon(method.type),
                        color: isSelected
                            ? Colors.white
                            : AppColors.primaryOrange,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Informações do método
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPaymentMethodDisplayName(method),
                            style: AppTextStyles.paragraph.copyWith(
                              color: isSelected
                                  ? AppColors.primaryOrange
                                  : AppColors.secondaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (method.cardNumber != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Terminado em ${method.cardNumber!.substring(method.cardNumber!.length - 4)}',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.secondaryDark.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Indicador de seleção
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primaryOrange,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );

    return Column(children: methodWidgets);
  }

  IconData _getPaymentMethodIcon(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
        return Icons.credit_card;
      case PaymentMethodType.debitCard:
        return Icons.account_balance_wallet;
      case PaymentMethodType.mercadoPago:
        return Icons.payment;
      case PaymentMethodType.pix:
        return Icons.qr_code;
    }
  }

  String _getPaymentMethodDisplayName(PaymentMethod method) {
    switch (method.type) {
      case PaymentMethodType.creditCard:
        return 'Cartão de Crédito';
      case PaymentMethodType.debitCard:
        return 'Cartão de Débito';
      case PaymentMethodType.mercadoPago:
        return 'Mercado Pago';
      case PaymentMethodType.pix:
        return 'PIX';
    }
  }
}
