import 'package:flutter/material.dart';

/// Textos sobre bandeiras aceitas via Stripe (conta Brasil).
class PaymentCardBrandsCopy {
  static const subtitle = 'Visa e Mastercard';
  static const note =
      'Aceitamos apenas cartões Visa e Mastercard. Elo e American Express '
      '(Amex) ainda não são aceitos.';
}

class PaymentCardBrandsHint extends StatelessWidget {
  const PaymentCardBrandsHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        PaymentCardBrandsCopy.note,
        style: TextStyle(
          fontFamily: 'Fira Sans',
          fontSize: 12,
          height: 1.4,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
