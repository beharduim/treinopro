import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Widget do logo do TreinoPro extraído do design do Figma
class TreinoProLogo extends StatelessWidget {
  const TreinoProLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.logoSize,
      height: AppDimensions.logoSize,
      child: Image.asset(
        AppAssets.logo,
        fit: BoxFit.contain,
        // Melhora a qualidade da imagem
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
