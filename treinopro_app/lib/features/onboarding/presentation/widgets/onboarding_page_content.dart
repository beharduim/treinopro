import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../models/onboarding_page_model.dart';

/// Widget que exibe o conteúdo de uma página de onboarding
class OnboardingPageContent extends StatelessWidget {
  final OnboardingPageModel page;
  final bool isLastPage;

  const OnboardingPageContent({
    super.key,
    required this.page,
    this.isLastPage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Área superior com imagem de fundo (sem logo)
        Expanded(
          flex: 3, // Aumentado de 2 para 3 para dar mais espaço à imagem
          child: Container(
            width: double.infinity,
            child: Stack(
              children: [
                // Imagem de fundo da academia
                Positioned.fill(
                  child: Image.asset(
                    page.effectiveBackgroundImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback para quando a imagem não carrega
                      return Container(
                        color: AppColors.secondaryDarkest.withValues(alpha: 0.3),
                        child: const Center(
                          child: Icon(
                            Icons.fitness_center,
                            size: 64,
                            color: AppColors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Gradiente branco correto: 100% embaixo → 0% no topo
                // Estendendo para cobrir completamente a borda de divisão
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.loginBackground, // 100% branco embaixo
                          AppColors.loginBackground.withValues(alpha: 0.95), // 95% branco
                          AppColors.loginBackground.withValues(alpha: 0.8), // 80% branco
                          AppColors.loginBackground.withValues(alpha: 0.6), // 60% branco
                          AppColors.loginBackground.withValues(alpha: 0.3), // 30% branco
                          AppColors.loginBackground.withValues(alpha: 0.0), // 0% branco no topo
                        ],
                        stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Conteúdo de texto centralizado verticalmente (corpo reduzido)
        Expanded(
          flex: 2, // Reduzido de 3 para 2 para dar mais espaço à imagem
          child: Container(
            width: double.infinity,
            color: AppColors.loginBackground, // Background branco sólido
            padding: const EdgeInsets.symmetric(horizontal: 44),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centraliza verticalmente
              children: [
                // Logo TREINOPRO no mesmo corpo dos textos, logo acima do título
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'TREINO',
                        style: AppTextStyles.h6Semibold.copyWith(
                          fontSize: 28, // Reduzido de 32 para 28
                          color: AppColors.primaryBlue, // Azul para TREINO
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: 'PRO',
                        style: AppTextStyles.h6Semibold.copyWith(
                          fontSize: 28, // Reduzido de 32 para 28
                          color: AppColors.primaryOrange, // Laranja para PRO
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16), // Espaçamento entre TREINOPRO e título
                
                // Título (H5 Semibold, 24px, altura 1.2)
                Text(
                  page.title,
                  style: AppTextStyles.h6Semibold.copyWith(
                    fontSize: 24,
                    color: AppColors.secondaryDarkest, // #0f131a
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16), // Espaçamento entre título e descrição
                
                // Descrição (Fira Sans Regular, 16px, altura 1.3)
                Text(
                  page.description,
                  style: AppTextStyles.paragraph.copyWith(
                    color: AppColors.secondaryDark, // #42464d
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
