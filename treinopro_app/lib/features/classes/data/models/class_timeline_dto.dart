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
      cancellationDeadline: json['cancellationDeadline'],
      noShowReportDeadline: json['noShowReportDeadline'],
      confirmationDeadline: json['confirmationDeadline'],
      timeUntilClass: json['timeUntilClass'],
      timeUntilCancellationDeadline: json['timeUntilCancellationDeadline'],
      minimumCompletionAt: json['minimumCompletionAt'] != null
          ? DateTime.tryParse(json['minimumCompletionAt'])
          : null,
      remainingToCompleteSeconds: json['remainingToCompleteSeconds'] is int
          ? json['remainingToCompleteSeconds']
          : (json['remainingToCompleteSeconds'] != null
              ? int.tryParse(json['remainingToCompleteSeconds'].toString())
              : null),
      hasPresenceSnapshot: json['hasPresenceSnapshot'] ?? false,
    );
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
    };
  }

  /// Verifica se a aula já começou
  bool get hasClassStarted => currentTime.isAfter(classTime);

  /// Verifica se ainda pode cancelar (dentro do prazo de 2h antes)
  bool get isWithinCancellationWindow {
    if (cancellationDeadline == null) return false;
    final deadline = DateTime.parse(cancellationDeadline!);
    return currentTime.isBefore(deadline);
  }

  /// Verifica se está dentro do prazo de confirmação (5-10 minutos)
  bool get isWithinConfirmationWindow {
    if (confirmationDeadline == null) return false;
    final deadline = DateTime.parse(confirmationDeadline!);
    return currentTime.isBefore(deadline);
  }

  /// Verifica se está dentro do prazo para reportar ausência
  bool get isWithinNoShowReportWindow {
    if (noShowReportDeadline == null) return false;
    final deadline = DateTime.parse(noShowReportDeadline!);
    return currentTime.isBefore(deadline);
  }

  /// Calcula tempo restante até a aula
  Duration get timeUntilClassDuration {
    final now = currentTime;
    final classStart = classTime;
    
    if (now.isAfter(classStart)) {
      return Duration.zero;
    }
    
    return classStart.difference(now);
  }

  /// Calcula tempo restante até o deadline de cancelamento
  Duration get timeUntilCancellationDuration {
    if (cancellationDeadline == null) return Duration.zero;
    
    final now = currentTime;
    final deadline = DateTime.parse(cancellationDeadline!);
    
    if (now.isAfter(deadline)) {
      return Duration.zero;
    }
    
    return deadline.difference(now);
  }

  /// Retorna uma string formatada do tempo restante
  String get formattedTimeUntilClass {
    final duration = timeUntilClassDuration;
    
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Agora';
    }
  }

  /// Retorna uma string formatada do tempo restante para cancelamento
  String get formattedTimeUntilCancellation {
    final duration = timeUntilCancellationDuration;
    
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Prazo expirado';
    }
  }
}
