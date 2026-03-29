import 'package:equatable/equatable.dart';
import '../../data/models/class_response_dto.dart';
import '../../data/models/class_timeline_dto.dart';
import '../../data/models/class_timer_state.dart';

/// Estados do ClassesBloc
abstract class ClassesState extends Equatable {
  const ClassesState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ClassesInitial extends ClassesState {
  const ClassesInitial();
}

/// Carregando aulas
class ClassesLoading extends ClassesState {
  const ClassesLoading();
}

/// Aulas carregadas com sucesso
class ClassesLoaded extends ClassesState {
  final List<ClassResponseDto> classes;
  final Map<String, ClassTimelineDto> timelines;
  final Map<String, ClassTimerState> timers;
  final String? selectedDate;
  final String? selectedTime;
  final String? selectedStatus;
  final bool isWebSocketConnected;
  final String? error;

  const ClassesLoaded({
    required this.classes,
    required this.timelines,
    required this.timers,
    this.selectedDate,
    this.selectedTime,
    this.selectedStatus,
    this.isWebSocketConnected = false,
    this.error,
  });

  @override
  List<Object?> get props => [
    classes,
    timelines,
    timers,
    selectedDate,
    selectedTime,
    selectedStatus,
    isWebSocketConnected,
    error,
  ];

  /// Cria uma cópia do estado com novos valores
  ClassesLoaded copyWith({
    List<ClassResponseDto>? classes,
    Map<String, ClassTimelineDto>? timelines,
    Map<String, ClassTimerState>? timers,
    String? selectedDate,
    String? selectedTime,
    String? selectedStatus,
    bool? isWebSocketConnected,
    String? error,
  }) {
    return ClassesLoaded(
      classes: classes ?? this.classes,
      timelines: timelines ?? this.timelines,
      timers: timers ?? this.timers,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
      error: error ?? this.error,
    );
  }
}

/// Erro ao carregar aulas
class ClassesError extends ClassesState {
  final String message;
  final List<ClassResponseDto>? classes;
  final Map<String, ClassTimelineDto>? timelines;
  final Map<String, ClassTimerState>? timers;

  const ClassesError({
    required this.message,
    this.classes,
    this.timelines,
    this.timers,
  });

  @override
  List<Object?> get props => [message, classes, timelines, timers];
}

/// Operação em andamento (iniciar, confirmar, finalizar, etc.)
class ClassesOperationInProgress extends ClassesState {
  final List<ClassResponseDto> classes;
  final Map<String, ClassTimelineDto> timelines;
  final Map<String, ClassTimerState> timers;
  final String operation;
  final String? selectedDate;
  final String? selectedTime;
  final String? selectedStatus;
  final bool isWebSocketConnected;

  const ClassesOperationInProgress({
    required this.classes,
    required this.timelines,
    required this.timers,
    required this.operation,
    this.selectedDate,
    this.selectedTime,
    this.selectedStatus,
    this.isWebSocketConnected = false,
  });

  @override
  List<Object?> get props => [
    classes,
    timelines,
    timers,
    operation,
    selectedDate,
    selectedTime,
    selectedStatus,
    isWebSocketConnected,
  ];
}

/// Operação concluída com sucesso
class ClassesOperationSuccess extends ClassesState {
  final List<ClassResponseDto> classes;
  final Map<String, ClassTimelineDto> timelines;
  final Map<String, ClassTimerState> timers;
  final String message;
  final String? selectedDate;
  final String? selectedTime;
  final String? selectedStatus;
  final bool isWebSocketConnected;

  const ClassesOperationSuccess({
    required this.classes,
    required this.timelines,
    required this.timers,
    required this.message,
    this.selectedDate,
    this.selectedTime,
    this.selectedStatus,
    this.isWebSocketConnected = false,
  });

  @override
  List<Object?> get props => [
    classes,
    timelines,
    timers,
    message,
    selectedDate,
    selectedTime,
    selectedStatus,
    isWebSocketConnected,
  ];
}

/// Aula iniciada com sucesso - navega para tracking
class ClassesStartSuccess extends ClassesState {
  final List<ClassResponseDto> classes;
  final Map<String, ClassTimelineDto> timelines;
  final Map<String, ClassTimerState> timers;
  final ClassResponseDto startedClass;
  final String? selectedDate;
  final String? selectedTime;
  final String? selectedStatus;
  final bool isWebSocketConnected;

  /// Código de confirmação de 4 dígitos — apenas presente quando iniciado localmente.
  /// Transmitido do resultado HTTP de startClass → tracking page via BLoC state.
  final String? startConfirmationCode;

  const ClassesStartSuccess({
    required this.classes,
    required this.timelines,
    required this.timers,
    required this.startedClass,
    this.selectedDate,
    this.selectedTime,
    this.selectedStatus,
    this.isWebSocketConnected = false,
    this.startConfirmationCode,
  });

  @override
  List<Object?> get props => [
    classes,
    timelines,
    timers,
    startedClass,
    selectedDate,
    selectedTime,
    selectedStatus,
    isWebSocketConnected,
    startConfirmationCode,
  ];
}

/// Aula finalizada com sucesso - navega para avaliação
class ClassesCompleteSuccess extends ClassesState {
  final List<ClassResponseDto> classes;
  final Map<String, ClassTimelineDto> timelines;
  final Map<String, ClassTimerState> timers;
  final ClassResponseDto completedClass;
  final String? selectedDate;
  final String? selectedTime;
  final String? selectedStatus;
  final bool isWebSocketConnected;

  const ClassesCompleteSuccess({
    required this.classes,
    required this.timelines,
    required this.timers,
    required this.completedClass,
    this.selectedDate,
    this.selectedTime,
    this.selectedStatus,
    this.isWebSocketConnected = false,
  });

  @override
  List<Object?> get props => [
    classes,
    timelines,
    timers,
    completedClass,
    selectedDate,
    selectedTime,
    selectedStatus,
    isWebSocketConnected,
  ];
}

/// Operação falhou
class ClassesOperationFailure extends ClassesState {
  final List<ClassResponseDto> classes;
  final Map<String, ClassTimelineDto> timelines;
  final Map<String, ClassTimerState> timers;
  final String error;
  final String? selectedDate;
  final String? selectedTime;
  final String? selectedStatus;
  final bool isWebSocketConnected;

  const ClassesOperationFailure({
    required this.classes,
    required this.timelines,
    required this.timers,
    required this.error,
    this.selectedDate,
    this.selectedTime,
    this.selectedStatus,
    this.isWebSocketConnected = false,
  });

  @override
  List<Object?> get props => [
    classes,
    timelines,
    timers,
    error,
    selectedDate,
    selectedTime,
    selectedStatus,
    isWebSocketConnected,
  ];
}
