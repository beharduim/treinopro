class ConfirmClassStartDto {
  final bool confirmed;
  final String confirmationCode;
  final String? notes;

  ConfirmClassStartDto({
    required this.confirmed,
    required this.confirmationCode,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'confirmed': confirmed,
      'confirmationCode': confirmationCode,
      if (notes != null) 'notes': notes,
    };
  }
}
