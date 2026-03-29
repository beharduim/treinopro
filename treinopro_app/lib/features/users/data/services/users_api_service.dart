import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_service.dart';

class UsersApiService {
  final http.Client _httpClient;
  final ApiService _apiService;
  final String _baseUrl;
  
  // Cache simples em memória para deduplicar chamadas frequentes
  // TTL curto para evitar dados antigos
  static final Map<String, Map<String, dynamic>> _basicInfoCache = <String, Map<String, dynamic>>{};
  static final Map<String, DateTime> _basicInfoCacheTime = <String, DateTime>{};
  static const Duration _basicInfoTtl = Duration(seconds: 45);

  UsersApiService({
    required http.Client client,
    required ApiService apiService,
    String? baseUrl,
  }) : _httpClient = client,
       _apiService = apiService,
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Map<String, String> get _headers {
    final token = _apiService.getAccessToken();
    if (token == null) {
      return {
        'Content-Type': 'application/json',
      };
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Busca dados de um usuário específico por ID
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      print('🔍 [USERS_API] Buscando usuário por ID: $userId');
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: _headers,
      );

      print('🔍 [USERS_API] Status da resposta: ${response.statusCode}');
      print('🔍 [USERS_API] Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 [USERS_API] Dados recebidos: $data');
        print('🔍 [USERS_API] Tipo de dados: ${data.runtimeType}');
        
        if (data is Map) {
          print('🔍 [USERS_API] Chaves disponíveis: ${data.keys.toList()}');
          print('🔍 [USERS_API] profileImageUrl: ${data['profileImageUrl']}');
          print('🔍 [USERS_API] imageUrl: ${data['imageUrl']}');
          print('🔍 [USERS_API] avatarUrl: ${data['avatarUrl']}');
          print('🔍 [USERS_API] profileImage: ${data['profileImage']}');
          print('🔍 [USERS_API] firstName: ${data['firstName']}');
          print('🔍 [USERS_API] lastName: ${data['lastName']}');
        }
        
        return data;
      } else if (response.statusCode == 404) {
        throw Exception('Usuário não encontrado');
      } else {
        throw Exception('Erro ao buscar usuário: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [USERS API] Erro ao buscar usuário: $e');
      rethrow;
    }
  }

  /// Busca dados básicos de um usuário (nome, rating, tempo na plataforma)
  Future<Map<String, dynamic>> getUserBasicInfo(String userId) async {
    try {
      // Cache hit rápido
      final cached = _basicInfoCache[userId];
      final cachedAt = _basicInfoCacheTime[userId];
      if (cached != null && cachedAt != null && DateTime.now().difference(cachedAt) < _basicInfoTtl) {
        return cached;
      }

      final userData = await getUserById(userId);
      
      String? _firstNonEmptyString(List<dynamic> candidates) {
        for (final c in candidates) {
          final v = c?.toString();
          if (v != null && v.trim().isNotEmpty) return v.trim();
        }
        return null;
      }

      double? _firstParsableDouble(List<dynamic> candidates) {
        for (final c in candidates) {
          if (c == null) continue;
          final parsed = double.tryParse(c.toString());
          if (parsed != null) return parsed;
        }
        return null;
      }

      final firstName = _firstNonEmptyString([
        userData['firstName'],
        userData['given_name'],
        userData['givenName'],
      ]);

      final lastName = _firstNonEmptyString([
        userData['lastName'],
        userData['family_name'],
        userData['familyName'],
      ]);

      final profileImageUrl = _firstNonEmptyString([
        userData['profileImageUrl'],
        userData['avatarUrl'],
        userData['imageUrl'],
        userData['photo'],
      ]);

      final rating = _firstParsableDouble([
        userData['rating'],
        userData['averageRating'],
        userData['score'],
      ])?.toString() ?? '4.5';

      final createdAt = _firstNonEmptyString([
        userData['createdAt'],
        userData['created_at'],
        userData['signupDate'],
      ]);

      final timeOnPlatform = _firstNonEmptyString([
        userData['timeOnPlatform'],
        userData['experience'],
      ]) ?? calculateTimeOnPlatform(createdAt);

      // Extrair dados relevantes com aliases e fallbacks
      final basicInfo = {
        'id': userData['id'],
        'firstName': firstName,
        'lastName': lastName,
        'email': userData['email'],
        'profileImageUrl': profileImageUrl,
        'rating': rating,
        'timeOnPlatform': timeOnPlatform,
        'userType': userData['userType'],
        'createdAt': createdAt,
      };

      print('🔍 [USERS API] Dados básicos extraídos: $basicInfo');
      // Armazenar no cache
      _basicInfoCache[userId] = basicInfo;
      _basicInfoCacheTime[userId] = DateTime.now();
      return basicInfo;
    } catch (e) {
      print('❌ [USERS API] Erro ao extrair dados básicos: $e');
      rethrow;
    }
  }

  /// Calcula dias na plataforma baseado na data de criação
  String calculateTimeOnPlatform(String? createdAt) {
    if (createdAt == null) return '7 dias';
    
    try {
      final createdDate = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(createdDate);
      final days = difference.inDays;
      
      if (days == 0) return 'Hoje';
      if (days == 1) return '1 dia';
      if (days < 7) return '$days dias';
      if (days < 30) {
        final weeks = (days / 7).floor();
        return weeks == 1 ? '1 semana' : '$weeks semanas';
      }
      if (days < 365) {
        final months = (days / 30).floor();
        return months == 1 ? '1 mês' : '$months meses';
      }
      
      final years = (days / 365).floor();
      return years == 1 ? '1 ano' : '$years anos';
    } catch (e) {
      print('❌ [USERS API] Erro ao calcular tempo na plataforma: $e');
      return '7 dias';
    }
  }
}
