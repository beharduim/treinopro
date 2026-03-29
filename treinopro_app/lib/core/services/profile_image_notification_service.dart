import 'dart:async';

/// Serviço para notificar mudanças na foto de perfil entre páginas
class ProfileImageNotificationService {
  static final ProfileImageNotificationService _instance = ProfileImageNotificationService._internal();
  factory ProfileImageNotificationService() => _instance;
  ProfileImageNotificationService._internal();

  final StreamController<Map<String, String?>> _controller = StreamController<Map<String, String?>>.broadcast();

  /// Stream para escutar mudanças na foto de perfil
  Stream<Map<String, String?>> get profileImageStream => _controller.stream;

  /// Notifica que a foto de perfil foi atualizada
  void notifyProfileImageUpdated({String? imagePath, String? imageUrl}) {
    print('📢 [PROFILE_IMAGE_NOTIFICATION] Notificando mudança - Path: $imagePath, URL: $imageUrl');
    _controller.add({
      'imagePath': imagePath,
      'imageUrl': imageUrl,
    });
  }

  /// Notifica que o nome foi atualizado
  void notifyProfileNameUpdated({required String fullName}) {
    print('📢 [PROFILE_IMAGE_NOTIFICATION] Notificando mudança de nome - fullName: $fullName');
    _controller.add({
      'fullName': fullName,
    });
  }

  /// Limpa recursos
  void dispose() {
    _controller.close();
  }
}
