import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';

class SupportApiService {
  final ApiService _apiService;

  SupportApiService({required ApiService apiService}) : _apiService = apiService;

  Future<Map<String, dynamic>> reportProblem({
    required String title,
    required String description,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/support/report-problem',
        data: {
          'title': title,
          'description': description,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Erro ao reportar problema: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic> 
            ? errorData['message'] ?? 'Erro desconhecido'
            : 'Erro ao reportar problema';
        throw Exception(errorMessage);
      } else {
        throw Exception('Erro de conexão: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }
}
