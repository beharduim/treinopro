import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Widget reutilizável para dropdown das perguntas do questionário
class HealthQuestionDropdown extends StatelessWidget {
  final String question;
  final String? selectedValue;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool isRequired;
  final String? errorText;

  const HealthQuestionDropdown({
    super.key,
    required this.question,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
    this.isRequired = true,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pergunta
        Row(
          children: [
            Expanded(
              child: Text(
                question,
                style: AppTextStyles.paragraph.copyWith(
                  color: AppColors.secondaryDark,
                ),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: AppTextStyles.paragraph.copyWith(
                  color: Colors.red,
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Dropdown
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null ? Colors.red : AppColors.secondaryDark,
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedValue,
            onChanged: onChanged,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
            style: AppTextStyles.small.copyWith(
              color: selectedValue != null 
                  ? AppColors.secondaryDark 
                  : AppColors.secondaryDark.withValues(alpha: 0.6),
            ),
            hint: Text(
              'Selecione uma opção',
              style: AppTextStyles.small.copyWith(
                color: AppColors.secondaryDark.withValues(alpha: 0.6),
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.secondaryDark,
              size: 24,
            ),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.secondaryDark,
                  ),
                ),
              );
            }).toList(),
            dropdownColor: AppColors.inputBackground,
            elevation: 2,
          ),
        ),
        
        // Texto de erro
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppTextStyles.small.copyWith(
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}
