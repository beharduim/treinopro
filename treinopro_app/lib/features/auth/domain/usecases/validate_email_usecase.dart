import '../../data/datasources/auth_api_datasource.dart';

class ValidateEmailUseCase {
  final AuthApiDataSource _repository;

  ValidateEmailUseCase(this._repository);

  Future<bool> call(String email) async {
    return await _repository.checkEmail(email);
  }
}
