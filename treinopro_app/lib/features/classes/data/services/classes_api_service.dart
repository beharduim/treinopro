import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';
import '../models/class_response_dto.dart';
import '../models/class_timeline_dto.dart';
import '../models/get_classes_dto.dart';
import '../models/start_class_dto.dart';
import '../models/confirm_class_start_dto.dart';
import '../models/complete_class_dto.dart';
import '../models/report_no_show_dto.dart';
import '../models/resolve_no_show_dispute_dto.dart';
import '../models/class_dispute_dto.dart';

class ClassesApiService {
  final Dio _dio;

  ClassesApiService({
    required Dio dio,
    required ApiService apiService,
    String? baseUrl,
  }) : _dio = dio;

  /// Obter aula criada a partir de uma proposalId
  Future<ClassResponseDto?> getClassByProposalId(String proposalId) async {
    try {
      final response = await _dio.get('/classes', queryParameters: {
        'proposalId': proposalId,
        'limit': 1,
      });
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List items = (data['classes'] ?? data['items'] ?? data['data'] ?? data['results'] ?? []) as List;
        if (items.isEmpty) return null;
        return ClassResponseDto.fromJson(items.first as Map<String, dynamic>);
      } else {
        throw Exception('Erro ao buscar aula por proposalId: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Listar aulas com filtros
  Future<Map<String, dynamic>> getClasses(GetClassesDto filters) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (filters.status != null) queryParams['status'] = filters.status!;
      if (filters.date != null) queryParams['date'] = filters.date!;
      if (filters.timeRange != null) queryParams['timeRange'] = filters.timeRange!;
      if (filters.category != null) queryParams['category'] = filters.category!;
      if (filters.page != null) queryParams['page'] = filters.page!;
      if (filters.limit != null) queryParams['limit'] = filters.limit!;

      print('🔍 [CLASSES_API] Fazendo requisição para /classes com parâmetros: $queryParams');
      final response = await _dio.get('/classes', queryParameters: queryParams);

      if (response.statusCode == 200) {
        print('🔍 [CLASSES_API] Resposta recebida com sucesso');
        print('🔍 [CLASSES_API] Status: ${response.statusCode}');
        print('🔍 [CLASSES_API] Headers: ${response.headers}');
        
        final data = response.data;
        print('🔍 [CLASSES_API] Tipo de dados: ${data.runtimeType}');
        print('🔍 [CLASSES_API] Chaves principais: ${data is Map ? data.keys.toList() : 'Não é um Map'}');
        
        if (data is Map) {
          final classes = data['classes'] as List?;
          print('🔍 [CLASSES_API] Número de aulas: ${classes?.length ?? 0}');
          
          if (classes != null && classes.isNotEmpty) {
            print('🔍 [CLASSES_API] Primeira aula - chaves: ${(classes.first as Map).keys.toList()}');
            final firstClass = classes.first as Map<String, dynamic>;
            
            // ✅ Debug: Log do studentRating recebido da API
            print('⭐ [CLASSES_API] studentRating na resposta: ${firstClass['studentRating']}');
            
            // Verificar estrutura do student
            if (firstClass.containsKey('student')) {
              final student = firstClass['student'] as Map<String, dynamic>?;
              print('🔍 [CLASSES_API] Student object: $student');
              if (student != null) {
                print('🔍 [CLASSES_API] Student keys: ${student.keys.toList()}');
                print('🔍 [CLASSES_API] Student profileImageUrl: ${student['profileImageUrl']}');
                print('🔍 [CLASSES_API] Student imageUrl: ${student['imageUrl']}');
                print('🔍 [CLASSES_API] Student avatarUrl: ${student['avatarUrl']}');
                print('🔍 [CLASSES_API] Student profileImage: ${student['profileImage']}');
              }
            }
          }
        }
        
        return data;
      } else {
        throw Exception('Erro ao buscar aulas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [CLASSES_API] Erro na requisição: $e');
      if (e.toString().contains('401')) {
        throw Exception('Usuário não autenticado - faça login novamente');
      }
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Obter aula por ID
  Future<ClassResponseDto> getClassById(String id) async {
    try {
      final response = await _dio.get('/classes/$id');

      if (response.statusCode == 200) {
        return ClassResponseDto.fromJson(response.data);
      } else {
        throw Exception('Erro ao buscar aula: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Obter timeline da aula (estados dos botões)
  Future<ClassTimelineDto> getClassTimeline(String id) async {
    try {
      final response = await _dio.get('/classes/$id/timeline');

      if (response.statusCode == 200) {
        return ClassTimelineDto.fromJson(response.data);
      } else {
        throw Exception('Erro ao buscar timeline: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Iniciar aula (personal trainer)
  Future<ClassResponseDto> startClass(String id, StartClassDto dto) async {
    try {
      final response = await _dio.post(
        '/classes/$id/start',
        data: dto.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ClassResponseDto.fromJson(response.data);
      } else {
        throw Exception('Erro ao iniciar aula: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Confirmar início da aula (aluno)
  Future<ClassResponseDto> confirmClassStart(String id, ConfirmClassStartDto dto) async {
    try {
      final response = await _dio.post(
        '/classes/$id/confirm-start',
        data: dto.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ClassResponseDto.fromJson(response.data);
      } else {
        throw Exception('Erro ao confirmar início: ${response.statusCode}');
      }
    } on DioException catch (dioE) {
      final data = dioE.response?.data;
      String msg = 'Código inválido. Verifique o código com seu personal e tente novamente.';
      if (data is Map<String, dynamic> && data['message'] != null) {
        msg = data['message'].toString();
      }
      throw Exception(msg);
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Finalizar aula
  Future<ClassResponseDto> completeClass(String id, CompleteClassDto dto) async {
    try {
      final response = await _dio.post(
        '/classes/$id/complete',
        data: dto.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ClassResponseDto.fromJson(response.data);
      } else {
        throw Exception('Erro ao finalizar aula: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (dioE) {
      final data = dioE.response?.data;
      String? msg;
      String? code;
      
      if (data is Map<String, dynamic>) {
        msg = data['message']?.toString();
        code = data['code']?.toString();
      } else if (data is String) {
        msg = data;
      }

      if (code == 'MIN_45_RULE') {
        throw Exception('MIN_45_RULE: ${msg ?? 'A aula precisa durar pelo menos 1 minuto.'}');
      }
      if (msg != null) {
        throw Exception('Erro: $msg');
      }
      throw Exception('Falha na requisição: ${dioE.message}');
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Finalizar aula automaticamente por expiração do timer
  Future<ClassResponseDto> completeClassByTimerExpiration(String id) async {
    try {
      final response = await _dio.post('/classes/$id/timer-expired');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ClassResponseDto.fromJson(response.data);
      } else {
        throw Exception('Erro ao finalizar aula por timer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Cancelar aula
  Future<ClassResponseDto> cancelClass(String id) async {
    try {
      final response = await _dio.post('/classes/$id/cancel');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ClassResponseDto.fromJson(response.data);
      } else {
        throw Exception('Erro ao cancelar aula: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Reportar ausência do aluno
  Future<ClassResponseDto> reportNoShow(String id, ReportNoShowDto dto) async {
    try {
      final response = await _dio.post(
        '/classes/$id/report-no-show',
        data: dto.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ClassResponseDto.fromJson(response.data);
      } else {
        throw Exception('Erro ao reportar ausência: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Reportar ausência do personal
  Future<ClassResponseDto> reportPersonalNoShow(String id, ReportNoShowDto dto) async {
    try {
      final response = await _dio.post(
        '/classes/$id/report-personal-no-show',
        data: dto.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ClassResponseDto.fromJson(response.data);
      } else {
        throw Exception('Erro ao reportar ausência do personal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Resolver disputa de ausência
  Future<ClassResponseDto> resolveNoShowDispute(String id, ResolveNoShowDisputeDto dto) async {
    try {
      final response = await _dio.post(
        '/classes/$id/resolve-dispute',
        data: dto.toJson(),
      );

      if (response.statusCode == 200) {
        return ClassResponseDto.fromJson(response.data);
      } else {
        throw Exception('Erro ao resolver disputa: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Listar disputas do usuário
  Future<List<ClassDisputeDto>> getClassDisputes({String status = 'all'}) async {
    try {
      final response = await _dio.get('/classes/disputes', queryParameters: {'status': status});

      if (response.statusCode == 200) {
        // Backend retorna array direto (não objeto com chave 'disputes')
        final data = response.data;
        List<dynamic> disputes;
        if (data is List) {
          disputes = data;
        } else if (data is Map) {
          disputes = (data['disputes'] ?? data['items'] ?? data['data'] ?? []) as List<dynamic>;
        } else {
          disputes = [];
        }
        return disputes.map((d) => ClassDisputeDto.fromJson(d as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Erro ao buscar disputas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Buscar disputa específica por ID (= classId)
  Future<ClassDisputeDto> getClassDisputeById(String classId) async {
    try {
      final response = await _dio.get('/classes/disputes/$classId');
      if (response.statusCode == 200) {
        return ClassDisputeDto.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Erro ao buscar disputa: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Enviar defesa (replica) em disputa de no-show
  Future<ClassResponseDto> submitDisputeDefense(String classId, String text, {List<String>? evidenceUrls}) async {
    try {
      final body = <String, dynamic>{'text': text};
      if (evidenceUrls != null && evidenceUrls.isNotEmpty) {
        body['evidenceUrls'] = evidenceUrls;
      }
      final response = await _dio.post('/classes/$classId/dispute-defense', data: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ClassResponseDto.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Erro ao enviar defesa: ${response.statusCode}');
      }
    } on DioException catch (dioE) {
      final msg = dioE.response?.data?['message'] ?? dioE.message ?? 'Erro desconhecido';
      throw Exception('Falha: $msg');
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Registrar snapshot de geolocalização de presença (idempotente)
  Future<Map<String, dynamic>> createPresenceSnapshot({
    required String classId,
    required double latitude,
    required double longitude,
    double? accuracyMeters,
    required String capturedAt,
    required String captureSource,
    required String appState,
  }) async {
    try {
      final body = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'capturedAt': capturedAt,
        'captureSource': captureSource,
        'appState': appState,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      };
      final response = await _dio.post('/classes/$classId/presence-snapshot', data: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Erro ao registrar snapshot: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  /// Listar histórico de aulas com filtros avançados
  Future<Map<String, dynamic>> getClassesHistory({
    int page = 1,
    int limit = 20,
    String? dateFrom,
    String? dateTo,
    String? status,
    String? timeRange,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (status != null) queryParams['status'] = status;
      if (timeRange != null) queryParams['timeRange'] = timeRange;
      if (category != null) queryParams['category'] = category;
      if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
      if (dateTo != null) queryParams['dateTo'] = dateTo;

      print('🔍 [CLASSES_API] Buscando histórico de aulas com parâmetros: $queryParams');

      // Usar endpoint correto /classes em vez de /classes/history
      final response = await _dio.get('/classes', queryParameters: queryParams);

      if (response.statusCode == 200) {
        print('✅ [CLASSES_API] Histórico carregado com sucesso');
        return response.data;
      } else {
        print('❌ [CLASSES_API] Erro ${response.statusCode}: ${response.data}');
        throw Exception('Erro ao buscar histórico de aulas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [CLASSES_API] Erro na requisição de histórico: $e');
      if (e.toString().contains('401')) {
        throw Exception('Usuário não autenticado - faça login novamente');
      }
      throw Exception('Erro na requisição: $e');
    }
  }


  /// Listar aulas com filtros avançados
  Future<Map<String, dynamic>> getClassesAdvanced({
    String? status,
    String? dateFrom,
    String? dateTo,
    String? timeRange,
    String? category,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (status != null) queryParams['status'] = status;
      if (timeRange != null) queryParams['timeRange'] = timeRange;
      if (category != null) queryParams['category'] = category;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
      if (dateTo != null) queryParams['dateTo'] = dateTo;

      final response = await _dio.get('/classes', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Erro ao buscar aulas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }
}
