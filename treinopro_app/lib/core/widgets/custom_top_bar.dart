import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../features/notifications/notifications.dart';

/// Top bar customizado reutilizável para aluno e personal trainer
/// Segue exatamente o design do Figma
class CustomTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationTap;
  final int unreadNotificationsCount;

  const CustomTopBar({
    super.key,
    this.onNotificationTap,
    this.unreadNotificationsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120, // Aumentado de 97 para 120
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Espaço vazio à esquerda para centralizar o logo
              const SizedBox(width: 40),
              // Logo centralizado
              Expanded(
                child: Center(
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'TREINO',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue, // Azul
                            letterSpacing: 1,
                          ),
                        ),
                        TextSpan(
                          text: 'PRO',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange, // Laranja
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Ícone de notificação (centralizado verticalmente)
              NotificationBell(
                onTap: onNotificationTap,
                unreadCount: unreadNotificationsCount,
                hasNotifications: unreadNotificationsCount > 0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120); // Atualizado para 120
}
