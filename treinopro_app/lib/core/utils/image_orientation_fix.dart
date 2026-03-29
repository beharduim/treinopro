import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Corrige a orientação EXIF de uma imagem e aplica flip horizontal se necessário
/// Retorna o arquivo corrigido (sobrescreve o original)
///
/// Este utilitário resolve o problema de imagens que aparecem
/// rotacionadas ou invertidas devido aos metadados EXIF não serem
/// aplicados corretamente pelo Flutter.
///
/// Também corrige o espelhamento de selfies (câmera frontal) do Android.
///
/// [imageFile] - Arquivo da imagem a ser corrigida
/// [isFromCamera] - Se true, aplica flip horizontal para corrigir espelhamento de selfies
Future<File> fixImageOrientation(
  File imageFile, {
  bool isFromCamera = false,
}) async {
  try {
    // Android: evitar processamento pesado em Dart (decode/encode) que pode causar
    // freeze/ANR/OOM em dispositivos com pouca memória.
    if (Platform.isAndroid) {
      print(
        '⚠️ [IMAGE_ORIENTATION] Android detectado - pulando correção para evitar travamento/crash.',
      );
      return imageFile;
    }

    print('🖼️ [IMAGE_ORIENTATION] Iniciando correção de orientação');
    print('🖼️ [IMAGE_ORIENTATION] Arquivo: ${imageFile.path}');
    print('🖼️ [IMAGE_ORIENTATION] isFromCamera: $isFromCamera');

    final int fileSize = await imageFile.length();
    print('🖼️ [IMAGE_ORIENTATION] Tamanho do arquivo: $fileSize bytes');

    // Proteção defensiva para evitar picos de memória em imagens muito grandes.
    // Nesses casos, mantemos o arquivo original para não arriscar encerramento do app.
    const int maxBytesForProcessing = 12 * 1024 * 1024; // 12 MB
    if (fileSize > maxBytesForProcessing) {
      print(
        '⚠️ [IMAGE_ORIENTATION] Arquivo muito grande para processamento seguro. Mantendo original.',
      );
      return imageFile;
    }

    // Ler os bytes da imagem somente se passar nas validações
    final Uint8List imageBytes = await imageFile.readAsBytes();

    // Decodificar a imagem (a biblioteca 'image' já lê os metadados EXIF)
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      // Se não conseguir decodificar, retorna o arquivo original
      print('⚠️ [IMAGE_ORIENTATION] Não foi possível decodificar a imagem');
      return imageFile;
    }

    print(
      '🖼️ [IMAGE_ORIENTATION] Dimensões originais: ${image.width}x${image.height}',
    );

    // A função bakeOrientation aplica a transformação indicada pelos
    // metadados EXIF diretamente nos pixels da imagem, removendo a
    // necessidade de metadados EXIF no futuro
    // IMPORTANTE: Aplicar bakeOrientation PRIMEIRO para corrigir rotações
    image = img.bakeOrientation(image);
    print(
      '🖼️ [IMAGE_ORIENTATION] Dimensões após bakeOrientation: ${image.width}x${image.height}',
    );

    // DEPOIS aplicar flip horizontal para fotos da câmera (selfies)
    // O Android mostra a pré-visualização espelhada (como um espelho),
    // mas salva a foto não espelhada, causando inversão dos lados
    // Aplicamos o flip DEPOIS do bakeOrientation para garantir que
    // a orientação já está correta antes de aplicar o espelhamento
    if (isFromCamera && Platform.isAndroid) {
      image = img.flipHorizontal(image);
      print(
        '🔄 [IMAGE_ORIENTATION] Flip horizontal aplicado no Android (correção de selfie)',
      );
      print(
        '🖼️ [IMAGE_ORIENTATION] Dimensões após flip: ${image.width}x${image.height}',
      );
    }

    // Codificar a imagem corrigida (JPEG com compressão moderada para reduzir uso de memória/rede)
    final Uint8List correctedBytes = img.encodeJpg(image, quality: 88);

    // Salvar o arquivo corrigido (sobrescreve o original)
    await imageFile.writeAsBytes(correctedBytes);

    print('✅ [IMAGE_ORIENTATION] Orientação corrigida com sucesso');
    return imageFile;
  } catch (e) {
    print('❌ [IMAGE_ORIENTATION] Erro ao corrigir orientação: $e');
    // Em caso de erro, retorna o arquivo original
    return imageFile;
  }
}
