import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// App bar customizado reutilizável
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFF2D3748),
                size: 20,
              ),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A202C),
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
