// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: json['id'] as String,
  classId: json['classId'] as String,
  senderId: json['senderId'] as String,
  receiverId: json['receiverId'] as String,
  messageText: json['messageText'] as String,
  sentAt: DateTime.parse(json['sentAt'] as String),
  isRead: json['isRead'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  sender: SenderData.fromJson(json['sender'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'classId': instance.classId,
      'senderId': instance.senderId,
      'receiverId': instance.receiverId,
      'messageText': instance.messageText,
      'sentAt': instance.sentAt.toIso8601String(),
      'isRead': instance.isRead,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'sender': instance.sender,
    };

SenderData _$SenderDataFromJson(Map<String, dynamic> json) => SenderData(
  id: json['id'] as String,
  name: json['name'] as String,
  profilePicture: json['profilePicture'] as String?,
);

Map<String, dynamic> _$SenderDataToJson(SenderData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'profilePicture': instance.profilePicture,
    };

SendMessageDto _$SendMessageDtoFromJson(Map<String, dynamic> json) =>
    SendMessageDto(
      classId: json['classId'] as String,
      receiverId: json['receiverId'] as String,
      messageText: json['messageText'] as String,
    );

Map<String, dynamic> _$SendMessageDtoToJson(SendMessageDto instance) =>
    <String, dynamic>{
      'classId': instance.classId,
      'receiverId': instance.receiverId,
      'messageText': instance.messageText,
    };

ChatStatsDto _$ChatStatsDtoFromJson(Map<String, dynamic> json) => ChatStatsDto(
  totalMessages: (json['totalMessages'] as num).toInt(),
  unreadMessages: (json['unreadMessages'] as num).toInt(),
  conversations: (json['conversations'] as num).toInt(),
);

Map<String, dynamic> _$ChatStatsDtoToJson(ChatStatsDto instance) =>
    <String, dynamic>{
      'totalMessages': instance.totalMessages,
      'unreadMessages': instance.unreadMessages,
      'conversations': instance.conversations,
    };
