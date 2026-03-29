class CrefValidationResponse {
  final bool isValid;
  final String? nome;
  final String? uf;
  final String? crefNumber;
  final String? details;
  final String? categoria;
  final String? naturezaTitulo;
  final DateTime? validatedAt;

  const CrefValidationResponse({
    required this.isValid,
    this.nome,
    this.uf,
    this.crefNumber,
    this.details,
    this.categoria,
    this.naturezaTitulo,
    this.validatedAt,
  });

  // Getter para compatibilidade com o código existente
  String? get name => nome;
  String? get message => details;
  bool get isBachelor => naturezaTitulo?.toUpperCase().contains('BACHAREL') ?? false;

  factory CrefValidationResponse.fromJson(Map<String, dynamic> json) {
    return CrefValidationResponse(
      isValid: json['isValid'] ?? false,
      nome: json['nome'],
      uf: json['uf'],
      crefNumber: json['crefNumber'],
      details: json['details'],
      categoria: json['categoria'],
      naturezaTitulo: json['naturezaTitulo'],
      validatedAt: json['validatedAt'] != null 
          ? DateTime.parse(json['validatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'nome': nome,
      'uf': uf,
      'crefNumber': crefNumber,
      'details': details,
      'categoria': categoria,
      'naturezaTitulo': naturezaTitulo,
      'validatedAt': validatedAt?.toIso8601String(),
    };
  }
}
