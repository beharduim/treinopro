import 'package:equatable/equatable.dart';

/// Entidade para locais de treino
class TrainingLocation extends Equatable {
  final String id;
  final String name;
  final String address;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final List<String> availableModalities;
  final bool isActive;

  const TrainingLocation({
    required this.id,
    required this.name,
    required this.address,
    this.description,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.availableModalities = const [],
    this.isActive = true,
  });

  TrainingLocation copyWith({
    String? id,
    String? name,
    String? address,
    String? description,
    double? latitude,
    double? longitude,
    String? imageUrl,
    List<String>? availableModalities,
    bool? isActive,
  }) {
    return TrainingLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      availableModalities: availableModalities ?? this.availableModalities,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        description,
        latitude,
        longitude,
        imageUrl,
        availableModalities,
        isActive,
      ];

  /// Criar TrainingLocation a partir de JSON da API
  factory TrainingLocation.fromJson(Map<String, dynamic> json) {
    // ✅ Extrair coordenadas de coordinates.lat/lng ou latitude/longitude diretamente
    double? lat;
    double? lng;
    
    if (json['coordinates'] != null) {
      final coords = json['coordinates'] as Map<String, dynamic>;
      lat = (coords['lat'] as num?)?.toDouble();
      lng = (coords['lng'] as num?)?.toDouble();
    } else {
      lat = (json['latitude'] as num?)?.toDouble();
      lng = (json['longitude'] as num?)?.toDouble();
    }
    
    return TrainingLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      description: json['description'] as String?,
      latitude: lat,
      longitude: lng,
      imageUrl: json['imageUrl'] as String?,
      availableModalities: (json['availableModalities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Converter TrainingLocation para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'availableModalities': availableModalities,
      'isActive': isActive,
    };
  }
}

/// Locais pré-definidos para demonstração
class TrainingLocationOptions {
  static const List<TrainingLocation> predefinedLocations = [
    TrainingLocation(
      id: 'smartfit_01',
      name: 'Smart Fit - Shopping Vila Olímpia',
      address: 'R. Olimpíadas, 360 - Vila Olímpia, São Paulo',
      description: 'Academia completa com equipamentos modernos',
      availableModalities: ['musculacao', 'cardio', 'funcional'],
    ),
    TrainingLocation(
      id: 'bio_ritmo_01',
      name: 'Bio Ritmo - Moema',
      address: 'Av. Moema, 170 - Moema, São Paulo',
      description: 'Academia premium com piscina e sauna',
      availableModalities: ['musculacao', 'cardio', 'funcional'],
    ),
    TrainingLocation(
      id: 'parque_ibirapuera',
      name: 'Parque Ibirapuera',
      address: 'Av. Paulista, 1578 - Bela Vista, São Paulo',
      description: 'Treino ao ar livre no maior parque da cidade',
      availableModalities: ['cardio', 'funcional'],
    ),
    TrainingLocation(
      id: 'academia_formula',
      name: 'Fórmula Academia',
      address: 'R. Augusta, 2690 - Jardim Paulista, São Paulo',
      description: 'Academia boutique com personal trainers especializados',
      availableModalities: ['musculacao', 'hiit', 'funcional'],
    ),
  ];

  /// Buscar locais por nome ou endereço
  static List<TrainingLocation> searchLocations(String query) {
    if (query.isEmpty) return predefinedLocations;
    
    final lowerQuery = query.toLowerCase();
    return predefinedLocations.where((location) =>
      location.name.toLowerCase().contains(lowerQuery) ||
      location.address.toLowerCase().contains(lowerQuery) ||
      (location.description?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  /// Obter local por ID
  static TrainingLocation? getLocationById(String id) {
    try {
      return predefinedLocations.firstWhere((location) => location.id == id);
    } catch (e) {
      return null;
    }
  }
}
