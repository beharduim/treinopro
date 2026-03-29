import 'package:equatable/equatable.dart';

/// Modelo para questionário de saúde
class HealthQuestionnaireModel extends Equatable {
  final String id;
  final String userId;
  final String? medicalCondition;
  final String? regularMedication;
  final String? chronicInjury;
  final String? trainingGoal;
  final String? dietaryRestrictions;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;

  const HealthQuestionnaireModel({
    required this.id,
    required this.userId,
    this.medicalCondition,
    this.regularMedication,
    this.chronicInjury,
    this.trainingGoal,
    this.dietaryRestrictions,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
  });

  factory HealthQuestionnaireModel.fromJson(Map<String, dynamic> json) {
    return HealthQuestionnaireModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      medicalCondition: json['medicalCondition']?.toString(),
      regularMedication: json['regularMedication']?.toString(),
      chronicInjury: json['chronicInjury']?.toString(),
      trainingGoal: json['trainingGoal']?.toString(),
      dietaryRestrictions: json['dietaryRestrictions']?.toString(),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'].toString())
          : null,
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicalCondition': medicalCondition,
      'regularMedication': regularMedication,
      'chronicInjury': chronicInjury,
      'trainingGoal': trainingGoal,
      'dietaryRestrictions': dietaryRestrictions,
    };
  }

  HealthQuestionnaireModel copyWith({
    String? id,
    String? userId,
    String? medicalCondition,
    String? regularMedication,
    String? chronicInjury,
    String? trainingGoal,
    String? dietaryRestrictions,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
  }) {
    return HealthQuestionnaireModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicalCondition: medicalCondition ?? this.medicalCondition,
      regularMedication: regularMedication ?? this.regularMedication,
      chronicInjury: chronicInjury ?? this.chronicInjury,
      trainingGoal: trainingGoal ?? this.trainingGoal,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        medicalCondition,
        regularMedication,
        chronicInjury,
        trainingGoal,
        dietaryRestrictions,
        completedAt,
        createdAt,
        updatedAt,
        isCompleted,
      ];
}

/// Modelo para questionário de saúde de aluno (para personal trainers)
class StudentHealthQuestionnaireModel extends HealthQuestionnaireModel {
  final String studentName;
  final String studentEmail;

  const StudentHealthQuestionnaireModel({
    required super.id,
    required super.userId,
    super.medicalCondition,
    super.regularMedication,
    super.chronicInjury,
    super.trainingGoal,
    super.dietaryRestrictions,
    super.completedAt,
    required super.createdAt,
    required super.updatedAt,
    super.isCompleted = false,
    required this.studentName,
    required this.studentEmail,
  });

  factory StudentHealthQuestionnaireModel.fromJson(Map<String, dynamic> json) {
    return StudentHealthQuestionnaireModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      medicalCondition: json['medicalCondition']?.toString(),
      regularMedication: json['regularMedication']?.toString(),
      chronicInjury: json['chronicInjury']?.toString(),
      trainingGoal: json['trainingGoal']?.toString(),
      dietaryRestrictions: json['dietaryRestrictions']?.toString(),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'].toString())
          : null,
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
      isCompleted: json['isCompleted'] ?? false,
      studentName: json['studentName']?.toString() ?? '',
      studentEmail: json['studentEmail']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        studentName,
        studentEmail,
      ];
}
