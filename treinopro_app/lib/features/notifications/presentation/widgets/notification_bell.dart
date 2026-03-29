import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget do sino de notificações com indicador
class NotificationBell extends StatelessWidget {
  final VoidCallback? onTap;
  final int unreadCount;
  final bool hasNotifications;

  const NotificationBell({
    super.key,
    this.onTap,
    this.unreadCount = 0,
    this.hasNotifications = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Ícone do sino
            Center(
              child: Icon(
                Icons.notifications,
                color: AppColors.primaryOrange,
                size: 24,
              ),
            ),
            
            // Indicador de notificações não lidas
            if (hasNotifications && unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: unreadCount > 9
                      ? Center(
                          child: Text(
                            '9+',
                            style: TextStyle(
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            unreadCount.toString(),
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
