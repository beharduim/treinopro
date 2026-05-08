import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_service.dart';
import '../../../payment_methods/data/services/stripe_payment_sheet_service.dart';
import '../models/create_proposal_dto.dart';
import '../models/proposal_response_dto.dart';

/// Serviço para comunicação com a API de propostas
class ProposalsApiService {
  final http.Client _client;
  final ApiService _apiService;
  final StripePaymentSheetService _stripePaymentSheetService;
  final String _baseUrl;

  ProposalsApiService({
    required http.Client client,
    required ApiService apiService,
    required StripePaymentSheetService stripePaymentSheetService,
    String? baseUrl,
  }) : _client = client,
       _apiService = apiService,
       _stripePaymentSheetService = stripePaymentSheetService,
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  /// Criar uma nova proposta
  Future<ProposalResponseDto> createProposal(CreateProposalDto dto) async {
    try {
      print('🚀 PROPOSALS API: Criando proposta');
      print('🚀 PROPOSALS API: DTO: ${dto.toJson()}');

      final token = _apiService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final url = Uri.parse('$_baseUrl/proposals');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await _client.post(
        url,
        headers: headers,
        body: json.encode(dto.toJson()),
      );

      print('🚀 PROPOSALS API: Status: ${response.statusCode}');
      print('🚀 PROPOSALS API: Response: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        return _completeStripePaymentIfNeeded(
          ProposalResponseDto.fromJson(responseData),
        );
      } else {
        throw Exception(
          'Erro ao criar proposta: ${_extractErrorMessage(response)}',
        );
      }
    } catch (e) {
      print('🚀 PROPOSALS API: Erro: $e');
      rethrow;
    }
  }

  /// Criar uma proposta de recontratação direta
  Future<ProposalResponseDto> createRecontract(
    Map<String, dynamic> proposalData,
  ) async {
    try {
      print('🚀 PROPOSALS API: Criando recontratação');
      print('🚀 PROPOSALS API: Dados: $proposalData');

      final token = _apiService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final url = Uri.parse('$_baseUrl/proposals/recontract');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await _client.post(
        url,
        headers: headers,
        body: json.encode(proposalData),
      );

      print('🚀 PROPOSALS API: Status: ${response.statusCode}');
      print('🚀 PROPOSALS API: Response: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        return _completeStripePaymentIfNeeded(
          ProposalResponseDto.fromJson(responseData),
        );
      } else {
        throw Exception(
          'Erro ao criar recontratação: ${_extractErrorMessage(response)}',
        );
      }
    } catch (e) {
      print('❌ PROPOSALS API: Erro ao criar recontratação: $e');
      rethrow;
    }
  }

  /// Buscar propostas do usuário
  Future<List<ProposalResponseDto>> getUserProposals({
    String? status,
    int limit = 50,
    int page = 1,
  }) async {
    try {
      print('🚀 PROPOSALS API: Buscando propostas do usuário');
      print('🚀 PROPOSALS API: Status: $status, Limit: $limit, Page: $page');

      final token = _apiService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'page': page.toString(),
      };

      if (status != null) {
        queryParams['status'] = status;
      }

      final url = Uri.parse(
        '$_baseUrl/proposals',
      ).replace(queryParameters: queryParams);

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await _client.get(url, headers: headers);

      print('🚀 PROPOSALS API: Status: ${response.statusCode}');
      print('🚀 PROPOSALS API: Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final proposalsList = responseData['proposals'] as List<dynamic>;

        return proposalsList
            .map(
              (json) =>
                  ProposalResponseDto.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          'Erro ao buscar propostas: ${_extractErrorMessage(response)}',
        );
      }
    } catch (e) {
      print('🚀 PROPOSALS API: Erro ao buscar propostas: $e');
      rethrow;
    }
  }

  /// Buscar proposta por ID
  Future<ProposalResponseDto> getProposalById(String proposalId) async {
    try {
      print('🚀 PROPOSALS API: Buscando proposta por ID: $proposalId');

      final token = _apiService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final url = Uri.parse('$_baseUrl/proposals/$proposalId');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await _client.get(url, headers: headers);

      print('🚀 PROPOSALS API: Status: ${response.statusCode}');
      print('🚀 PROPOSALS API: Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        return ProposalResponseDto.fromJson(responseData);
      } else {
        throw Exception(
          'Erro ao buscar proposta: ${_extractErrorMessage(response)}',
        );
      }
    } catch (e) {
      print('🚀 PROPOSALS API: Erro ao buscar proposta: $e');
      rethrow;
    }
  }

  /// Cancelar proposta
  Future<void> cancelProposal(String proposalId) async {
    try {
      print('🚀 PROPOSALS API: Cancelando proposta: $proposalId');

      final token = _apiService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final url = Uri.parse('$_baseUrl/proposals/$proposalId');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await _client.delete(url, headers: headers);

      print('🚀 PROPOSALS API: Status: ${response.statusCode}');
      print('🚀 PROPOSALS API: Response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Erro ao cancelar proposta: ${_extractErrorMessage(response)}',
        );
      }
    } catch (e) {
      print('🚀 PROPOSALS API: Erro ao cancelar proposta: $e');
      rethrow;
    }
  }

  /// Buscar conflitos de horários para uma data específica
  Future<TimeConflictsResponse> getTimeConflicts(String date) async {
    try {
      print(
        '🔍 PROPOSALS API: Buscando conflitos de horários para data: $date',
      );

      final token = _apiService.getAccessToken();
      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      final url = Uri.parse(
        '$_baseUrl/proposals/conflicts',
      ).replace(queryParameters: {'date': date});

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await _client.get(url, headers: headers);

      print('🔍 PROPOSALS API: Status: ${response.statusCode}');
      print('🔍 PROPOSALS API: Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        return TimeConflictsResponse.fromJson(responseData);
      } else {
        throw Exception(
          'Erro ao buscar conflitos: ${_extractErrorMessage(response)}',
        );
      }
    } catch (e) {
      print('🔍 PROPOSALS API: Erro ao buscar conflitos: $e');
      rethrow;
    }
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final decoded = json.decode(response.body);

      if (decoded is Map<String, dynamic>) {
        final dynamic message = decoded['message'] ?? decoded['error'];
        if (message is List) {
          return message.map((item) => item.toString()).join(', ');
        }
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Ignora erro de parse e usa fallback abaixo
    }

    if (response.body.trim().isNotEmpty) {
      return response.body;
    }
    return 'Erro desconhecido (${response.statusCode})';
  }

  Future<ProposalResponseDto> confirmStripeProposalPayment(
    String proposalId,
  ) async {
    final token = _apiService.getAccessToken();
    if (token == null) {
      throw Exception('Token de acesso não encontrado');
    }

    final url = Uri.parse('$_baseUrl/proposals/$proposalId/stripe/confirm');
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao confirmar pagamento: ${_extractErrorMessage(response)}',
      );
    }

    final responseData = json.decode(response.body) as Map<String, dynamic>;
    return ProposalResponseDto.fromJson(responseData);
  }

  Future<ProposalResponseDto> _completeStripePaymentIfNeeded(
    ProposalResponseDto response,
  ) async {
    final payment = response.payment;
    if (payment == null ||
        payment.provider != 'stripe' ||
        payment.method == 'pix' ||
        payment.clientSecret == null ||
        payment.clientSecret!.isEmpty) {
      return response;
    }

    await _stripePaymentSheetService.presentPaymentSheet(
      clientSecret: payment.clientSecret!,
      customerId: payment.customerId ?? '',
      ephemeralKeySecret: payment.customerEphemeralKeySecret ?? '',
      publishableKey: payment.publishableKey ?? '',
    );

    return confirmStripeProposalPayment(response.id);
  }
}

/// Modelo para resposta de conflitos de horários
class TimeConflictsResponse {
  final List<ExistingProposal> existingProposals;
  final List<MatchedClass> matchedClasses;
  final List<String> blockedTimeSlots;

  TimeConflictsResponse({
    required this.existingProposals,
    required this.matchedClasses,
    required this.blockedTimeSlots,
  });

  factory TimeConflictsResponse.fromJson(Map<String, dynamic> json) {
    return TimeConflictsResponse(
      existingProposals: (json['existingProposals'] as List<dynamic>)
          .map(
            (item) => ExistingProposal.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      matchedClasses: (json['matchedClasses'] as List<dynamic>)
          .map((item) => MatchedClass.fromJson(item as Map<String, dynamic>))
          .toList(),
      blockedTimeSlots: (json['blockedTimeSlots'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
    );
  }
}

/// Modelo para proposta existente
class ExistingProposal {
  final String id;
  final String trainingTime;
  final String status;
  final int durationMinutes;

  ExistingProposal({
    required this.id,
    required this.trainingTime,
    required this.status,
    required this.durationMinutes,
  });

  factory ExistingProposal.fromJson(Map<String, dynamic> json) {
    return ExistingProposal(
      id: json['id'] as String,
      trainingTime: json['trainingTime'] as String,
      status: json['status'] as String,
      durationMinutes: json['durationMinutes'] as int,
    );
  }
}

/// Modelo para aula em match
class MatchedClass {
  final String id;
  final String time;
  final String status;
  final int duration;

  MatchedClass({
    required this.id,
    required this.time,
    required this.status,
    required this.duration,
  });

  factory MatchedClass.fromJson(Map<String, dynamic> json) {
    return MatchedClass(
      id: json['id'] as String,
      time: json['time'] as String,
      status: json['status'] as String,
      duration: json['duration'] as int,
    );
  }
}
