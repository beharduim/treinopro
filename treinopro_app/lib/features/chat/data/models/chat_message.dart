import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

@JsonSerializable()
class ChatMessage {
  final String id;
  final String classId;
  final String senderId;
  final String receiverId;
  final String messageText;
  final DateTime sentAt;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final SenderData sender;

  const ChatMessage({
    required this.id,
    required this.classId,
    required this.senderId,
    required this.receiverId,
    required this.messageText,
    required this.sentAt,
    required this.isRead,
    required this.createdAt,
    this.updatedAt,
    required this.sender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

@JsonSerializable()
class SenderData {
  final String id;
  final String name;
  final String? profilePicture;

  const SenderData({
    required this.id,
    required this.name,
    this.profilePicture,
  });

  factory SenderData.fromJson(Map<String, dynamic> json) =>
      _$SenderDataFromJson(json);

  Map<String, dynamic> toJson() => _$SenderDataToJson(this);
}

@JsonSerializable()
class SendMessageDto {
  final String classId;
  final String receiverId;
  final String messageText;

  const SendMessageDto({
    required this.classId,
    required this.receiverId,
    required this.messageText,
  });

  factory SendMessageDto.fromJson(Map<String, dynamic> json) =>
      _$SendMessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SendMessageDtoToJson(this);
}

@JsonSerializable()
class ChatStatsDto {
  final int totalMessages;
  final int unreadMessages;
  final int conversations;

  const ChatStatsDto({
    required this.totalMessages,
    required this.unreadMessages,
    required this.conversations,
  });

  factory ChatStatsDto.fromJson(Map<String, dynamic> json) =>
      _$ChatStatsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ChatStatsDtoToJson(this);
}
