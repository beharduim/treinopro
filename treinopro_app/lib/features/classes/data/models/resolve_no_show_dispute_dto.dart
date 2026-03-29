class ResolveNoShowDisputeDto {
  final bool studentWasPresent;
  final String? adminNotes;
  final String? evidence; // URL da evidência adicional do admin

  ResolveNoShowDisputeDto({
    required this.studentWasPresent,
    this.adminNotes,
    this.evidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentWasPresent': studentWasPresent,
      'adminNotes': adminNotes,
      'evidence': evidence,
    };
  }
}
