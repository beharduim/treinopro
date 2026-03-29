class CrefValidationResult {
  final bool isValid;
  final bool isBachelor;
  final String? name;
  final String? uf;
  final String? crefNumber;
  final String? message;

  const CrefValidationResult({
    required this.isValid,
    required this.isBachelor,
    this.name,
    this.uf,
    this.crefNumber,
    this.message,
  });
}
