import '../../data/models/class_response_dto.dart';
import '../../data/models/class_timer_state.dart';

/// Verifica se a duração do treino (countdown exibido) chegou a zero.
bool isClassWorkoutDurationElapsed(ClassTimerState timer) {
  final start = timer.startTime;
  if (start == null) return false;
  final elapsed = DateTime.now().difference(start).inSeconds;
  return elapsed >= timer.durationMinutes * 60;
}

/// Dispara finalização automática quando a aula está ACTIVE e o tempo acabou.
void maybeTriggerClassTimerExpiration({
  required ClassResponseDto? currentClass,
  required ClassTimerState effectiveTimer,
  required bool alreadyTriggered,
  required void Function() onTrigger,
}) {
  if (alreadyTriggered) return;
  if (currentClass == null || currentClass.status != ClassStatus.ACTIVE) {
    return;
  }
  if (!isClassWorkoutDurationElapsed(effectiveTimer)) return;
  onTrigger();
}
