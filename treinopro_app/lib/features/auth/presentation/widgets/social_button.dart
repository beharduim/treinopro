import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Widget de botão social (Google/Facebook) seguindo o design do Figma
class SocialButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryOrange, width: 2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryOrange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    Icon(
                      icon,
                      size: text == 'Google' ? 32 : 20,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: AppTextStyles.h6Semibold.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
