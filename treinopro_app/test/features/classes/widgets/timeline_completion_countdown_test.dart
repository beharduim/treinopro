import 'package:flutter_test/flutter_test.dart';
import 'package:treinopro_app/features/classes/presentation/widgets/timeline_completion_countdown.dart';
import 'package:treinopro_app/features/classes/data/models/class_timeline_dto.dart';

ClassTimelineDto _timeline({
  required bool canComplete,
  int? remainingToCompleteSeconds,
}) {
  return ClassTimelineDto(
    matchTime: DateTime.now(),
    currentTime: DateTime.now(),
    classTime: DateTime.now(),
    canCancel: false,
    canStart: false,
    canReportNoShow: false,
    canConfirmStart: false,
    canReportPersonalNoShow: false,
    canComplete: canComplete,
    remainingToCompleteSeconds: remainingToCompleteSeconds,
    minCompletionMinutes: 50,
  );
}

void main() {
  test('habilita finalização localmente quando countdown chega a zero', () async {
    final controller = TimelineCompletionCountdownController();
    controller.syncFromTimeline(
      _timeline(canComplete: false, remainingToCompleteSeconds: 2),
    );

    expect(controller.effectiveCanComplete, isFalse);
    expect(controller.displayRemainingSeconds, 2);

    await Future.delayed(const Duration(seconds: 3));

    expect(controller.displayRemainingSeconds, 0);
    expect(controller.effectiveCanComplete, isTrue);

    controller.dispose();
  });

  test('respeita canComplete=true da API imediatamente', () {
    final controller = TimelineCompletionCountdownController();
    controller.syncFromTimeline(_timeline(canComplete: true, remainingToCompleteSeconds: 120));

    expect(controller.effectiveCanComplete, isTrue);
    expect(controller.displayRemainingSeconds, 0);

    controller.dispose();
  });
}
