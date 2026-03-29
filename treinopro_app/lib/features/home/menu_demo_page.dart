import 'package:flutter/material.dart';
import 'presentation/pages/student_home_page.dart';
import 'presentation/pages/personal_home_page.dart';

/// Página de demonstração dos menus
class MenuDemoPage extends StatefulWidget {
  const MenuDemoPage({super.key});

  @override
  State<MenuDemoPage> createState() => _MenuDemoPageState();
}

class _MenuDemoPageState extends State<MenuDemoPage> {
  bool isPersonal = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demonstração dos Menus'),
        backgroundColor: const Color(0xFF007BFF),
        foregroundColor: Colors.white,
        actions: [
          Switch(
            value: isPersonal,
            onChanged: (value) {
              setState(() {
                isPersonal = value;
              });
            },
            activeColor: Colors.white,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                isPersonal ? 'Personal' : 'Aluno',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isPersonal ? const PersonalHomePage() : const StudentHomePage(),
    );
  }
}
