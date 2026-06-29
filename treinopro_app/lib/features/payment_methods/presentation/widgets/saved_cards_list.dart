import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/payment_method.dart';

class SavedCardsList extends StatelessWidget {
  final List<PaymentMethod> cards;
  final Function(String) onRemoveCard;
  final Function(String) onSetDefault;

  const SavedCardsList({
    super.key,
    required this.cards,
    required this.onRemoveCard,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: cards.map((card) => _buildCardItem(context, card)).toList(),
    );
  }

  Widget _buildCardItem(BuildContext context, PaymentMethod card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: card.isDefault
              ? AppColors.primaryOrange
              : const Color(0xFFE2E8F0),
          width: card.isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com bandeira e ações
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bandeira do cartão
              Row(
                children: [
                  _buildCardBrandIcon(card.cardBrand),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCardTypeName(card.cardType),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                      Text(
                        _getCardBrandName(card.cardBrand),
                        style: const TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 14,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Ações
              Row(
                children: [
                  if (card.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'PADRÃO',
                        style: TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),

                  const SizedBox(width: 8),

                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'remove') {
                        _showRemoveCardDialog(context, card);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Remover'),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(
                      Icons.more_vert,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Número do cartão mascarado
          Text(
            _maskCardNumber(card.cardNumber ?? ''),
            style: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3748),
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 8),

          // Nome do portador e validade
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.cardHolderName ?? '',
                style: const TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 14,
                  color: Color(0xFF718096),
                ),
              ),
              if (card.expiryMonth != null && card.expiryYear != null)
                Text(
                  '${card.expiryMonth}/${card.expiryYear}',
                  style: const TextStyle(
                    fontFamily: 'Fira Sans',
                    fontSize: 14,
                    color: Color(0xFF718096),
                  ),
                ),
            ],
          ),

          // Botão "Definir como padrão" alinhado à direita
          if (!card.isDefault) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => onSetDefault(card.id),
                  child: const Text(
                    'Definir como padrão',
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 12,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardBrandIcon(CardBrand? brand) {
    Color color;
    IconData icon;

    switch (brand) {
      case CardBrand.visa:
        color = const Color(0xFF1A1F71);
        icon = Icons.credit_card;
        break;
      case CardBrand.mastercard:
        color = const Color(0xFFEB001B);
        icon = Icons.credit_card;
        break;
      case CardBrand.americanExpress:
        color = const Color(0xFF006FCF);
        icon = Icons.credit_card;
        break;
      case CardBrand.elo:
        color = const Color(0xFFFF6B35);
        icon = Icons.credit_card;
        break;
      default:
        color = const Color(0xFF718096);
        icon = Icons.credit_card;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  String _getCardTypeName(CardType? type) {
    switch (type) {
      case CardType.credit:
        return 'Cartão de Crédito';
      case CardType.debit:
        return 'Cartão de Débito';
      default:
        return 'Cartão';
    }
  }

  String _getCardBrandName(CardBrand? brand) {
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
      default:
        return 'Cartão';
    }
  }

  String _maskCardNumber(String cardNumber) {
    if (cardNumber.length < 4) return cardNumber;

    final lastFour = cardNumber.substring(cardNumber.length - 4);
    final masked = '*' * (cardNumber.length - 4);

    // Adicionar espaços a cada 4 dígitos
    final spaced = masked
        .replaceAllMapped(RegExp(r'.{4}'), (match) => '${match.group(0)} ')
        .trim();

    return '$spaced $lastFour';
  }

  void _showRemoveCardDialog(BuildContext context, PaymentMethod card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Remover Cartão',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Tem certeza que deseja remover este cartão?',
          style: const TextStyle(fontFamily: 'Fira Sans', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'Fira Sans',
                color: Color(0xFF718096),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRemoveCard(card.id);
            },
            child: const Text(
              'Remover',
              style: TextStyle(
                fontFamily: 'Fira Sans',
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
