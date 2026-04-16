import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';

Future<String?> showSavedCardCvvDialog(
  BuildContext context, {
  required PaymentMethod paymentMethod,
}) async {
  final cvvController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final isAmex = paymentMethod.cardBrand == CardBrand.americanExpress;
  final hintText = isAmex ? '1234' : '123';
  final labelText = isAmex ? 'CVV (4 dígitos)' : 'CVV (3 ou 4 dígitos)';
  final brandName = _getCardBrandLabel(paymentMethod.cardBrand);
  final lastFourDigits =
      paymentMethod.cardNumber != null && paymentMethod.cardNumber!.length >= 4
      ? paymentMethod.cardNumber!.substring(
          paymentMethod.cardNumber!.length - 4,
        )
      : null;

  final cvv = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Text(
        'Confirme o código de segurança',
        style: TextStyle(fontFamily: 'Fira Sans', fontWeight: FontWeight.w600),
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Por segurança, informe o CVV do cartão ${brandName.isNotEmpty ? brandName : ''}${lastFourDigits != null ? ' terminado em $lastFourDigits' : ''} para confirmar o pagamento.'
                  .trim(),
              style: const TextStyle(fontFamily: 'Fira Sans', fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: cvvController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: labelText,
                hintText: hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primaryOrange),
                ),
              ),
              validator: (value) {
                final normalized = value?.trim() ?? '';
                if (normalized.isEmpty) {
                  return 'CVV é obrigatório';
                }
                if (!RegExp(r'^\d{3,4}$').hasMatch(normalized)) {
                  return 'Digite um CVV válido com 3 ou 4 dígitos';
                }
                if (isAmex && normalized.length != 4) {
                  return 'American Express usa CVV de 4 dígitos';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(dialogContext).pop(cvvController.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'Confirmar',
            style: TextStyle(fontFamily: 'Fira Sans'),
          ),
        ),
      ],
    ),
  );

  cvvController.dispose();
  return cvv?.trim();
}

String _getCardBrandLabel(CardBrand? brand) {
  switch (brand) {
    case CardBrand.visa:
      return 'Visa';
    case CardBrand.mastercard:
      return 'Mastercard';
    case CardBrand.americanExpress:
      return 'American Express';
    case CardBrand.elo:
      return 'Elo';
    case CardBrand.hipercard:
      return 'Hipercard';
    case CardBrand.diners:
      return 'Diners';
    case CardBrand.discover:
      return 'Discover';
    case CardBrand.jcb:
      return 'JCB';
    case CardBrand.aura:
      return 'Aura';
    case CardBrand.unknown:
    case null:
      return '';
  }
}
