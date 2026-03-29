import 'package:flutter/material.dart';
import '../../../core/widgets/custom_bottom_navigation_bar.dart';

class StudentBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const StudentBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBottomNavigationBar(
      currentIndex: currentIndex,
      items: [
        BottomNavigationItem(
          iconData: Icons.home,
          label: 'Início',
          onTap: () => onTap(0),
        ),
        BottomNavigationItem(
          iconData: Icons.fitness_center,
          label: 'Treino',
          onTap: () => onTap(1),
        ),
        BottomNavigationItem(
          iconData: Icons.person,
          label: 'Perfil',
          onTap: () => onTap(2),
        ),
      ],
    );
  }
}
