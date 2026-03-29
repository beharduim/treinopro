import '../../../users/data/services/users_api_service.dart';
import '../../../../core/config/app_config.dart';

class StudentPhotoCacheService {
  final UsersApiService _usersApiService;
  final Map<String, String?> _photoCache = {};
  final Set<String> _loadingStudents = {};

  StudentPhotoCacheService({
    required UsersApiService usersApiService,
  }) : _usersApiService = usersApiService;

  /// Busca a foto de um aluno, usando cache quando possível
  Future<String?> getStudentPhoto(String studentId) async {
    // Se já está no cache, retorna imediatamente
    if (_photoCache.containsKey(studentId)) {
      return _photoCache[studentId];
    }

    // Se já está carregando, aguarda
    if (_loadingStudents.contains(studentId)) {
      // Aguarda um pouco e tenta novamente
      await Future.delayed(const Duration(milliseconds: 100));
      return _photoCache[studentId];
    }

    // Marca como carregando
    _loadingStudents.add(studentId);

    try {
      print('🔍 [PHOTO_CACHE] Buscando foto do aluno: $studentId');
      print('🔍 [PHOTO_CACHE] Chamando UsersApiService.getUserById...');
      
      final userData = await _usersApiService.getUserById(studentId);
      print('🔍 [PHOTO_CACHE] Resposta do UsersApiService recebida');
      
      // Tentar diferentes campos para a foto
      String? photoUrl = userData['profileImageUrl']?.toString();
      if (photoUrl == null || photoUrl.isEmpty) {
        photoUrl = userData['imageUrl']?.toString();
      }
      if (photoUrl == null || photoUrl.isEmpty) {
        photoUrl = userData['avatarUrl']?.toString();
      }
      if (photoUrl == null || photoUrl.isEmpty) {
        photoUrl = userData['profileImage']?.toString();
      }

      // Normalizar URL relativa para absoluta
      if (photoUrl != null && photoUrl.isNotEmpty &&
          !(photoUrl.startsWith('http://') || photoUrl.startsWith('https://'))) {
        final base = AppConfig.apiBaseUrl;
        final needsSlash = !(photoUrl.startsWith('/'));
        photoUrl = '$base${needsSlash ? '/' : ''}$photoUrl';
      }

      print('🔍 [PHOTO_CACHE] Foto encontrada para $studentId: $photoUrl');
      
      // Armazena no cache (mesmo se for null)
      _photoCache[studentId] = photoUrl;
      
      return photoUrl;
    } catch (e) {
      print('❌ [PHOTO_CACHE] Erro ao buscar foto do aluno $studentId: $e');
      // Armazena null no cache para evitar tentativas repetidas
      _photoCache[studentId] = null;
      return null;
    } finally {
      _loadingStudents.remove(studentId);
    }
  }

  /// Limpa o cache
  void clearCache() {
    _photoCache.clear();
    _loadingStudents.clear();
  }

  /// Remove um aluno específico do cache
  void removeFromCache(String studentId) {
    _photoCache.remove(studentId);
    _loadingStudents.remove(studentId);
  }

  /// Retorna o tamanho atual do cache
  int get cacheSize => _photoCache.length;

  /// Retorna se um aluno está sendo carregado
  bool isLoading(String studentId) => _loadingStudents.contains(studentId);
}
