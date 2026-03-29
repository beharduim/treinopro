import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/health_questionnaire.dart';
import '../../domain/usecases/get_health_questionnaire.dart';
import '../../domain/usecases/save_health_questionnaire.dart';
import 'health_questionnaire_event.dart';
import 'health_questionnaire_state.dart';

/// BLoC para gerenciar o estado do questionário de saúde
class HealthQuestionnaireBloc extends Bloc<HealthQuestionnaireEvent, HealthQuestionnaireState> {
  final GetHealthQuestionnaire _getQuestionnaire;
  final SaveHealthQuestionnaire _saveQuestionnaire;

  HealthQuestionnaireBloc({
    required GetHealthQuestionnaire getQuestionnaire,
    required SaveHealthQuestionnaire saveQuestionnaire,
  })  : _getQuestionnaire = getQuestionnaire,
        _saveQuestionnaire = saveQuestionnaire,
        super(const HealthQuestionnaireInitial()) {
    
    on<InitializeQuestionnaire>(_onInitializeQuestionnaire);
    on<UpdateStep1>(_onUpdateStep1);
    on<UpdateStep2>(_onUpdateStep2);
    on<UpdateStep3>(_onUpdateStep3);
    on<NextStep>(_onNextStep);
    on<PreviousStep>(_onPreviousStep);
    on<GoToStep>(_onGoToStep);
    on<SubmitQuestionnaire>(_onSubmitQuestionnaire);
    on<ResetQuestionnaire>(_onResetQuestionnaire);
  }

  Future<void> _onInitializeQuestionnaire(
    InitializeQuestionnaire event,
    Emitter<HealthQuestionnaireState> emit,
  ) async {
    emit(const HealthQuestionnaireLoading());
    
    try {
      final questionnaire = await _getQuestionnaire();
      final initialQuestionnaire = questionnaire ?? const HealthQuestionnaire();
      
      emit(HealthQuestionnaireLoaded(
        questionnaire: initialQuestionnaire,
        currentStep: 1,
        totalSteps: 3,
      ));
    } catch (e) {
      emit(HealthQuestionnaireError(message: 'Erro ao carregar questionário: $e'));
    }
  }

  void _onUpdateStep1(
    UpdateStep1 event,
    Emitter<HealthQuestionnaireState> emit,
  ) {
    if (state is HealthQuestionnaireLoaded) {
      final currentState = state as HealthQuestionnaireLoaded;
      final updatedQuestionnaire = currentState.questionnaire.copyWith(
        medicalCondition: event.medicalCondition,
        regularMedication: event.regularMedication,
      );
      
      emit(currentState.copyWith(questionnaire: updatedQuestionnaire));
    }
  }

  void _onUpdateStep2(
    UpdateStep2 event,
    Emitter<HealthQuestionnaireState> emit,
  ) {
    if (state is HealthQuestionnaireLoaded) {
      final currentState = state as HealthQuestionnaireLoaded;
      final updatedQuestionnaire = currentState.questionnaire.copyWith(
        chronicInjury: event.chronicInjury,
        trainingGoal: event.trainingGoal,
      );
      
      emit(currentState.copyWith(questionnaire: updatedQuestionnaire));
    }
  }

  void _onUpdateStep3(
    UpdateStep3 event,
    Emitter<HealthQuestionnaireState> emit,
  ) {
    if (state is HealthQuestionnaireLoaded) {
      final currentState = state as HealthQuestionnaireLoaded;
      final updatedQuestionnaire = currentState.questionnaire.copyWith(
        dietaryRestrictions: event.dietaryRestrictions,
      );
      
      emit(currentState.copyWith(questionnaire: updatedQuestionnaire));
    }
  }

  void _onNextStep(
    NextStep event,
    Emitter<HealthQuestionnaireState> emit,
  ) {
    if (state is HealthQuestionnaireLoaded) {
      final currentState = state as HealthQuestionnaireLoaded;
      final nextStep = currentState.currentStep + 1;
      
      if (nextStep <= currentState.totalSteps) {
        emit(currentState.copyWith(currentStep: nextStep));
      }
    }
  }

  void _onPreviousStep(
    PreviousStep event,
    Emitter<HealthQuestionnaireState> emit,
  ) {
    if (state is HealthQuestionnaireLoaded) {
      final currentState = state as HealthQuestionnaireLoaded;
      final previousStep = currentState.currentStep - 1;
      
      if (previousStep >= 1) {
        emit(currentState.copyWith(currentStep: previousStep));
      }
    }
  }

  void _onGoToStep(
    GoToStep event,
    Emitter<HealthQuestionnaireState> emit,
  ) {
    if (state is HealthQuestionnaireLoaded) {
      final currentState = state as HealthQuestionnaireLoaded;
      
      if (event.step >= 1 && event.step <= currentState.totalSteps) {
        emit(currentState.copyWith(currentStep: event.step));
      }
    }
  }

  Future<void> _onSubmitQuestionnaire(
    SubmitQuestionnaire event,
    Emitter<HealthQuestionnaireState> emit,
  ) async {
    if (state is HealthQuestionnaireLoaded) {
      final currentState = state as HealthQuestionnaireLoaded;
      
      try {
        final completedQuestionnaire = currentState.questionnaire.copyWith(
          isCompleted: true,
        );
        
        await _saveQuestionnaire(completedQuestionnaire);
        emit(HealthQuestionnaireSuccess());
      } catch (e) {
        emit(HealthQuestionnaireError(message: 'Erro ao salvar questionário: $e'));
      }
    }
  }

  void _onResetQuestionnaire(
    ResetQuestionnaire event,
    Emitter<HealthQuestionnaireState> emit,
  ) {
    emit(const HealthQuestionnaireLoaded(
      questionnaire: HealthQuestionnaire(),
      currentStep: 1,
      totalSteps: 3,
    ));
  }
}
