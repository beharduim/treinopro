import 'dart:io';
import '../../data/services/upload_service.dart';
import '../../data/models/upload_response.dart';

/// Use case para gerenciar uploads durante o processo de cadastro
class UploadUseCase {
  final UploadService _uploadService;

  UploadUseCase(this._uploadService);

  /// Upload de documento de identidade (RG, CNH, etc.)
  Future<UploadResponse> uploadDocument({
    required File file,
    required String documentType,
    Function(double)? onProgress,
  }) async {
    return await _uploadService.uploadDocument(
      file: file,
      documentType: documentType,
      description: 'Documento de identidade - $documentType',
      onProgress: onProgress,
    );
  }

  /// Upload de documento CREF para personal trainers
  Future<UploadResponse> uploadCrefDocument({
    required File file,
    Function(double)? onProgress,
  }) async {
    return await _uploadService.uploadDocument(
      file: file,
      documentType: 'CREF',
      description: 'Documento CREF - Personal Trainer',
      onProgress: onProgress,
    );
  }

  /// Upload temporário para qualquer arquivo durante cadastro
  Future<UploadResponse> uploadTempFile({
    required File file,
    String? description,
    Function(double)? onProgress,
  }) async {
    return await _uploadService.uploadTemp(
      file: file,
      description: description,
      onProgress: onProgress,
    );
  }

  /// Upload de foto de perfil (usado após cadastro)
  Future<UploadResponse> uploadProfileImage({
    required File file,
    Function(double)? onProgress,
  }) async {
    return await _uploadService.uploadProfileImage(
      file: file,
      description: 'Foto de perfil do usuário',
      onProgress: onProgress,
    );
  }

  /// Upload de evidência de disputa (ausência)
  Future<UploadResponse> uploadDisputeEvidence({
    required File file,
    String? classId,
    String? description,
    Function(double)? onProgress,
  }) async {
    return await _uploadService.uploadDisputeEvidence(
      file: file,
      classId: classId,
      description: description ?? 'Evidência de ausência',
      onProgress: onProgress,
    );
  }
}
