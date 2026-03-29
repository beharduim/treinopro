import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// Utilitários para carregamento de imagens
class ImageUtils {
  /// Constrói uma URL completa para imagem baseada na configuração do ambiente
  static String buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // CORREÇÃO: Se a URL vem com localhost, substituir pela URL correta
    if (imagePath.contains('localhost:3000') || imagePath.contains('localhost:')) {
      final baseUrl = AppConfig.apiBaseUrl;
      // Extrair apenas o path da URL localhost
      final uri = Uri.parse(imagePath);
      final path = uri.path;
      debugPrint('🔧 [IMAGE_UTILS] Corrigindo URL localhost: $imagePath -> $baseUrl$path');
      return '$baseUrl$path';
    }
    
    // Se já é uma URL completa válida, retornar como está
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    // Se é um caminho relativo, construir URL completa
    final baseUrl = AppConfig.apiBaseUrl;
    return '$baseUrl/$imagePath'.replaceAll('//', '/').replaceFirst(':/', '://');
  }
  
  /// Widget para carregar imagem de perfil com fallback
  static Widget buildProfileImage({
    required String? imageUrl,
    required double size,
    IconData fallbackIcon = Icons.person,
    Color? fallbackIconColor,
    Color? backgroundColor,
  }) {
    final fullImageUrl = buildImageUrl(imageUrl);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFE0E0E0),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: fullImageUrl.isNotEmpty
          ? Image.network(
              fullImageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: size * 0.3,
                    height: size * 0.3,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF666666)),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ [IMAGE_UTILS] Erro ao carregar imagem: $fullImageUrl - $error');
                return Icon(
                  fallbackIcon,
                  color: fallbackIconColor ?? const Color(0xFF666666),
                  size: size * 0.5,
                );
              },
            )
          : Icon(
              fallbackIcon,
              color: fallbackIconColor ?? const Color(0xFF666666),
              size: size * 0.5,
            ),
    );
  }
  
  /// Widget para carregar imagem genérica com fallback
  static Widget buildNetworkImage({
    required String? imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final fullImageUrl = buildImageUrl(imageUrl);
    
    if (fullImageUrl.isEmpty) {
      return errorWidget ?? Container(
        width: width,
        height: height,
        color: const Color(0xFFE0E0E0),
        child: const Icon(
          Icons.image,
          color: Color(0xFF666666),
        ),
      );
    }
    
    return Image.network(
      fullImageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? Container(
          width: width,
          height: height,
          color: const Color(0xFFE0E0E0),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF666666)),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ [IMAGE_UTILS] Erro ao carregar imagem: $fullImageUrl - $error');
        return errorWidget ?? Container(
          width: width,
          height: height,
          color: const Color(0xFFE0E0E0),
          child: const Icon(
            Icons.broken_image,
            color: Color(0xFF666666),
          ),
        );
      },
    );
  }
}