import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Modal de confirmação para o aluno aceitar ou reportar problema
/// quando o personal trainer inicia uma aula
class ClassConfirmationModal extends StatelessWidget {
  final String studentName;
  final String personalName;
  final VoidCallback onAccept;
  final VoidCallback onReportProblem;

  const ClassConfirmationModal({
    super.key,
    required this.studentName,
    required this.personalName,
    required this.onAccept,
    required this.onReportProblem,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.all(16),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone de exercício
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFF8C00), // Cor laranja
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 24,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Título
            const Text(
              'Treino iniciado',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 24,
                color: Color(0xFF2D3748),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Descrição
            Text(
              'Seu personal trainer $personalName iniciou seu treino, clique\nabaixo para aceitar ou reportar problema.',
              style: const TextStyle(
                fontFamily: 'Fira Sans',
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Color(0xFF2D3748),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Botão Aceitar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Aceitar',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Color(0xFF2D3748),
                    height: 1.2,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botão Reportar Problema
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onReportProblem,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFFFF8C00),
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Reportar problema',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Color(0xFFFF8C00),
                    height: 1.2,
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
