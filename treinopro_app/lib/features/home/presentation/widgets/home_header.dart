import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/home_state.dart';

/// Widget do cabeçalho da home
class HomeHeader extends StatelessWidget {
  final HomeState homeState;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;

  const HomeHeader({
    super.key,
    required this.homeState,
    this.onProfileTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 97,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Texto TREINOPRO centralizado
          Positioned(
            left: 0,
            right: 0,
            top: 28, // Centralizado verticalmente no header
            child: Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'TREINO',
                      style: AppTextStyles.h6Semibold.copyWith(
                        fontSize: 28,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'PRO',
                      style: AppTextStyles.h6Semibold.copyWith(
                        fontSize: 28,
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Ícone de notificação (sino) - canto direito
          Positioned(
            right: 16,
            top: 28,
            child: GestureDetector(
              onTap: onNotificationTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications,
                  color: AppColors.primaryOrange,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
