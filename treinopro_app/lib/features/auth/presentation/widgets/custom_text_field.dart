import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Widget de campo de texto personalizado seguindo o design do Figma
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool hasError;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.hasError = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    Color borderColor;

    if (widget.hasError) {
      borderColor = Colors.red;
    } else if (_isFocused) {
      borderColor = AppColors.primaryOrange; // Cor do botão
    } else {
      borderColor = const Color(0xFF42464D); // Cor padrão
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3), // Help/White 2 do Figma
        borderRadius: BorderRadius.circular(4), // rounded conforme Figma
        border: Border.all(
          color: borderColor,
          width: _isFocused || widget.hasError ? 2.0 : 0.5,
        ),
      ),
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            _isFocused = hasFocus;
          });
        },
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          style: AppTextStyles.paragraph.copyWith(
            color: const Color(0xFF2D3748), // Secondary/0 do Figma
          ),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: AppTextStyles.paragraph.copyWith(
              color: const Color(0xFF9CA3AF), // Tom de cinza mais claro
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, // px-4
              vertical: 24, // py-6 conforme Figma
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            errorStyle: const TextStyle(
              height: 0,
            ), // Remove mensagem de erro inline
          ),
        ),
      ),
    );
  }
}
