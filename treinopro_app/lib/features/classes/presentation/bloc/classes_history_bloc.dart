import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/services/classes_api_service.dart';
import '../../data/models/class_response_dto.dart';

// Events
abstract class ClassesHistoryEvent extends Equatable {
  const ClassesHistoryEvent();

  @override
  List<Object?> get props => [];
}

class ClassesHistoryLoad extends ClassesHistoryEvent {
  final int? page;
  final int? limit;
  final String? dateFrom;
  final String? dateTo;

  const ClassesHistoryLoad({
    this.page,
    this.limit,
    this.dateFrom,
    this.dateTo,
  });

  @override
  List<Object?> get props => [page, limit, dateFrom, dateTo];
}

class ClassesHistoryRefresh extends ClassesHistoryEvent {
  const ClassesHistoryRefresh();
}

// States
abstract class ClassesHistoryState extends Equatable {
  const ClassesHistoryState();

  @override
  List<Object?> get props => [];
}

class ClassesHistoryInitial extends ClassesHistoryState {}

class ClassesHistoryLoading extends ClassesHistoryState {}

class ClassesHistoryLoaded extends ClassesHistoryState {
  final List<ClassResponseDto> classes;
  final bool hasMore;
  final int currentPage;

  const ClassesHistoryLoaded({
    required this.classes,
    required this.hasMore,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [classes, hasMore, currentPage];
}

class ClassesHistoryError extends ClassesHistoryState {
  final String message;
  final List<ClassResponseDto>? previousClasses;

  const ClassesHistoryError({
    required this.message,
    this.previousClasses,
  });

  @override
  List<Object?> get props => [message, previousClasses];
}

// BLoC
class ClassesHistoryBloc extends Bloc<ClassesHistoryEvent, ClassesHistoryState> {
  final ClassesApiService _classesApiService;

  ClassesHistoryBloc({
    required ClassesApiService classesApiService,
  }) : _classesApiService = classesApiService,
       super(ClassesHistoryInitial()) {
    
    on<ClassesHistoryLoad>(_onLoad);
    on<ClassesHistoryRefresh>(_onRefresh);
  }

  Future<void> _onLoad(
    ClassesHistoryLoad event,
    Emitter<ClassesHistoryState> emit,
  ) async {
    try {
      if (state is ClassesHistoryInitial) {
        emit(ClassesHistoryLoading());
      }

      final response = await _classesApiService.getClassesHistory(
        page: event.page ?? 1,
        limit: event.limit ?? 20,
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
      );

      final List<dynamic> classesData = response['classes'] ?? [];
      final List<ClassResponseDto> classes = classesData
          .map((e) => ClassResponseDto.fromJson(e))
          .toList();

      final bool hasMore = response['hasMore'] ?? false;
      final int currentPage = response['currentPage'] ?? 1;

      emit(ClassesHistoryLoaded(
        classes: classes,
        hasMore: hasMore,
        currentPage: currentPage,
      ));
    } catch (e) {
      // Melhorar mensagem de erro para o usuário
      String userFriendlyMessage = _getUserFriendlyErrorMessage(e);
      
      emit(ClassesHistoryError(
        message: userFriendlyMessage,
        previousClasses: state is ClassesHistoryLoaded 
            ? (state as ClassesHistoryLoaded).classes 
            : null,
      ));
    }
  }

  /// Converte erros técnicos em mensagens amigáveis para o usuário
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('500') || errorString.contains('server error')) {
      return 'Servidor temporariamente indisponível. Tente novamente em alguns minutos.';
    } else if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Sessão expirada. Faça login novamente.';
    } else if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Você não tem permissão para acessar este conteúdo.';
    } else if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Histórico de aulas não encontrado.';
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Verifique sua conexão com a internet e tente novamente.';
    } else if (errorString.contains('timeout')) {
      return 'A requisição demorou muito para responder. Tente novamente.';
    } else {
      return 'Ocorreu um erro inesperado. Tente novamente mais tarde.';
    }
  }

  Future<void> _onRefresh(
    ClassesHistoryRefresh event,
    Emitter<ClassesHistoryState> emit,
  ) async {
    add(const ClassesHistoryLoad());
  }
}
