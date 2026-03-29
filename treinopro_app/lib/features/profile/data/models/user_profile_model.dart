class UserProfileModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? profileImageUrl;
  final String? documentNumber;
  final String? birthDate;
  final String userType; // 'student' ou 'personal'
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profileImageUrl,
    this.documentNumber,
    this.birthDate,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    // Tentar diferentes campos para a imagem de perfil
    String? profileImageUrl = json['profileImageUrl']?.toString();
    if (profileImageUrl == null || profileImageUrl.isEmpty) {
      profileImageUrl = json['imageUrl']?.toString();
    }
    if (profileImageUrl == null || profileImageUrl.isEmpty) {
      profileImageUrl = json['avatarUrl']?.toString();
    }
    if (profileImageUrl == null || profileImageUrl.isEmpty) {
      profileImageUrl = json['profileImage']?.toString();
    }
    
    print('🔍 [USER_PROFILE_MODEL] Campos de imagem encontrados:');
    print('🔍 [USER_PROFILE_MODEL] profileImageUrl: ${json['profileImageUrl']}');
    print('🔍 [USER_PROFILE_MODEL] imageUrl: ${json['imageUrl']}');
    print('🔍 [USER_PROFILE_MODEL] avatarUrl: ${json['avatarUrl']}');
    print('🔍 [USER_PROFILE_MODEL] profileImage: ${json['profileImage']}');
    print('🔍 [USER_PROFILE_MODEL] URL final selecionada: $profileImageUrl');
    
    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profileImageUrl: profileImageUrl,
      documentNumber: json['documentNumber']?.toString(),
      birthDate: json['birthDate']?.toString(),
      userType: json['userType']?.toString() ?? 'student',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'documentNumber': documentNumber,
      'birthDate': birthDate,
      'userType': userType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName';

  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }
}

class UserStatsModel {
  final String level;
  final int totalXp;
  final int completedClasses;
  final double totalEarnings;

  UserStatsModel({
    required this.level,
    required this.totalXp,
    required this.completedClasses,
    required this.totalEarnings,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    // Aceitar múltiplas nomenclaturas vindas dos serviços
    final dynamic levelRaw = json['xpLevel'] ?? json['level'];
    final dynamic totalXpRaw = json['totalXp'] ?? json['totalXP'];
    final dynamic totalEarningsRaw = json['totalEarnings'] ?? json['totalEarned'];

    return UserStatsModel(
      // Backend pode retornar numérico; manter como string para compatibilidade com UI
      level: (levelRaw ?? '1').toString(),
      totalXp: _parseInt(totalXpRaw) ?? 0,
      completedClasses: _parseInt(json['completedClasses']) ?? 0,
      totalEarnings: _parseDouble(totalEarningsRaw) ?? 0.0,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'totalXp': totalXp,
      'completedClasses': completedClasses,
      'totalEarnings': totalEarnings,
    };
  }
}
