class ChatConversation {
  final String classId;
  final String otherParticipantId;
  final String otherParticipantName;
  final String? otherParticipantProfilePicture;
  final String? location;
  final DateTime? classDate;
  final String? classTime;
  final int? durationMinutes;
  final String? classStatus;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ChatConversation({
    required this.classId,
    required this.otherParticipantId,
    required this.otherParticipantName,
    this.otherParticipantProfilePicture,
    this.location,
    this.classDate,
    this.classTime,
    this.durationMinutes,
    this.classStatus,
    this.lastMessageText,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ChatConversation.fromJson(
    Map<String, dynamic> json, {
    required bool currentUserIsStudent,
  }) {
    final other = json['otherParticipant'] as Map<String, dynamic>? ?? {};
    final last = json['lastMessage'] as Map<String, dynamic>?;

    DateTime? parsedDate;
    final rawDate = json['date'];
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString());
    }

    DateTime? lastAt;
    if (last?['sentAt'] != null) {
      lastAt = DateTime.tryParse(last['sentAt'].toString());
    }

    return ChatConversation(
      classId: json['classId']?.toString() ?? '',
      otherParticipantId: other['id']?.toString() ?? '',
      otherParticipantName: (other['name']?.toString() ?? 'Usuário').trim(),
      otherParticipantProfilePicture: other['profilePicture']?.toString(),
      location: json['location']?.toString(),
      classDate: parsedDate,
      classTime: json['time']?.toString(),
      durationMinutes: json['duration'] is num
          ? (json['duration'] as num).toInt()
          : int.tryParse(json['duration']?.toString() ?? ''),
      classStatus: json['classStatus']?.toString(),
      lastMessageText: last?['messageText']?.toString(),
      lastMessageAt: lastAt,
      unreadCount: json['unreadCount'] is num
          ? (json['unreadCount'] as num).toInt()
          : int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
    );
  }

  String get formattedClassDate {
    if (classDate == null) return '—';
    final d = classDate!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
