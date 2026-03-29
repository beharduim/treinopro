import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'upload_response.g.dart';

@JsonSerializable()
class UploadResponse {
  final String id;
  final String originalName;
  final String storedName;
  final String mimeType;
  final int size;
  final String url;
  final String category;
  final bool isProcessed;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const UploadResponse({
    required this.id,
    required this.originalName,
    required this.storedName,
    required this.mimeType,
    required this.size,
    required this.url,
    required this.category,
    required this.isProcessed,
    this.metadata,
    required this.createdAt,
  });

  factory UploadResponse.fromJson(dynamic json) {
    // Trata caso onde a resposta pode vir como lista
    if (json is List) {
      if (json.isEmpty) {
        throw FormatException('Resposta vazia do servidor');
      }
      json = json[0];
    }
    
    // Garante que json é um Map
    if (json is! Map<String, dynamic>) {
      throw FormatException('Resposta inválida do servidor: esperado Map, recebido ${json.runtimeType}');
    }
    
    final Map<String, dynamic> jsonMap = json;
    
    // Trata metadata que pode vir como String JSON ou já como Map
    Map<String, dynamic>? parsedMetadata;
    if (jsonMap['metadata'] != null) {
      if (jsonMap['metadata'] is String) {
        try {
          parsedMetadata = jsonDecode(jsonMap['metadata'] as String) as Map<String, dynamic>?;
        } catch (e) {
          print('Erro ao parsear metadata como JSON: $e');
          parsedMetadata = null;
        }
      } else if (jsonMap['metadata'] is Map) {
        parsedMetadata = jsonMap['metadata'] as Map<String, dynamic>?;
      }
    }
    
    // Cria um novo Map com metadata parseado
    final Map<String, dynamic> processedJson = Map<String, dynamic>.from(jsonMap);
    processedJson['metadata'] = parsedMetadata;
    
    return _$UploadResponseFromJson(processedJson);
  }
  
  Map<String, dynamic> toJson() => _$UploadResponseToJson(this);
}
