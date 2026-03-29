import 'package:equatable/equatable.dart';
import '../../domain/entities/health_questionnaire.dart';

/// Estados do BLoC do questionário de saúde
abstract class HealthQuestionnaireState extends Equatable {
  const HealthQuestionnaireState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class HealthQuestionnaireInitial extends HealthQuestionnaireState {
  const HealthQuestionnaireInitial();
}

/// Estado de carregamento
class HealthQuestionnaireLoading extends HealthQuestionnaireState {
  const HealthQuestionnaireLoading();
}

/// Estado carregado com dados
class HealthQuestionnaireLoaded extends HealthQuestionnaireState {
  final HealthQuestionnaire questionnaire;
  final int currentStep;
  final int totalSteps;

  const HealthQuestionnaireLoaded({
    required this.questionnaire,
    this.currentStep = 1,
    this.totalSteps = 3,
  });

  HealthQuestionnaireLoaded copyWith({
    HealthQuestionnaire? questionnaire,
    int? currentStep,
    int? totalSteps,
  }) {
    return HealthQuestionnaireLoaded(
      questionnaire: questionnaire ?? this.questionnaire,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }

  @override
  List<Object?> get props => [questionnaire, currentStep, totalSteps];
}

/// Estado de sucesso ao salvar
class HealthQuestionnaireSuccess extends HealthQuestionnaireState {
  final String message;

  const HealthQuestionnaireSuccess({this.message = 'Questionário salvo com sucesso!'});

  @override
  List<Object> get props => [message];
}

/// Estado de erro
class HealthQuestionnaireError extends HealthQuestionnaireState {
  final String message;

  const HealthQuestionnaireError({required this.message});

  @override
  List<Object> get props => [message];
}
