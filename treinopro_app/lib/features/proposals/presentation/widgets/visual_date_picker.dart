import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Seletor visual de data para treinos
class VisualDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? minDate;
  final DateTime? maxDate;
  final String placeholder;

  const VisualDatePicker({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.minDate,
    this.maxDate,
    this.placeholder = 'Selecione uma data',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDatePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppColors.secondaryDark,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedDate != null
                    ? _formatDate(selectedDate!)
                    : placeholder,
                style: AppTextStyles.small.copyWith(
                  color: selectedDate != null
                      ? AppColors.secondaryDark
                      : AppColors.secondaryDark.withValues(alpha: 0.6),
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.secondaryDark,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: minDate ?? DateTime.now(),
      lastDate: maxDate ?? DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.secondary,
              secondary: AppColors.primaryOrange,
              onSecondary: Colors.white,
              error: Colors.red,
              onError: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryOrange,
                textStyle: AppTextStyles.small.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              headerBackgroundColor: AppColors.primaryOrange,
              headerForegroundColor: Colors.white,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppColors.secondary;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primaryOrange;
                }
                return Colors.transparent;
              }),
              yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppColors.secondary;
              }),
              yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primaryOrange;
                }
                return Colors.transparent;
              }),
              // Configurações para campos de texto (digitação da data)
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.secondaryDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.secondaryDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primaryOrange, width: 2),
                ),
                hintStyle: AppTextStyles.small.copyWith(
                  color: AppColors.secondaryDark.withValues(alpha: 0.6),
                ),
                labelStyle: AppTextStyles.small.copyWith(
                  color: AppColors.secondaryDark,
                ),
              ),
            ),
            // Configurações globais para campos de texto
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.secondaryDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.secondaryDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryOrange, width: 2),
              ),
              hintStyle: AppTextStyles.small.copyWith(
                color: AppColors.secondaryDark.withValues(alpha: 0.6),
              ),
              labelStyle: AppTextStyles.small.copyWith(
                color: AppColors.secondaryDark,
              ),
            ),
            // Configurações para o tema de texto
            textTheme: Theme.of(context).textTheme.copyWith(
              bodyLarge: AppTextStyles.paragraph.copyWith(color: AppColors.secondary),
              bodyMedium: AppTextStyles.small.copyWith(color: AppColors.secondary),
              bodySmall: AppTextStyles.small.copyWith(color: AppColors.secondary),
              labelLarge: AppTextStyles.small.copyWith(color: AppColors.secondary),
              labelMedium: AppTextStyles.small.copyWith(color: AppColors.secondary),
              labelSmall: AppTextStyles.small.copyWith(color: AppColors.secondary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      onDateSelected(picked);
    }
  }

  String _formatDate(DateTime date) {
    final weekdays = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    
    final months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    final weekday = weekdays[date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;

    return '$weekday, $day de $month de $year';
  }
}
