class CompleteClassDto {
  final String? notes;

  CompleteClassDto({
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'notes': notes,
    };
  }
}
