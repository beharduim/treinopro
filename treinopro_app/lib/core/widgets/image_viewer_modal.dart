import 'package:flutter/material.dart';

/// Modal para visualização ampliada de imagens
class ImageViewerModal extends StatelessWidget {
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final VoidCallback? onClose;

  const ImageViewerModal({
    super.key,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Imagem centralizada
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Botão de fechar
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      shape: const CircleBorder(),
                    ),
                  ),
                ),

                // Informações do usuário (se fornecidas)
                if (title != null || subtitle != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (title != null)
                            Text(
                              title!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Função helper para mostrar o modal
  static void show(
    BuildContext context, {
    required String imageUrl,
    String? title,
    String? subtitle,
  }) {
    // Usar Overlay para garantir que apareça na frente de qualquer modal
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          onTap: () => overlayEntry.remove(),
          child: Container(
            color: Colors.black.withOpacity(0.9),
            child: Center(
              child: GestureDetector(
                onTap: () {}, // Prevenir fechamento ao clicar na imagem
                child: ImageViewerModal(
                  imageUrl: imageUrl,
                  title: title,
                  subtitle: subtitle,
                  onClose: () => overlayEntry.remove(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
  }
}
