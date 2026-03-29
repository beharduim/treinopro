import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';

/// Widget do logo variante do TreinoPro para tela de login
class TreinoProLogoVariant extends StatelessWidget {
  const TreinoProLogoVariant({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240, // 60 * 4 (convertendo de size-60 do Tailwind)
      child: Image.asset(
        AppAssets.logo, // Usando logo principal como fallback por enquanto
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        // Fallback caso a imagem não carregue
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 240,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[800],
            ),
            child: const Icon(
              Icons.fitness_center,
              color: Colors.orange,
              size: 80,
            ),
          );
        },
      ),
    );
  }
}
