import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Campo inteligente de preço com sugestões
class SmartPriceField extends StatefulWidget {
  final double? initialValue;
  final double minValue;
  final double? suggestedValue;
  final ValueChanged<double> onValueChanged;
  final List<double> suggestions;
  final String currency;
  final String placeholder;

  const SmartPriceField({
    super.key,
    this.initialValue,
    required this.minValue,
    this.suggestedValue,
    required this.onValueChanged,
    this.suggestions = const [30, 40, 50, 60, 80, 100],
    this.currency = 'R\$',
    this.placeholder = 'Digite o valor',
  });

  @override
  State<SmartPriceField> createState() => _SmartPriceFieldState();
}

class _SmartPriceFieldState extends State<SmartPriceField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toStringAsFixed(0) ?? '',
    );
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.isEmpty) {
      setState(() => _errorMessage = null);
      return;
    }

    final value = double.tryParse(text);
    if (value == null) {
      setState(() => _errorMessage = 'Valor inválido');
      return;
    }

    if (value < widget.minValue) {
      setState(
        () => _errorMessage =
            'Valor mínimo de ${widget.currency} ${widget.minValue.toStringAsFixed(0)}',
      );
      return;
    }

    setState(() => _errorMessage = null);
    widget.onValueChanged(value);
  }

  void _onSuggestionTapped(double value) {
    _controller.text = value.toStringAsFixed(0);
    widget.onValueChanged(value);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorMessage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de entrada
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: hasError ? Colors.red : AppColors.secondaryDark,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.small.copyWith(color: AppColors.secondaryDark),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: AppTextStyles.small.copyWith(
                color: AppColors.secondaryDark.withOpacity(0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 22,
              ),
              prefixText: '${widget.currency} ',
              prefixStyle: AppTextStyles.small.copyWith(
                color: AppColors.secondaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Mensagem de erro
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _errorMessage!,
              style: AppTextStyles.small.copyWith(color: Colors.red),
            ),
          ),

        // Sugestões de preço
        if (widget.suggestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Sugestões de preço:',
            style: AppTextStyles.small.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.suggestions.map((value) {
              final isSelected = _controller.text == value.toStringAsFixed(0);
              final isSuggested = widget.suggestedValue == value;

              return _PriceSuggestionChip(
                value: value,
                currency: widget.currency,
                isSelected: isSelected,
                isSuggested: isSuggested,
                onTap: () => _onSuggestionTapped(value),
              );
            }).toList(),
          ),
        ],

        // Informação adicional
        if (widget.suggestedValue != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.primaryOrange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sugestão com base na modalidade: ${widget.currency} ${widget.suggestedValue!.toStringAsFixed(0)}',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Chip de sugestão de preço
class _PriceSuggestionChip extends StatelessWidget {
  final double value;
  final String currency;
  final bool isSelected;
  final bool isSuggested;
  final VoidCallback onTap;

  const _PriceSuggestionChip({
    required this.value,
    required this.currency,
    required this.isSelected,
    required this.isSuggested,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange
              : isSuggested
              ? AppColors.primaryOrange.withOpacity(0.1)
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected || isSuggested
                ? AppColors.primaryOrange
                : AppColors.secondaryDark.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSuggested && !isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.star,
                  size: 12,
                  color: AppColors.primaryOrange,
                ),
              ),
            Text(
              '$currency ${value.toStringAsFixed(0)}',
              style: AppTextStyles.small.copyWith(
                color: isSelected
                    ? Colors.white
                    : isSuggested
                    ? AppColors.primaryOrange
                    : AppColors.secondaryDark,
                fontWeight: isSuggested || isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
