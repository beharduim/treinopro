class CompleteClassDto {
  final String? notes;
  final String? studentNotes;

  CompleteClassDto({
    this.notes,
    this.studentNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (studentNotes != null && studentNotes!.isNotEmpty)
        'studentNotes': studentNotes,
    };
  }
}
