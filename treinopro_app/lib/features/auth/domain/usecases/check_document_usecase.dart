import '../../data/datasources/auth_api_datasource.dart';

class CheckDocumentUseCase {
  final AuthApiDataSource _repository;

  CheckDocumentUseCase(this._repository);

  Future<bool> call(String documentType, String documentNumber) async {
    return await _repository.checkDocument(documentType, documentNumber);
  }
}
