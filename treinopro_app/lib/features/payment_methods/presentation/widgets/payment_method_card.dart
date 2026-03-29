import 'package:flutter/material.dart';

class PaymentMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;

  const PaymentMethodCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? const Color(0xFFE2E8F0) : Colors.grey[300]!,
          ),
          boxShadow: isEnabled ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            // Ícone
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isEnabled ? color.withOpacity(0.1) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isEnabled ? color : Colors.grey[400],
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? const Color(0xFF1A202C) : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 14,
                      color: isEnabled ? const Color(0xFF718096) : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            
            // Seta
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isEnabled ? const Color(0xFF718096) : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
