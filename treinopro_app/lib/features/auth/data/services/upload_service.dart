import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import '../../../../core/services/api_service.dart';
import '../models/upload_response.dart';

/// Serviço responsável pelo upload de arquivos para a API
class UploadService {
  final ApiService _apiService;

  UploadService(this._apiService);

  /// Upload de documento (público - usado durante cadastro)
  /// Endpoint: POST /upload/document
  Future<UploadResponse> uploadDocument({
    required File file,
    required String documentType,
    String? description,
    Function(double)? onProgress,
  }) async {
    try {
      print('UploadService: Iniciando upload de documento: ${file.path}');

      final fileName = path.basename(file.path);
      final metadata = {
        'documentType': documentType,
        'description': description ?? 'Documento de $documentType',
      };

      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
        'category': 'document',
        'metadata': jsonEncode(metadata),
      });

      print('UploadService: FormData criado:');
      print('- fileName: $fileName');
      print('- file exists: ${await File(file.path).exists()}');
      print('- file size: ${await File(file.path).length()} bytes');
      print('- multipartFile.length: ${multipartFile.length}');
      print('- category: document');
      print('- metadata: ${jsonEncode(metadata)}');

      final response = await _apiService.dio.post(
        '/upload/document',
        data: formData,
        onSendProgress: onProgress != null
            ? (sent, total) {
                final progress = sent / total;
                onProgress(progress);
              }
            : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('UploadService: Upload de documento concluído com sucesso');
        print('UploadService: Tipo da resposta: ${response.data.runtimeType}');
        print('UploadService: Dados da resposta: ${response.data}');

        try {
          return UploadResponse.fromJson(response.data);
        } catch (parseError) {
          print('UploadService: Erro ao parsear resposta: $parseError');
          print('UploadService: Stack trace: ${StackTrace.current}');
          rethrow;
        }
      } else {
        throw Exception('Erro no upload: ${response.statusCode}');
      }
    } catch (e) {
      print('UploadService: Erro no upload de documento: $e');
      print('UploadService: Tipo do erro: ${e.runtimeType}');
      if (e is DioException) {
        print('UploadService: Status Code: ${e.response?.statusCode}');
        print('UploadService: Response Data: ${e.response?.data}');
        print('UploadService: Response Headers: ${e.response?.headers}');
        if (e.response?.data != null) {
          final errorMessage = e.response?.data is Map
              ? (e.response?.data['message'] ?? e.message)
              : e.message;
          throw Exception('Erro no upload: $errorMessage');
        }
      }
      throw Exception('Erro no upload do documento: $e');
    }
  }

  /// Upload temporário (público - usado durante cadastro)
  /// Endpoint: POST /upload/temp
  Future<UploadResponse> uploadTemp({
    required File file,
    String? description,
    Function(double)? onProgress,
  }) async {
    try {
      print('UploadService: Iniciando upload temporário: ${file.path}');

      final fileName = path.basename(file.path);
      final metadata = description != null
          ? {'description': description}
          : <String, dynamic>{};

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'category': 'temp',
        'metadata': jsonEncode(metadata),
      });

      final response = await _apiService.dio.post(
        '/upload/temp',
        data: formData,
        onSendProgress: onProgress != null
            ? (sent, total) {
                final progress = sent / total;
                onProgress(progress);
              }
            : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('UploadService: Upload temporário concluído com sucesso');
        print('UploadService: Tipo da resposta: ${response.data.runtimeType}');
        try {
          return UploadResponse.fromJson(response.data);
        } catch (parseError) {
          print('UploadService: Erro ao parsear resposta: $parseError');
          rethrow;
        }
      } else {
        throw Exception('Erro no upload: ${response.statusCode}');
      }
    } catch (e) {
      print('UploadService: Erro no upload temporário: $e');
      if (e is DioException) {
        if (e.response?.data != null) {
          final errorMessage = e.response?.data is Map
              ? (e.response?.data['message'] ?? e.message)
              : e.message;
          throw Exception('Erro no upload: $errorMessage');
        }
      }
      throw Exception('Erro no upload temporário: $e');
    }
  }

  /// Teste de upload - Debug
  Future<Map<String, dynamic>> testUpload({
    required File file,
    Function(double)? onProgress,
  }) async {
    try {
      print('UploadService: Iniciando teste de upload: ${file.path}');

      final fileName = path.basename(file.path);

      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
        'category': 'test',
        'metadata': jsonEncode({'test': 'debug'}),
      });

      print('UploadService: FormData para teste criado:');
      print('- fileName: $fileName');
      print('- file exists: ${await File(file.path).exists()}');
      print('- file size: ${await File(file.path).length()} bytes');
      print('- multipartFile.length: ${multipartFile.length}');

      final response = await _apiService.dio.post(
        '/upload/test',
        data: formData,
        onSendProgress: onProgress != null
            ? (sent, total) {
                final progress = sent / total;
                onProgress(progress);
              }
            : null,
      );

      print('UploadService: Teste de upload - resposta: ${response.data}');
      return response.data;
    } catch (e) {
      print('UploadService: Erro no teste de upload: $e');
      if (e is DioException) {
        print('UploadService: Status Code: ${e.response?.statusCode}');
        print('UploadService: Response Data: ${e.response?.data}');
        print('UploadService: Response Headers: ${e.response?.headers}');
      }
      rethrow;
    }
  }

  /// Upload de foto de perfil (autenticado)
  /// Endpoint: POST /upload/profile-image
  Future<UploadResponse> uploadProfileImage({
    required File file,
    String? description,
    Function(double)? onProgress,
  }) async {
    try {
      print('UploadService: Iniciando upload de foto de perfil: ${file.path}');

      final fileName = path.basename(file.path);
      final metadata = {
        'description': description ?? 'Foto de perfil principal',
      };

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'category': 'profile',
        'metadata': jsonEncode(metadata),
      });

      final response = await _apiService.dio.post(
        '/upload/profile-image',
        data: formData,
        onSendProgress: onProgress != null
            ? (sent, total) {
                final progress = sent / total;
                onProgress(progress);
              }
            : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('UploadService: Upload de foto de perfil concluído com sucesso');
        print('UploadService: Tipo da resposta: ${response.data.runtimeType}');
        try {
          return UploadResponse.fromJson(response.data);
        } catch (parseError) {
          print('UploadService: Erro ao parsear resposta: $parseError');
          rethrow;
        }
      } else {
        throw Exception('Erro no upload: ${response.statusCode}');
      }
    } catch (e) {
      print('UploadService: Erro no upload de foto de perfil: $e');
      if (e is DioException) {
        if (e.response?.data != null) {
          final errorMessage = e.response?.data is Map
              ? (e.response?.data['message'] ?? e.message)
              : e.message;
          throw Exception('Erro no upload: $errorMessage');
        }
      }
      throw Exception('Erro no upload da foto de perfil: $e');
    }
  }

  /// Upload de evidência de disputa (ausência) - autenticado
  /// Endpoint: POST /upload/dispute-evidence
  Future<UploadResponse> uploadDisputeEvidence({
    required File file,
    String? classId,
    String? description,
    Function(double)? onProgress,
  }) async {
    try {
      print(
        'UploadService: Iniciando upload de evidência de disputa: ${file.path}',
      );

      final fileName = path.basename(file.path);
      final metadata = {
        'classId': classId,
        'description': description ?? 'Evidência de ausência',
      };

      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
        'category': 'dispute_evidence',
        'metadata': jsonEncode(metadata),
      });

      print('UploadService: FormData para evidência de disputa criado:');
      print('- fileName: $fileName');
      print('- file exists: ${await File(file.path).exists()}');
      print('- file size: ${await File(file.path).length()} bytes');
      print('- multipartFile.length: ${multipartFile.length}');
      print('- category: dispute_evidence');
      print('- metadata: ${jsonEncode(metadata)}');

      final response = await _apiService.dio.post(
        '/upload/dispute-evidence',
        data: formData,
        onSendProgress: onProgress != null
            ? (sent, total) {
                final progress = sent / total;
                onProgress(progress);
              }
            : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(
          'UploadService: Upload de evidência de disputa concluído com sucesso',
        );
        print('UploadService: Tipo da resposta: ${response.data.runtimeType}');
        try {
          return UploadResponse.fromJson(response.data);
        } catch (parseError) {
          print('UploadService: Erro ao parsear resposta: $parseError');
          rethrow;
        }
      } else {
        throw Exception('Erro no upload: ${response.statusCode}');
      }
    } catch (e) {
      print('UploadService: Erro no upload de evidência de disputa: $e');
      if (e is DioException) {
        print('UploadService: Status Code: ${e.response?.statusCode}');
        print('UploadService: Response Data: ${e.response?.data}');
        if (e.response?.data != null) {
          final errorMessage = e.response?.data is Map
              ? (e.response?.data['message'] ?? e.message)
              : e.message;
          throw Exception('Erro no upload: $errorMessage');
        }
      }
      throw Exception('Erro no upload da evidência de disputa: $e');
    }
  }
}
