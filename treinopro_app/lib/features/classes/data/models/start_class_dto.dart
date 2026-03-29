class StartClassDto {
  final String? notes;

  StartClassDto({
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'notes': notes,
    };
  }
}
