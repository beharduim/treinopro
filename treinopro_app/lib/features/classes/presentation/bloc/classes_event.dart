import 'package:equatable/equatable.dart';
import '../../data/models/class_response_dto.dart';
import '../../data/models/get_classes_dto.dart';
import '../../data/models/start_class_dto.dart';
import '../../data/models/confirm_class_start_dto.dart';
import '../../data/models/complete_class_dto.dart';
import '../../data/models/report_no_show_dto.dart';

/// Eventos do ClassesBloc
abstract class ClassesEvent extends Equatable {
  const ClassesEvent();

  @override
  List<Object?> get props => [];
}

/// Inicializar o bloc e carregar aulas
class ClassesInitialize extends ClassesEvent {
  const ClassesInitialize();
}

/// Carregar aulas com filtros
class ClassesLoad extends ClassesEvent {
  final GetClassesDto filters;

  const ClassesLoad({required this.filters});

  @override
  List<Object?> get props => [filters];
}

/// Atualizar aulas via WebSocket
class ClassesUpdateFromWebSocket extends ClassesEvent {
  final Map<String, dynamic> data;

  const ClassesUpdateFromWebSocket({required this.data});

  @override
  List<Object?> get props => [data];
}

/// Iniciar aula
class ClassesStartClass extends ClassesEvent {
  final String classId;
  final StartClassDto dto;

  const ClassesStartClass({required this.classId, required this.dto});

  @override
  List<Object?> get props => [classId, dto];
}

/// Confirmar início da aula
class ClassesConfirmClassStart extends ClassesEvent {
  final String classId;
  final ConfirmClassStartDto dto;

  const ClassesConfirmClassStart({required this.classId, required this.dto});

  @override
  List<Object?> get props => [classId, dto];
}

/// Finalizar aula
class ClassesCompleteClass extends ClassesEvent {
  final String classId;
  final CompleteClassDto dto;

  const ClassesCompleteClass({required this.classId, required this.dto});

  @override
  List<Object?> get props => [classId, dto];
}

/// Cancelar aula
class ClassesCancelClass extends ClassesEvent {
  final String classId;

  const ClassesCancelClass({required this.classId});

  @override
  List<Object?> get props => [classId];
}

/// Reportar ausência do aluno (pelo personal)
class ClassesReportNoShow extends ClassesEvent {
  final String classId;
  final ReportNoShowDto dto;

  const ClassesReportNoShow({required this.classId, required this.dto});

  @override
  List<Object?> get props => [classId, dto];
}

/// Reportar ausência do personal (pelo aluno)
class ClassesReportPersonalNoShow extends ClassesEvent {
  final String classId;
  final ReportNoShowDto dto;

  const ClassesReportPersonalNoShow({required this.classId, required this.dto});

  @override
  List<Object?> get props => [classId, dto];
}

/// Atualizar timeline de uma aula específica
class ClassesUpdateTimeline extends ClassesEvent {
  final String classId;

  const ClassesUpdateTimeline({required this.classId});

  @override
  List<Object?> get props => [classId];
}

/// Atualizar aula específica (incremental)
class ClassesUpdateClass extends ClassesEvent {
  final ClassResponseDto classData;
  final String action;

  const ClassesUpdateClass({required this.classData, required this.action});

  @override
  List<Object?> get props => [classData, action];
}

/// Adicionar nova aula
class ClassesAddClass extends ClassesEvent {
  final ClassResponseDto classData;

  const ClassesAddClass({required this.classData});

  @override
  List<Object?> get props => [classData];
}

/// Limpar filtros
class ClassesClearFilters extends ClassesEvent {
  const ClassesClearFilters();
}

/// Atualizar apenas as fotos dos alunos (sem recarregar dados)
class ClassesUpdateStudentPhotos extends ClassesEvent {
  const ClassesUpdateStudentPhotos();
}

/// Atualizar filtros
class ClassesUpdateFilters extends ClassesEvent {
  final String? selectedDate;
  final String? selectedTime;
  final String? selectedStatus;

  const ClassesUpdateFilters({
    this.selectedDate,
    this.selectedTime,
    this.selectedStatus,
  });

  @override
  List<Object?> get props => [selectedDate, selectedTime, selectedStatus];
}

/// Refresh manual
class ClassesRefresh extends ClassesEvent {
  const ClassesRefresh();
}

/// Conectar WebSocket
class ClassesConnectWebSocket extends ClassesEvent {
  const ClassesConnectWebSocket();
}

/// Desconectar WebSocket
class ClassesDisconnectWebSocket extends ClassesEvent {
  const ClassesDisconnectWebSocket();
}

/// Iniciar timer de uma aula
class ClassesStartTimer extends ClassesEvent {
  final String classId;
  final int durationMinutes;

  const ClassesStartTimer({
    required this.classId,
    required this.durationMinutes,
  });

  @override
  List<Object?> get props => [classId, durationMinutes];
}

/// Parar timer de uma aula
class ClassesStopTimer extends ClassesEvent {
  final String classId;

  const ClassesStopTimer({required this.classId});

  @override
  List<Object?> get props => [classId];
}

/// Atualizar timer (chamado periodicamente)
class ClassesUpdateTimer extends ClassesEvent {
  const ClassesUpdateTimer();
}

/// Iniciar timer global sincronizado via WebSocket
class ClassesStartGlobalTimer extends ClassesEvent {
  final Map<String, dynamic> data;

  const ClassesStartGlobalTimer({required this.data});

  @override
  List<Object?> get props => [data];
}

/// Timer da aula chegou a zero — finalizar automaticamente
class ClassesTimerExpired extends ClassesEvent {
  final String classId;

  const ClassesTimerExpired({required this.classId});

  @override
  List<Object?> get props => [classId];
}

/// Resetar o estado do ClassesBloc (usado no logout)
class ClassesReset extends ClassesEvent {
  const ClassesReset();
}

/// Enviar defesa em disputa de no-show
class ClassesSubmitDisputeDefense extends ClassesEvent {
  final String classId;
  final String text;
  final List<String>? evidenceUrls;

  const ClassesSubmitDisputeDefense({
    required this.classId,
    required this.text,
    this.evidenceUrls,
  });

  @override
  List<Object?> get props => [classId, text, evidenceUrls];
}
