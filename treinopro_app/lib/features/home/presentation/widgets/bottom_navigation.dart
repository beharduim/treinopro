import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget da navegação inferior
class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const BottomNavigation({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 412,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), // Reduzido de 16 para 12
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border.all(
          color: const Color(0xFFA6A6A6),
          width: 0.24,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão Início
          _buildNavItem(
            icon: 'assets/images/home.png',
            label: 'Início',
            isSelected: currentIndex == 0,
            onTap: () => onTap?.call(0),
          ),
          
          // Botão Treino
          _buildNavItem(
            icon: 'assets/images/strength.png',
            label: 'Treino',
            isSelected: currentIndex == 1,
            onTap: () => onTap?.call(1),
          ),
          
          // Botão Perfil
          _buildNavItem(
            icon: 'assets/images/account.png',
            label: 'Perfil',
            isSelected: currentIndex == 2,
            onTap: () => onTap?.call(2),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 47,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.menuSelected : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage(icon),
                  fit: BoxFit.contain,
                  colorFilter: isSelected 
                      ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 12,
                color: isSelected ? AppColors.menuSelected : AppColors.secondaryDark,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
