import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryMonthController = TextEditingController();
  final _expiryYearController = TextEditingController();
  final _cvvController = TextEditingController();

  CardBrand? _detectedBrand;
  bool _isLoading = false;
  bool _isSavingCard = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentMethodsBloc, PaymentMethodsState>(
      // Só reagir quando estamos no meio de um salvamento
      listenWhen: (previous, current) {
        if (!_isSavingCard) return false;
        // Detectar conclusão: isUpdating passou de true para false
        return previous is PaymentMethodsLoaded &&
            previous.isUpdating &&
            current is PaymentMethodsLoaded;
      },
      listener: (context, state) {
        if (state is! PaymentMethodsLoaded) return;

        if (state.error == null) {
          // Salvamento concluído com sucesso
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isSavingCard = false;
            });
          }
          // Notifica o pai (recarrega métodos em PaymentMethodsBloc)
          try {
            widget.onCardSaved();
          } catch (_) {}
          // Fecha o bottom sheet somente após confirmação de sucesso
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } else {
          // Salvamento falhou
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isSavingCard = false;
            });
          }
          debugPrint('PaymentMethods save error: ${state.error}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível salvar o cartão. Tente novamente.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Número do cartão
              _buildTextField(
              controller: _cardNumberController,
              label: 'Número do Cartão',
              hint: '1234 5678 9012 3456',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(19),
                CardNumberInputFormatter(),
              ],
              onChanged: _onCardNumberChanged,
              validator: _validateCardNumber,
            ),

            const SizedBox(height: 20),

            // Nome do portador
            _buildTextField(
              controller: _cardHolderController,
              label: 'Nome do Portador',
              hint: 'Como está no cartão',
              textCapitalization: TextCapitalization.characters,
              validator: _validateCardHolder,
            ),

            const SizedBox(height: 20),

            // Validade e CVV
            Row(
              children: [
                // Mês
                Expanded(
                  child: _buildTextField(
                    controller: _expiryMonthController,
                    label: 'Mês',
                    hint: 'MM',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    validator: _validateExpiryMonth,
                  ),
                ),

                const SizedBox(width: 16),

                // Ano
                Expanded(
                  child: _buildTextField(
                    controller: _expiryYearController,
                    label: 'Ano',
                    hint: 'AA',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    validator: _validateExpiryYear,
                  ),
                ),

                const SizedBox(width: 16),

                // CVV
                Expanded(
                  child: _buildTextField(
                    controller: _cvvController,
                    label: 'CVV',
                    hint: '123',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: _validateCVV,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Bandeira detectada
            if (_detectedBrand != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryOrange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: AppColors.primaryOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bandeira detectada: ${_getCardBrandName(_detectedBrand!)}',
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 14,
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 32),

            // Botão salvar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Salvar ${_getCardTypeName()}',
                        style: const TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    ));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Fira Sans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Fira Sans',
              color: Color(0xFFA0AEC0),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryOrange),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  void _onCardNumberChanged(String value) {
    final cleanNumber = value.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _detectedBrand = _detectCardBrand(cleanNumber);
    });
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Número do cartão é obrigatório';
    }

    final cleanNumber = value.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return 'Número do cartão inválido';
    }

    if (!_isValidLuhn(cleanNumber)) {
      return 'Número do cartão inválido';
    }

    return null;
  }

  String? _validateCardHolder(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome do portador é obrigatório';
    }

    if (value.length < 2) {
      return 'Nome muito curto';
    }

    return null;
  }

  String? _validateExpiryMonth(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mês é obrigatório';
    }

    final month = int.tryParse(value);
    if (month == null || month < 1 || month > 12) {
      return 'Mês inválido';
    }

    return null;
  }

  String? _validateExpiryYear(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ano é obrigatório';
    }

    final year = int.tryParse(value);
    if (year == null) {
      return 'Ano inválido';
    }

    final currentYear = DateTime.now().year % 100;
    if (year < currentYear) {
      return 'Cartão expirado';
    }

    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV é obrigatório';
    }

    if (value.length < 3 || value.length > 4) {
      return 'CVV inválido';
    }

    return null;
  }

  void _saveCard() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isSavingCard = true;
    });

    // Dispara o evento e aguarda: o BlocListener fechará o bottom sheet
    // somente após o BLoC confirmar o salvamento com sucesso, eliminando
    // a condição de corrida que fazia o cartão não aparecer na lista da proposta.
    context.read<PaymentMethodsBloc>().add(
      SaveCard(
        cardNumber: _cardNumberController.text.replaceAll(RegExp(r'\D'), ''),
        cardHolderName: _cardHolderController.text.trim(),
        expiryMonth: _expiryMonthController.text.padLeft(2, '0'),
        expiryYear: _expiryYearController.text.padLeft(2, '0'),
        cvv: _cvvController.text,
        cardType: widget.cardType,
      ),
    );
  }

  String _getCardTypeName() {
    return widget.cardType == CardType.credit
        ? 'Cartão de Crédito'
        : 'Cartão de Débito';
  }

  String _getCardBrandName(CardBrand brand) {
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

  CardBrand _detectCardBrand(String cardNumber) {
    if (cardNumber.startsWith('4')) return CardBrand.visa;
    if (cardNumber.startsWith('5') || cardNumber.startsWith('2'))
      return CardBrand.mastercard;
    if (cardNumber.startsWith('3')) {
      if (cardNumber.startsWith('34') || cardNumber.startsWith('37')) {
        return CardBrand.americanExpress;
      }
      return CardBrand.diners;
    }
    if (cardNumber.startsWith('6')) return CardBrand.elo;
    if (cardNumber.startsWith('38')) return CardBrand.hipercard;

    return CardBrand.unknown;
  }

  bool _isValidLuhn(String cardNumber) {
    int sum = 0;
    bool isEven = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      isEven = !isEven;
    }

    return sum % 10 == 0;
  }
}

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length <= 4) {
      return newValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
