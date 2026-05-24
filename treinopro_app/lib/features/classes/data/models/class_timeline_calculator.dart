import 'class_response_dto.dart';
import 'class_timeline_dto.dart';

/// @deprecated Calculadora local desativada — backend é SSOT via GET /classes/:id/timeline.
@Deprecated('Use ClassesApiService.getClassTimeline()')
class ClassTimelineCalculator {
  @Deprecated('Backend é a fonte única de verdade para timeline de aulas')
  static ClassTimelineDto calculate(ClassResponseDto classData) {
    throw UnsupportedError(
      'ClassTimelineCalculator foi desativado. '
      'Use ClassesApiService.getClassTimeline(${classData.id}).',
    );
  }
}
