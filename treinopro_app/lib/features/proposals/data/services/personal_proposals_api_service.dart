import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_service.dart';
import '../models/proposal_response_dto.dart';

/// Serviço para comunicação com a API de propostas do personal trainer
class PersonalProposalsApiService {
  final http.Client _client;
  final ApiService _apiService;
  final String _baseUrl;

  PersonalProposalsApiService({
    required http.Client client,
    required ApiService apiService,
    String? baseUrl,
  }) : _client = client,
       _apiService = apiService,
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  /// Listar propostas disponíveis para o personal trainer
  Future<Map<String, dynamic>> getProposals({
    int page = 1,
    int limit = 50,
    String? status,
    String? modality,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final token = _apiService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null) {
        queryParams['status'] = status;
      }
      if (modality != null) {
        queryParams['modality'] = modality;
      }
      if (dateFrom != null) {
        queryParams['dateFrom'] = dateFrom;
      }
      if (dateTo != null) {
        queryParams['dateTo'] = dateTo;
      }

      final url = Uri.parse('$_baseUrl/proposals').replace(
        queryParameters: queryParams,
      );

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        throw Exception('Erro ao buscar propostas: ${errorData['message'] ?? 'Erro desconhecido'}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Aceitar uma proposta
  Future<ProposalResponseDto> acceptProposal(String proposalId) async {
    try {
      final token = _apiService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final url = Uri.parse('$_baseUrl/proposals/$proposalId/accept');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await _client.post(url, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        return ProposalResponseDto.fromJson(responseData);
      } else {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message'] ?? errorData['error'] ?? 'Erro desconhecido';
        } catch (_) {
          // Se não conseguir decodificar o JSON, usar a mensagem de status
          if (response.statusCode == 400) {
            errorMessage = 'Requisição inválida';
          } else if (response.statusCode == 404) {
            errorMessage = 'Proposta não encontrada';
          } else if (response.statusCode == 409) {
            errorMessage = 'Proposta já foi aceita ou cancelada';
          } else if (response.statusCode == 500) {
            errorMessage = 'Erro interno do servidor. Tente novamente.';
          } else {
            errorMessage = 'Erro ao aceitar proposta (${response.statusCode})';
          }
        }
        throw Exception('Erro ao aceitar proposta: $errorMessage');
      }
    } catch (e) {
      rethrow;
    }
  }
}
