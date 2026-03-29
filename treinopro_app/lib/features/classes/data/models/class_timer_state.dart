class ClassTimerState {
  final String classId;
  final DateTime? startTime;
  final int durationMinutes;
  final bool isActive;
  final bool isCompleted;
  final int? remainingSeconds; // Campo direto para timer global

  const ClassTimerState({
    required this.classId,
    this.startTime,
    required this.durationMinutes,
    this.isActive = false,
    this.isCompleted = false,
    this.remainingSeconds,
  });

  /// Tempo restante em segundos
  int get remainingSecondsCalculated {
    if (remainingSeconds != null) {
      return remainingSeconds!; // Usar valor direto se disponível
    }
    
    if (!isActive || startTime == null) return 0;
    
    final now = DateTime.now();
    final elapsed = now.difference(startTime!).inSeconds;
    final totalSeconds = durationMinutes * 60;
    final remaining = totalSeconds - elapsed;
    
    return remaining > 0 ? remaining : 0;
  }

  /// Tempo decorrido em segundos
  int get elapsedSeconds {
    if (!isActive || startTime == null) return 0;
    
    final now = DateTime.now();
    final elapsed = now.difference(startTime!).inSeconds;
    final totalSeconds = durationMinutes * 60;
    
    return elapsed > totalSeconds ? totalSeconds : elapsed;
  }

  /// Porcentagem de progresso (0.0 a 1.0)
  double get progressPercentage {
    if (!isActive || startTime == null) return 0.0;
    
    final elapsed = elapsedSeconds;
    final total = durationMinutes * 60;
    
    return elapsed / total;
  }

  /// Se o timer está próximo do fim (últimos 5 minutos)
  bool get isNearEnd {
    return remainingSecondsCalculated <= 300; // 5 minutos
  }

  /// Se o timer expirou
  bool get hasExpired {
    return remainingSecondsCalculated <= 0;
  }

  ClassTimerState copyWith({
    String? classId,
    DateTime? startTime,
    int? durationMinutes,
    bool? isActive,
    bool? isCompleted,
    int? remainingSeconds,
  }) {
    return ClassTimerState(
      classId: classId ?? this.classId,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }

  @override
  String toString() {
    return 'ClassTimerState(classId: $classId, startTime: $startTime, durationMinutes: $durationMinutes, isActive: $isActive, isCompleted: $isCompleted, remainingSeconds: $remainingSecondsCalculated)';
  }
}
