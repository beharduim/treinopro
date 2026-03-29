// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadResponse _$UploadResponseFromJson(Map<String, dynamic> json) =>
    UploadResponse(
      id: json['id'] as String,
      originalName: json['originalName'] as String,
      storedName: json['storedName'] as String,
      mimeType: json['mimeType'] as String,
      size: (json['size'] as num).toInt(),
      url: json['url'] as String,
      category: json['category'] as String,
      isProcessed: json['isProcessed'] as bool,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$UploadResponseToJson(UploadResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'originalName': instance.originalName,
      'storedName': instance.storedName,
      'mimeType': instance.mimeType,
      'size': instance.size,
      'url': instance.url,
      'category': instance.category,
      'isProcessed': instance.isProcessed,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
    };
