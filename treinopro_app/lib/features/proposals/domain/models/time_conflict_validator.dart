/// Modelo para representar um agendamento existente
class ExistingAppointment {
  final DateTime startTime;
  final DateTime endTime;
  final String status; // 'scheduled', 'in_progress', 'completed', 'cancelled'
  final String id;

  const ExistingAppointment({
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.id,
  });

  /// Verifica se o agendamento está ativo (agendado ou em andamento)
  bool get isActive => status == 'scheduled' || status == 'in_progress';

  /// Verifica se o agendamento foi finalizado
  bool get isCompleted => status == 'completed' || status == 'cancelled';
}

/// Validador de conflitos temporais para agendamentos
class TimeConflictValidator {
  static const Duration _lessonDuration = Duration(hours: 1);

  /// Valida se um novo horário conflita com agendamentos existentes
  static TimeConflictResult validateNewAppointment({
    required DateTime proposedStartTime,
    required List<ExistingAppointment> existingAppointments,
    Duration lessonDuration = _lessonDuration,
  }) {
    final proposedEndTime = proposedStartTime.add(lessonDuration);

    // Filtrar apenas agendamentos ativos (não finalizados)
    final activeAppointments = existingAppointments
        .where((appointment) => appointment.isActive)
        .toList();

    for (final existing in activeAppointments) {
      final conflict = _checkTimeConflict(
        proposedStart: proposedStartTime,
        proposedEnd: proposedEndTime,
        existingStart: existing.startTime,
        existingEnd: existing.endTime,
      );

      if (conflict != null) {
        return TimeConflictResult.conflict(
          conflictType: conflict,
          conflictingAppointment: existing,
        );
      }
    }

    return TimeConflictResult.valid();
  }

  /// Verifica conflito entre dois intervalos de tempo
  static ConflictType? _checkTimeConflict({
    required DateTime proposedStart,
    required DateTime proposedEnd,
    required DateTime existingStart,
    required DateTime existingEnd,
  }) {
    // Caso 1: Nova aula começaria durante aula existente
    if (_isTimeBetween(proposedStart, existingStart, existingEnd)) {
      return ConflictType.startsInMiddle;
    }

    // Caso 2: Nova aula terminaria durante aula existente
    if (_isTimeBetween(proposedEnd, existingStart, existingEnd)) {
      return ConflictType.endsInMiddle;
    }

    // Caso 3: Nova aula envolveria completamente a aula existente
    if (proposedStart.isBefore(existingStart) &&
        proposedEnd.isAfter(existingEnd)) {
      return ConflictType.wrapsAround;
    }

    // Caso 4: Nova aula seria completamente envolvida pela existente
    if (existingStart.isBefore(proposedStart) &&
        existingEnd.isAfter(proposedEnd)) {
      return ConflictType.wrappedBy;
    }

    // Caso 5: Horários exatamente iguais
    if (proposedStart.isAtSameMomentAs(existingStart)) {
      return ConflictType.exactMatch;
    }

    return null; // Sem conflito
  }

  /// Verifica se um momento está entre dois outros (exclusivo)
  static bool _isTimeBetween(DateTime time, DateTime start, DateTime end) {
    return time.isAfter(start) && time.isBefore(end);
  }

  /// Gera lista de horários sugeridos alternativos
  static List<DateTime> getSuggestedAlternatives({
    required DateTime originalTime,
    required List<ExistingAppointment> existingAppointments,
    Duration lessonDuration = _lessonDuration,
    int maxSuggestions = 3,
  }) {
    final suggestions = <DateTime>[];
    final baseDate = DateTime(
      originalTime.year,
      originalTime.month,
      originalTime.day,
    );

    // Tentar horários a cada 30 minutos do dia
    for (int hour = 6; hour <= 22; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final candidate = baseDate.add(Duration(hours: hour, minutes: minute));

        // Pular se for no passado
        if (candidate.isBefore(DateTime.now())) continue;

        final result = validateNewAppointment(
          proposedStartTime: candidate,
          existingAppointments: existingAppointments,
          lessonDuration: lessonDuration,
        );

        if (result.isValid && suggestions.length < maxSuggestions) {
          suggestions.add(candidate);
        }
      }
    }

    return suggestions;
  }
}

/// Resultado da validação de conflitos temporais
class TimeConflictResult {
  final bool isValid;
  final ConflictType? conflictType;
  final ExistingAppointment? conflictingAppointment;
  final String? errorMessage;

  const TimeConflictResult._({
    required this.isValid,
    this.conflictType,
    this.conflictingAppointment,
    this.errorMessage,
  });

  factory TimeConflictResult.valid() {
    return const TimeConflictResult._(isValid: true);
  }

  factory TimeConflictResult.conflict({
    required ConflictType conflictType,
    required ExistingAppointment conflictingAppointment,
  }) {
    return TimeConflictResult._(
      isValid: false,
      conflictType: conflictType,
      conflictingAppointment: conflictingAppointment,
      errorMessage: _getErrorMessage(conflictType, conflictingAppointment),
    );
  }

  static String _getErrorMessage(
    ConflictType type,
    ExistingAppointment appointment,
  ) {
    final startTime = _formatTime(appointment.startTime);
    final endTime = _formatTime(appointment.endTime);

    switch (type) {
      case ConflictType.exactMatch:
        return 'Você já tem uma aula agendada para este horário ($startTime)';
      case ConflictType.startsInMiddle:
        return 'Este horário conflita com sua aula das $startTime às $endTime';
      case ConflictType.endsInMiddle:
        return 'Esta aula terminaria durante sua aula das $startTime às $endTime';
      case ConflictType.wrapsAround:
        return 'Esta aula envolveria sua aula das $startTime às $endTime';
      case ConflictType.wrappedBy:
        return 'Este horário está dentro da sua aula das $startTime às $endTime';
    }
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Tipos de conflito temporal
enum ConflictType {
  exactMatch, // Horário exatamente igual
  startsInMiddle, // Começa no meio de outra aula
  endsInMiddle, // Termina no meio de outra aula
  wrapsAround, // Envolve completamente outra aula
  wrappedBy, // Está completamente dentro de outra aula
}
