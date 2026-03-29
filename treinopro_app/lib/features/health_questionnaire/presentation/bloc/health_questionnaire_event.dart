import 'package:equatable/equatable.dart';

/// Eventos do BLoC do questionário de saúde
abstract class HealthQuestionnaireEvent extends Equatable {
  const HealthQuestionnaireEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para inicializar o questionário
class InitializeQuestionnaire extends HealthQuestionnaireEvent {
  const InitializeQuestionnaire();
}

/// Evento para atualizar a primeira etapa
class UpdateStep1 extends HealthQuestionnaireEvent {
  final String? medicalCondition;
  final String? regularMedication;

  const UpdateStep1({
    this.medicalCondition,
    this.regularMedication,
  });

  @override
  List<Object?> get props => [medicalCondition, regularMedication];
}

/// Evento para atualizar a segunda etapa
class UpdateStep2 extends HealthQuestionnaireEvent {
  final String? chronicInjury;
  final String? trainingGoal;

  const UpdateStep2({
    this.chronicInjury,
    this.trainingGoal,
  });

  @override
  List<Object?> get props => [chronicInjury, trainingGoal];
}

/// Evento para atualizar a terceira etapa
class UpdateStep3 extends HealthQuestionnaireEvent {
  final String? dietaryRestrictions;

  const UpdateStep3({
    this.dietaryRestrictions,
  });

  @override
  List<Object?> get props => [dietaryRestrictions];
}

/// Evento para avançar para a próxima etapa
class NextStep extends HealthQuestionnaireEvent {
  const NextStep();
}

/// Evento para voltar para a etapa anterior
class PreviousStep extends HealthQuestionnaireEvent {
  const PreviousStep();
}

/// Evento para ir para uma etapa específica
class GoToStep extends HealthQuestionnaireEvent {
  final int step;

  const GoToStep(this.step);

  @override
  List<Object> get props => [step];
}

/// Evento para finalizar o questionário
class SubmitQuestionnaire extends HealthQuestionnaireEvent {
  const SubmitQuestionnaire();
}

/// Evento para resetar o questionário
class ResetQuestionnaire extends HealthQuestionnaireEvent {
  const ResetQuestionnaire();
}
