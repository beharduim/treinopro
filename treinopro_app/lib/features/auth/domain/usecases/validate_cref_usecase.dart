import '../entities/cref_validation_result.dart';
import '../../data/datasources/auth_api_datasource.dart';

class ValidateCrefUseCase {
  final AuthApiDataSource _authApiDataSource;

  ValidateCrefUseCase(this._authApiDataSource);

  Future<CrefValidationResult> call(String cref) async {
    try {
      final response = await _authApiDataSource.validateCref(cref);
      
      return CrefValidationResult(
        isValid: response.isValid,
        isBachelor: response.isBachelor,
        name: response.name,
        uf: response.uf,
        crefNumber: response.crefNumber,
        message: response.message,
      );
    } catch (e) {
      return CrefValidationResult(
        isValid: false,
        isBachelor: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
