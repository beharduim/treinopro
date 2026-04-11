import 'class_response_dto.dart';
import 'class_timeline_dto.dart';

/// Calculadora local de timeline para evitar chamadas desnecessárias à API
/// Replica a lógica do backend: classes.service.ts -> getClassTimeline()
/// 
/// IMPORTANTE: Este calculador é usado APENAS no módulo de classes,
/// não interfere com outros módulos (como home)
class ClassTimelineCalculator {
  /// Calcula o timeline de uma aula baseado no horário atual
  static ClassTimelineDto calculate(ClassResponseDto classData) {
    final now = DateTime.now();
    
    // Combinar data e hora da aula
    final classDateTime = DateTime(
      classData.date.year,
      classData.date.month,
      classData.date.day,
      int.parse(classData.time.split(':')[0]),
      int.parse(classData.time.split(':')[1]),
    );
    
    // Calcular deadlines (mesma lógica do backend)
    final cancellationDeadline = classDateTime.subtract(const Duration(hours: 2)); // 2h antes
    final noShowReportDeadline = classDateTime.add(const Duration(minutes: 10)); // 10min depois
    
    // Janela para iniciar aula: 10min antes até 10min depois
    final startWindowBegin = classDateTime.subtract(const Duration(minutes: 10));
    final startWindowEnd = classDateTime.add(const Duration(minutes: 10));
    
    // Lógica dos botões baseada no tempo (mesma lógica do backend)
    final canCancel = now.isBefore(cancellationDeadline) && 
                      classData.status == ClassStatus.SCHEDULED;
    
    final canStart = now.isAfter(startWindowBegin) && 
                     now.isBefore(startWindowEnd) &&
                     (classData.status == ClassStatus.SCHEDULED || 
                      classData.status == ClassStatus.PENDING_CONFIRMATION);
    
    final canReportNoShow = now.isAfter(noShowReportDeadline) && 
                           (classData.status == ClassStatus.PENDING_CONFIRMATION || 
                            classData.status == ClassStatus.SCHEDULED);
    
    final canConfirmStart = classData.status == ClassStatus.PENDING_CONFIRMATION;
    
    final canReportPersonalNoShow = now.isAfter(noShowReportDeadline) && 
                                   (classData.status == ClassStatus.PENDING_CONFIRMATION || 
                                    classData.status == ClassStatus.SCHEDULED);
    
    final canComplete = classData.status == ClassStatus.ACTIVE;
    
    return ClassTimelineDto(
      matchTime: classData.createdAt,
      currentTime: now,
      classTime: classDateTime,
      canCancel: canCancel,
      canStart: canStart,
      canReportNoShow: canReportNoShow,
      canConfirmStart: canConfirmStart,
      canReportPersonalNoShow: canReportPersonalNoShow,
      canComplete: canComplete,
      cancellationDeadline: cancellationDeadline.toIso8601String(),
      noShowReportDeadline: noShowReportDeadline.toIso8601String(),
    );
  }
}
