import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';

class GuardianAuthorizationService {
  final Dio _dio;

  GuardianAuthorizationService(this._dio);

  /// Envia email de autorização para o responsável
  Future<Map<String, dynamic>> sendGuardianAuthorizationEmail({
    required String guardianName,
    required String guardianEmail,
    required String studentName,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/auth/send-guardian-authorization',
        data: {
          'guardianName': guardianName,
          'guardianEmail': guardianEmail,
          'studentName': studentName,
        },
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  /// Verifica o OTP do responsável
  Future<Map<String, dynamic>> verifyGuardianOtp({
    required String guardianEmail,
    required String otpCode,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/auth/verify-guardian-otp',
        data: {
          'guardianEmail': guardianEmail,
          'otpCode': otpCode,
        },
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  String _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tempo limite de conexão excedido. Verifique sua internet.';
      
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        
        if (statusCode == 400) {
          return data?['message'] ?? 'Dados inválidos';
        } else if (statusCode == 404) {
          return 'Serviço não encontrado';
        } else if (statusCode == 500) {
          return 'Erro interno do servidor';
        }
        return 'Erro na comunicação com o servidor';
      
      case DioExceptionType.cancel:
        return 'Operação cancelada';
      
      case DioExceptionType.connectionError:
        return 'Erro de conexão. Verifique sua internet.';
      
      default:
        return 'Erro de comunicação com o servidor';
    }
  }
}
