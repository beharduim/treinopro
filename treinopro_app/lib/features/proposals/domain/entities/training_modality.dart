import 'package:equatable/equatable.dart';

/// Entidade para modalidades de treino
class TrainingModality extends Equatable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final double suggestedPrice;
  final int durationMinutes;
  final String difficulty;
  final List<String> benefits;
  final bool isActive;

  const TrainingModality({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.suggestedPrice,
    required this.durationMinutes,
    required this.difficulty,
    this.benefits = const [],
    this.isActive = true,
  });

  TrainingModality copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    double? suggestedPrice,
    int? durationMinutes,
    String? difficulty,
    List<String>? benefits,
    bool? isActive,
  }) {
    return TrainingModality(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      suggestedPrice: suggestedPrice ?? this.suggestedPrice,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      difficulty: difficulty ?? this.difficulty,
      benefits: benefits ?? this.benefits,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    icon,
    color,
    suggestedPrice,
    durationMinutes,
    difficulty,
    benefits,
    isActive,
  ];
}

/// Modalidades pré-definidas
class TrainingModalityOptions {
  static const List<TrainingModality> predefinedModalities = [
    TrainingModality(
      id: 'musculacao',
      name: 'Musculação',
      description: 'Treino com pesos para ganho de massa muscular',
      icon: '💪',
      color: '#FF8C00',
      suggestedPrice: 50.0,
      durationMinutes: 60,
      difficulty: 'Intermediário',
      benefits: ['Ganho de massa', 'Força', 'Definição'],
    ),
    TrainingModality(
      id: 'cardio',
      name: 'Cardio',
      description: 'Exercícios aeróbicos para queima de gordura',
      icon: '🏃',
      color: '#00BFFF',
      suggestedPrice: 50.0,
      durationMinutes: 45,
      difficulty: 'Iniciante',
      benefits: ['Queima de gordura', 'Resistência', 'Saúde cardiovascular'],
    ),
    TrainingModality(
      id: 'funcional',
      name: 'Funcional',
      description: 'Movimentos naturais do corpo humano',
      icon: '🤸',
      color: '#32CD32',
      suggestedPrice: 50.0,
      durationMinutes: 50,
      difficulty: 'Intermediário',
      benefits: ['Mobilidade', 'Coordenação', 'Força funcional'],
    ),
    TrainingModality(
      id: 'hiit',
      name: 'HIIT',
      description: 'Treino intervalado de alta intensidade',
      icon: '🔥',
      color: '#FF4500',
      suggestedPrice: 50.0,
      durationMinutes: 30,
      difficulty: 'Avançado',
      benefits: ['Queima de gordura', 'Condicionamento', 'Eficiência'],
    ),
    TrainingModality(
      id: 'alongamento',
      name: 'Alongamento',
      description: 'Exercícios para flexibilidade e relaxamento',
      icon: '🧘',
      color: '#FF6B9D',
      suggestedPrice: 50.0,
      durationMinutes: 40,
      difficulty: 'Iniciante',
      benefits: ['Flexibilidade', 'Relaxamento', 'Postura'],
    ),
    TrainingModality(
      id: 'taf',
      name: 'TAF',
      description: 'Treinamento Aeróbico Funcional',
      icon: '✅',
      color: '#8A2BE2',
      suggestedPrice: 50.0,
      durationMinutes: 55,
      difficulty: 'Intermediário',
      benefits: ['Condicionamento', 'Força', 'Resistência'],
    ),
  ];

  /// Buscar modalidades por nome
  static List<TrainingModality> searchModalities(String query) {
    if (query.isEmpty) return predefinedModalities;

    final lowerQuery = query.toLowerCase();
    return predefinedModalities
        .where(
          (modality) =>
              modality.name.toLowerCase().contains(lowerQuery) ||
              modality.description.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  /// Obter modalidade por ID
  static TrainingModality? getModalityById(String id) {
    try {
      return predefinedModalities.firstWhere((modality) => modality.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Modalidades por nível de dificuldade
  static List<TrainingModality> getModalitiesByDifficulty(String difficulty) {
    return predefinedModalities
        .where((modality) => modality.difficulty == difficulty)
        .toList();
  }

  /// Modalidades dentro de uma faixa de preço
  static List<TrainingModality> getModalitiesByPriceRange(
    double minPrice,
    double maxPrice,
  ) {
    return predefinedModalities
        .where(
          (modality) =>
              modality.suggestedPrice >= minPrice &&
              modality.suggestedPrice <= maxPrice,
        )
        .toList();
  }
}
