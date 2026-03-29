import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ChatRulesModal extends StatelessWidget {
  final VoidCallback onClose;

  const ChatRulesModal({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Atenção',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF718096),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Ícone de aviso
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF5E7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFD69E2E),
                size: 32,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Texto das regras
            const Text(
              'É proibida a troca de números de telefone, e-mails ou redes sociais pelo chat.\n\n'
              'Todas as comunicações devem ocorrer somente dentro da plataforma.\n\n'
              'O descumprimento desta regra pode resultar em banimento imediato da conta.',
              style: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 14,
                color: Color(0xFF4A5568),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Botão de confirmação
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Entendi',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
