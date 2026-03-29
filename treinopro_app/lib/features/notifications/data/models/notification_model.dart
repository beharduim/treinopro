import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Modelo para notificação
class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Parse do campo createdAt - pode vir como string, DateTime ou número (timestamp)
    DateTime createdAt;
    try {
      if (json['createdAt'] == null) {
        createdAt = DateTime.now();
      } else if (json['createdAt'] is DateTime) {
        createdAt = json['createdAt'] as DateTime;
      } else if (json['createdAt'] is String) {
        createdAt = DateTime.parse(json['createdAt'] as String);
      } else if (json['createdAt'] is int) {
        // Se vier como timestamp (milissegundos)
        createdAt = DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int);
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      print('⚠️ [NOTIFICATION_MODEL] Erro ao parsear createdAt: $e');
      print('⚠️ [NOTIFICATION_MODEL] Valor recebido: ${json['createdAt']}');
      createdAt = DateTime.now();
    }

    // Parse do campo data - pode vir como Map, null ou string JSON
    Map<String, dynamic>? data;
    try {
      if (json['data'] == null) {
        data = null;
      } else if (json['data'] is Map) {
        data = Map<String, dynamic>.from(json['data'] as Map);
      } else if (json['data'] is String) {
        // Se vier como string JSON, fazer parse
        final decoded = jsonDecode(json['data'] as String);
        data = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      }
    } catch (e) {
      data = null;
    }

    // Validar campos obrigatórios
    final id = json['id']?.toString();
    final title = json['title']?.toString();
    final message = json['message']?.toString();
    
    if (id == null || id.isEmpty) {
      throw Exception('NotificationModel: campo id é obrigatório');
    }
    if (title == null || title.isEmpty) {
      throw Exception('NotificationModel: campo title é obrigatório');
    }
    if (message == null || message.isEmpty) {
      throw Exception('NotificationModel: campo message é obrigatório');
    }
    
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: json['type']?.toString() ?? 'info',
      isRead: json['isRead'] == true || json['isRead'] == 'true',
      createdAt: createdAt,
      data: data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        type,
        isRead,
        createdAt,
        data,
      ];
}
