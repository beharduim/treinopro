class ReportNoShowDto {
  final String reason;
  final String? notes; // Observações adicionais
  final List<String>? evidenceUrls; // URLs das evidências (imagens)

  ReportNoShowDto({
    required this.reason,
    this.notes,
    this.evidenceUrls,
  });

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      'notes': notes,
      'evidenceUrls': evidenceUrls,
    };
  }
}
