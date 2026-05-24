/// Timeline de aula — SSOT: GET /classes/:id/timeline (backend NestJS).
class ClassTimelineDto {
  final DateTime matchTime;
  final DateTime currentTime;
  final DateTime classTime;
  final bool canCancel;
  final bool canStart;
  final bool canReportNoShow;
  final bool canConfirmStart;
  final bool canReportPersonalNoShow;
  final bool canComplete;
  final String? cancellationDeadline;
  final String? noShowReportDeadline;
  final String? confirmationDeadline;
  final String? timeUntilClass;
  final String? timeUntilCancellationDeadline;
  final DateTime? minimumCompletionAt;
  final int? remainingToCompleteSeconds;
  final bool hasPresenceSnapshot;
  final DateTime? startWindowBegin;
  final DateTime? startWindowEnd;
  final int? startWindowBeforeMinutes;
  final int? startWindowAfterMinutes;
  final double? cancellationWindowHours;
  final int? minCompletionMinutes;

  ClassTimelineDto({
    required this.matchTime,
    required this.currentTime,
    required this.classTime,
    required this.canCancel,
    required this.canStart,
    required this.canReportNoShow,
    required this.canConfirmStart,
    required this.canReportPersonalNoShow,
    required this.canComplete,
    this.cancellationDeadline,
    this.noShowReportDeadline,
    this.confirmationDeadline,
    this.timeUntilClass,
    this.timeUntilCancellationDeadline,
    this.minimumCompletionAt,
    this.remainingToCompleteSeconds,
    this.hasPresenceSnapshot = false,
    this.startWindowBegin,
    this.startWindowEnd,
    this.startWindowBeforeMinutes,
    this.startWindowAfterMinutes,
    this.cancellationWindowHours,
    this.minCompletionMinutes,
  });

  factory ClassTimelineDto.fromJson(Map<String, dynamic> json) {
    return ClassTimelineDto(
      matchTime: DateTime.parse(json['matchTime'] ?? DateTime.now().toIso8601String()),
      currentTime: DateTime.parse(json['currentTime'] ?? DateTime.now().toIso8601String()),
      classTime: DateTime.parse(json['classTime'] ?? DateTime.now().toIso8601String()),
      canCancel: json['canCancel'] ?? false,
      canStart: json['canStart'] ?? false,
      canReportNoShow: json['canReportNoShow'] ?? false,
      canConfirmStart: json['canConfirmStart'] ?? false,
      canReportPersonalNoShow: json['canReportPersonalNoShow'] ?? false,
      canComplete: json['canComplete'] ?? false,
      cancellationDeadline: _asIsoString(json['cancellationDeadline']),
      noShowReportDeadline: _asIsoString(json['noShowReportDeadline']),
      confirmationDeadline: json['confirmationDeadline']?.toString(),
      timeUntilClass: json['timeUntilClass']?.toString(),
      timeUntilCancellationDeadline: json['timeUntilCancellationDeadline']?.toString(),
      minimumCompletionAt: _parseDateTime(json['minimumCompletionAt']),
      remainingToCompleteSeconds: json['remainingToCompleteSeconds'] is int
          ? json['remainingToCompleteSeconds']
          : (json['remainingToCompleteSeconds'] != null
              ? int.tryParse(json['remainingToCompleteSeconds'].toString())
              : null),
      hasPresenceSnapshot: json['hasPresenceSnapshot'] ?? false,
      startWindowBegin: _parseDateTime(json['startWindowBegin']),
      startWindowEnd: _parseDateTime(json['startWindowEnd']),
      startWindowBeforeMinutes: _parseInt(json['startWindowBeforeMinutes']),
      startWindowAfterMinutes: _parseInt(json['startWindowAfterMinutes']),
      cancellationWindowHours: _parseDouble(json['cancellationWindowHours']),
      minCompletionMinutes: _parseInt(json['minCompletionMinutes']),
    );
  }

  static String? _asIsoString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'matchTime': matchTime.toIso8601String(),
      'currentTime': currentTime.toIso8601String(),
      'classTime': classTime.toIso8601String(),
      'canCancel': canCancel,
      'canStart': canStart,
      'canReportNoShow': canReportNoShow,
      'canConfirmStart': canConfirmStart,
      'canReportPersonalNoShow': canReportPersonalNoShow,
      'canComplete': canComplete,
      'cancellationDeadline': cancellationDeadline,
      'noShowReportDeadline': noShowReportDeadline,
      'confirmationDeadline': confirmationDeadline,
      'timeUntilClass': timeUntilClass,
      'timeUntilCancellationDeadline': timeUntilCancellationDeadline,
      'minimumCompletionAt': minimumCompletionAt?.toIso8601String(),
      'remainingToCompleteSeconds': remainingToCompleteSeconds,
      'hasPresenceSnapshot': hasPresenceSnapshot,
      'startWindowBegin': startWindowBegin?.toIso8601String(),
      'startWindowEnd': startWindowEnd?.toIso8601String(),
      'startWindowBeforeMinutes': startWindowBeforeMinutes,
      'startWindowAfterMinutes': startWindowAfterMinutes,
      'cancellationWindowHours': cancellationWindowHours,
      'minCompletionMinutes': minCompletionMinutes,
    };
  }

  bool get hasClassStarted => currentTime.isAfter(classTime);

  /// SSOT: usar canCancel do backend em vez de calcular 2h localmente.
  bool get isWithinCancellationWindow => canCancel;

  bool get isWithinConfirmationWindow {
    if (confirmationDeadline == null) return false;
    final deadline = DateTime.tryParse(confirmationDeadline!);
    if (deadline == null) return false;
    return currentTime.isBefore(deadline);
  }

  bool get isWithinNoShowReportWindow {
    if (noShowReportDeadline == null) return false;
    final deadline = DateTime.tryParse(noShowReportDeadline!);
    if (deadline == null) return false;
    return currentTime.isBefore(deadline);
  }

  Duration get timeUntilClassDuration {
    if (currentTime.isAfter(classTime)) return Duration.zero;
    return classTime.difference(currentTime);
  }

  Duration get timeUntilCancellationDuration {
    if (cancellationDeadline == null) return Duration.zero;
    final deadline = DateTime.tryParse(cancellationDeadline!);
    if (deadline == null) return Duration.zero;
    if (currentTime.isAfter(deadline)) return Duration.zero;
    return deadline.difference(currentTime);
  }

  String get formattedTimeUntilClass {
    final duration = timeUntilClassDuration;
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    }
    return 'Agora';
  }

  String get formattedTimeUntilCancellation {
    final duration = timeUntilCancellationDuration;
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    }
    return 'Prazo expirado';
  }
}
