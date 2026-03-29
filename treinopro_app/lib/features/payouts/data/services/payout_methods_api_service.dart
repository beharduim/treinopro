import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_service.dart';

class PayoutMethodsApiService {
  final http.Client _client;
  final ApiService _apiService;
  final String _baseUrl;

  PayoutMethodsApiService({
    required http.Client client,
    required ApiService apiService,
    String? baseUrl,
  }) : _client = client,
       _apiService = apiService,
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Map<String, String> get _headers {
    final token = _apiService.getAccessToken();
    if (token == null) {
      return {
        'Content-Type': 'application/json',
      };
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Cadastra método de recebimento (conta bancária)
  Future<Map<String, dynamic>> createBankAccount({
    required String bankName,
    required String agency,
    required String account,
    required String holderName,
    required String document,
  }) async {
    try {
      print('🏦 [PAYOUT API] Cadastrando conta bancária...');
      
      final response = await _client.put(
        Uri.parse('$_baseUrl/payments/profile/financial'),
        headers: _headers,
        body: json.encode({
          'preferredMethod': 'bank_transfer',
          'bankAccount': {
            'bankCode': '001', // Código padrão, pode ser ajustado
            'bankName': bankName,
            'agency': agency,
            'accountNumber': account,
            'accountType': 'checking',
            'accountHolderName': holderName,
            'document': document,
          },
        }),
      );

      print('🏦 [PAYOUT API] Status da resposta: ${response.statusCode}');
      print('🏦 [PAYOUT API] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('🏦 [PAYOUT API] Conta bancária cadastrada: $data');
        return data;
      } else {
        throw Exception('Erro ao cadastrar conta bancária: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [PAYOUT API] Erro ao cadastrar conta bancária: $e');
      throw Exception('Falha ao conectar com a API de métodos de recebimento: $e');
    }
  }

  /// Cadastra método de recebimento (Mercado Pago)
  Future<Map<String, dynamic>> createMercadoPago({
    required String email,
    required String document,
  }) async {
    try {
      print('💳 [PAYOUT API] Cadastrando Mercado Pago...');
      
      final response = await _client.put(
        Uri.parse('$_baseUrl/payments/profile/financial'),
        headers: _headers,
        body: json.encode({
          'preferredMethod': 'mercado_pago',
          'mercadoPagoAccount': {
            'email': email,
            'document': document,
            'accessToken': '', // Será preenchido pelo backend
          },
        }),
      );

      print('💳 [PAYOUT API] Status da resposta: ${response.statusCode}');
      print('💳 [PAYOUT API] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('💳 [PAYOUT API] Mercado Pago cadastrado: $data');
        return data;
      } else {
        throw Exception('Erro ao cadastrar Mercado Pago: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [PAYOUT API] Erro ao cadastrar Mercado Pago: $e');
      throw Exception('Falha ao conectar com a API de métodos de recebimento: $e');
    }
  }

  /// Busca métodos de recebimento do usuário
  Future<Map<String, dynamic>> getPayoutMethods() async {
    try {
      print('📋 [PAYOUT API] Buscando métodos de recebimento...');
      
      final response = await _client.get(
        Uri.parse('$_baseUrl/payments/profile/financial'),
        headers: _headers,
      );

      print('📋 [PAYOUT API] Status da resposta: ${response.statusCode}');
      print('📋 [PAYOUT API] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📋 [PAYOUT API] Métodos encontrados: $data');
        return data['data']; // Extrair dados do wrapper de resposta
      } else if (response.statusCode == 404) {
        // Fallback: retornar estrutura vazia segura para UI
        print('📋 [PAYOUT API] /payments/profile/financial não encontrado (404). Usando fallback vazio.');
        return {
          'preferredMethod': null,
          'bankAccount': null,
          'mercadoPagoAccount': null,
        };
      } else {
        throw Exception('Erro ao buscar métodos de recebimento: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [PAYOUT API] Erro ao buscar métodos de recebimento: $e');
      throw Exception('Falha ao conectar com a API de métodos de recebimento: $e');
    }
  }

  /// Atualiza método de recebimento (conta bancária)
  Future<Map<String, dynamic>> updateBankAccount({
    required String id,
    required String bankName,
    required String agency,
    required String account,
    required String holderName,
    required String document,
  }) async {
    try {
      print('🏦 [PAYOUT API] Atualizando conta bancária...');
      
      final response = await _client.put(
        Uri.parse('$_baseUrl/payments/profile/financial'),
        headers: _headers,
        body: json.encode({
          'preferredMethod': 'bank_transfer',
          'bankAccount': {
            'bankCode': '001', // Código padrão, pode ser ajustado
            'bankName': bankName,
            'agency': agency,
            'accountNumber': account,
            'accountType': 'checking',
            'accountHolderName': holderName,
            'document': document,
          },
        }),
      );

      print('🏦 [PAYOUT API] Status da resposta: ${response.statusCode}');
      print('🏦 [PAYOUT API] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🏦 [PAYOUT API] Conta bancária atualizada: $data');
        return data;
      } else {
        throw Exception('Erro ao atualizar conta bancária: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [PAYOUT API] Erro ao atualizar conta bancária: $e');
      throw Exception('Falha ao conectar com a API de métodos de recebimento: $e');
    }
  }

  /// Atualiza método de recebimento (Mercado Pago)
  Future<Map<String, dynamic>> updateMercadoPago({
    required String id,
    required String email,
    required String document,
  }) async {
    try {
      print('💳 [PAYOUT API] Atualizando Mercado Pago...');
      
      final response = await _client.put(
        Uri.parse('$_baseUrl/payments/profile/financial'),
        headers: _headers,
        body: json.encode({
          'preferredMethod': 'mercado_pago',
          'mercadoPagoAccount': {
            'email': email,
            'document': document,
            'accessToken': '', // Será preenchido pelo backend
          },
        }),
      );

      print('💳 [PAYOUT API] Status da resposta: ${response.statusCode}');
      print('💳 [PAYOUT API] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('💳 [PAYOUT API] Mercado Pago atualizado: $data');
        return data;
      } else {
        throw Exception('Erro ao atualizar Mercado Pago: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [PAYOUT API] Erro ao atualizar Mercado Pago: $e');
      throw Exception('Falha ao conectar com a API de métodos de recebimento: $e');
    }
  }
}
