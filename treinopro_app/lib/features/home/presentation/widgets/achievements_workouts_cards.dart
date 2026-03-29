import 'package:flutter/material.dart';
import '../../domain/entities/home_state.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget dos cards de conquistas e treinos realizados
class AchievementsWorkoutsCards extends StatelessWidget {
  final HomeState homeState;
  final VoidCallback? onAchievementsTap;

  const AchievementsWorkoutsCards({
    super.key,
    required this.homeState,
    this.onAchievementsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Card "Suas conquistas"
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 140),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white, // #FFFFFF
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.08,
                  ), // blur 12, y=4, opacidade 0.08
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone de coroa
                Icon(
                  Icons.workspace_premium, // Ícone de coroa
                  size: 28,
                  color: AppColors.primaryOrange, // Laranja principal
                ),

                const SizedBox(
                  height: 8,
                ), // Espaçamento entre título e subtítulo
                // Título
                Text(
                  'Suas conquistas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700, // bold
                    color: const Color(0xFF2A2A2A), // #2A2A2A
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(
                  height: 8,
                ), // Espaçamento entre título e subtítulo
                // Link "Saiba mais"
                GestureDetector(
                  onTap: onAchievementsTap,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Saiba mais',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600, // semibold
                          color: const Color(0xFF6B6B6B), // #6B6B6B
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: const Color(0xFF6B6B6B), // #6B6B6B
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16), // Espaçamento entre cards
        // Card "Treinos realizados"
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 140),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white, // #FFFFFF
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.08,
                  ), // blur 12, y=4, opacidade 0.08
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone de nadador
                Icon(
                  Icons.pool, // Ícone de nadador
                  size: 28,
                  color: AppColors.primaryOrange, // Laranja principal
                ),

                const SizedBox(
                  height: 8,
                ), // Espaçamento entre título e subtítulo
                // Número central
                Text(
                  homeState.completedWorkouts > 0
                      ? '${homeState.completedWorkouts}'
                      : '–',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700, // bold
                    color: const Color(0xFF2A2A2A), // #2A2A2A
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(
                  height: 8,
                ), // Espaçamento entre título e subtítulo
                // Subtítulo
                Text(
                  'Treinos realizados',
                  style: TextStyle(
                    fontSize: 13, // 12-13px conforme especificado
                    color: const Color(0xFF6B6B6B), // #6B6B6B
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
