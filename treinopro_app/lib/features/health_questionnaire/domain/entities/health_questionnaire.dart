import 'package:equatable/equatable.dart';

/// Entidade principal do questionário de saúde
class HealthQuestionnaire extends Equatable {
  final String? medicalCondition;
  final String? regularMedication;
  final String? chronicInjury;
  final String? trainingGoal;
  final String? dietaryRestrictions;
  final bool isCompleted;

  const HealthQuestionnaire({
    this.medicalCondition,
    this.regularMedication,
    this.chronicInjury,
    this.trainingGoal,
    this.dietaryRestrictions,
    this.isCompleted = false,
  });

  HealthQuestionnaire copyWith({
    String? medicalCondition,
    String? regularMedication,
    String? chronicInjury,
    String? trainingGoal,
    String? dietaryRestrictions,
    bool? isCompleted,
  }) {
    return HealthQuestionnaire(
      medicalCondition: medicalCondition ?? this.medicalCondition,
      regularMedication: regularMedication ?? this.regularMedication,
      chronicInjury: chronicInjury ?? this.chronicInjury,
      trainingGoal: trainingGoal ?? this.trainingGoal,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  bool get isStep1Valid => medicalCondition != null && regularMedication != null;
  bool get isStep2Valid => chronicInjury != null && trainingGoal != null;
  bool get isStep3Valid => dietaryRestrictions != null;

  @override
  List<Object?> get props => [
        medicalCondition,
        regularMedication,
        chronicInjury,
        trainingGoal,
        dietaryRestrictions,
        isCompleted,
      ];
}

/// Opções para as perguntas do questionário
class HealthQuestionnaireOptions {
  static const List<String> medicalConditions = [
    'Nenhuma',
    'Hipertensão',
    'Diabetes',
    'Problemas cardíacos',
    'Problemas respiratórios',
    'Outras',
  ];

  static const List<String> medicationOptions = [
    'Não',
    'Sim, ocasionalmente',
    'Sim, regularmente',
    'Prefiro não informar',
  ];

  static const List<String> injuryOptions = [
    'Nenhuma',
    'Lesão no joelho',
    'Lesão na coluna',
    'Lesão no ombro',
    'Lesão no tornozelo',
    'Outras',
  ];

  static const List<String> trainingGoals = [
    'Perda de peso',
    'Ganho de massa muscular',
    'Melhora da condição física',
    'Reabilitação',
    'Manutenção da saúde',
    'Preparação para competições',
  ];

  static const List<String> dietaryOptions = [
    'Nenhuma',
    'Vegetariano',
    'Vegano',
    'Sem glúten',
    'Sem lactose',
    'Alergias específicas',
    'Outras restrições',
  ];
}
