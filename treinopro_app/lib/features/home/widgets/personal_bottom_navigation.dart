import 'package:flutter/material.dart';
import '../../../core/widgets/custom_bottom_navigation_bar.dart';

class PersonalBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PersonalBottomNavigation({
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
          label: 'Aulas',
          onTap: () => onTap(1),
        ),
        BottomNavigationItem(
          iconData: Icons.book,
          label: 'Propostas',
          onTap: () => onTap(2),
        ),
        BottomNavigationItem(
          iconData: Icons.person,
          label: 'Perfil',
          onTap: () => onTap(3),
        ),
      ],
    );
  }
}
