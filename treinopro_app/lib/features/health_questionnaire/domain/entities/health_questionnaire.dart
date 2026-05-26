import 'package:equatable/equatable.dart';

/// Entidade principal do questionário de saúde (5 perguntas obrigatórias).
class HealthQuestionnaire extends Equatable {
  /// Lesão ou limitação física?
  final String? chronicInjury;

  /// Recomendação médica para evitar exercícios?
  final String? regularMedication;

  /// Dor no peito, falta de ar ou tontura?
  final String? dietaryRestrictions;

  /// Condição de saúde (pressão, diabetes, etc.)?
  final String? medicalCondition;

  /// Nível de condicionamento físico
  final String? trainingGoal;

  final bool isCompleted;

  const HealthQuestionnaire({
    this.chronicInjury,
    this.regularMedication,
    this.dietaryRestrictions,
    this.medicalCondition,
    this.trainingGoal,
    this.isCompleted = false,
  });

  HealthQuestionnaire copyWith({
    String? chronicInjury,
    String? regularMedication,
    String? dietaryRestrictions,
    String? medicalCondition,
    String? trainingGoal,
    bool? isCompleted,
  }) {
    return HealthQuestionnaire(
      chronicInjury: chronicInjury ?? this.chronicInjury,
      regularMedication: regularMedication ?? this.regularMedication,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      medicalCondition: medicalCondition ?? this.medicalCondition,
      trainingGoal: trainingGoal ?? this.trainingGoal,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  bool get isStep1Valid =>
      chronicInjury != null && regularMedication != null;
  bool get isStep2Valid =>
      dietaryRestrictions != null && medicalCondition != null;
  bool get isStep3Valid => trainingGoal != null;

  @override
  List<Object?> get props => [
        chronicInjury,
        regularMedication,
        dietaryRestrictions,
        medicalCondition,
        trainingGoal,
        isCompleted,
      ];
}

class HealthQuestionnaireOptions {
  static const List<String> physicalLimitationOptions = [
    'Nenhuma',
    'Lesão no joelho',
    'Lesão na coluna',
    'Lesão no ombro',
    'Limitação de mobilidade',
    'Outras',
  ];

  static const List<String> medicalRecommendationOptions = [
    'Não',
    'Sim, evitar exercícios de alto impacto',
    'Sim, evitar exercícios até liberação médica',
    'Prefiro não informar',
  ];

  static const List<String> chestPainSymptomsOptions = [
    'Não',
    'Sim, ocasionalmente',
    'Sim, com frequência',
    'Prefiro não informar',
  ];

  static const List<String> healthConditionOptions = [
    'Nenhuma',
    'Hipertensão',
    'Diabetes',
    'Problemas cardíacos',
    'Problemas respiratórios',
    'Outras',
  ];

  static const List<String> fitnessLevelOptions = [
    'Iniciante',
    'Intermediário',
    'Avançado',
  ];
}
