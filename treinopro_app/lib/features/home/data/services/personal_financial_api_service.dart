import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_service.dart';

class PersonalFinancialApiService {
  final http.Client _client;
  final ApiService _apiService;
  final String _baseUrl;

  PersonalFinancialApiService({
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

  /// Busca estatísticas financeiras do personal trainer
  Future<Map<String, dynamic>> getPersonalFinancialStats() async {
    try {
      print('🔍 [FINANCIAL API] Buscando estatísticas financeiras do personal...');
      
      final response = await _client.get(
        Uri.parse('$_baseUrl/payments/personal/financial/stats'),
        headers: _headers,
      );

      print('🔍 [FINANCIAL API] Status da resposta: ${response.statusCode}');
      print('🔍 [FINANCIAL API] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 [FINANCIAL API] Dados decodificados: $data');
        return data['data']; // Extrair dados do wrapper de resposta
      } else {
        throw Exception('Erro ao buscar estatísticas financeiras: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [FINANCIAL API] Erro ao buscar estatísticas financeiras: $e');
      throw Exception('Falha ao conectar com a API financeira: $e');
    }
  }

  /// Busca saldo da carteira do personal trainer
  Future<Map<String, dynamic>> getWalletBalance() async {
    try {
      print('💰 [FINANCIAL API] Buscando saldo da carteira...');
      
      final response = await _client.get(
        Uri.parse('$_baseUrl/payments/personal/wallet/balance'),
        headers: _headers,
      );

      print('💰 [FINANCIAL API] Status da resposta: ${response.statusCode}');
      print('💰 [FINANCIAL API] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('💰 [FINANCIAL API] Dados da carteira: $data');
        return data['data']; // Extrair dados do wrapper de resposta
      } else {
        throw Exception('Erro ao buscar saldo da carteira: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [FINANCIAL API] Erro ao buscar saldo da carteira: $e');
      throw Exception('Falha ao conectar com a API da carteira: $e');
    }
  }

  /// Busca histórico de transações da carteira
  Future<List<Map<String, dynamic>>> getWalletTransactions({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      print('📜 [FINANCIAL API] Buscando histórico de transações...');
      
      final uri = Uri.parse('$_baseUrl/payments/personal/wallet/transactions').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );
      
      final response = await _client.get(uri, headers: _headers);

      print('📜 [FINANCIAL API] Status da resposta: ${response.statusCode}');
      print('📜 [FINANCIAL API] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final transactions = List<Map<String, dynamic>>.from(data['data']);
        print('📜 [FINANCIAL API] ${transactions.length} transações encontradas');
        return transactions;
      } else {
        throw Exception('Erro ao buscar transações: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [FINANCIAL API] Erro ao buscar transações: $e');
      throw Exception('Falha ao conectar com a API de transações: $e');
    }
  }

  /// Busca estatísticas de pagamentos do personal trainer
  Future<Map<String, dynamic>> getPaymentStats() async {
    try {
      print('📊 [FINANCIAL API] Buscando estatísticas de pagamentos...');
      
      final response = await _client.get(
        Uri.parse('$_baseUrl/payments/stats/my'),
        headers: _headers,
      );

      print('📊 [FINANCIAL API] Status da resposta: ${response.statusCode}');
      print('📊 [FINANCIAL API] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 [FINANCIAL API] Estatísticas: $data');
        return data;
      } else {
        throw Exception('Erro ao buscar estatísticas: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [FINANCIAL API] Erro ao buscar estatísticas: $e');
      throw Exception('Falha ao conectar com a API de estatísticas: $e');
    }
  }

  /// Busca pagamentos capturados (aulas concluídas)
  Future<List<Map<String, dynamic>>> getCapturedPayments({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      print('✅ [FINANCIAL API] Buscando pagamentos capturados...');
      
      final uri = Uri.parse('$_baseUrl/payments/personal/payments').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
          'status': 'captured',
        },
      );
      
      final response = await _client.get(uri, headers: _headers);

      print('✅ [FINANCIAL API] Status da resposta: ${response.statusCode}');
      print('✅ [FINANCIAL API] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final payments = List<Map<String, dynamic>>.from(data['data']);
        print('✅ [FINANCIAL API] ${payments.length} pagamentos capturados encontrados');
        return payments;
      } else {
        throw Exception('Erro ao buscar pagamentos capturados: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [FINANCIAL API] Erro ao buscar pagamentos capturados: $e');
      throw Exception('Falha ao conectar com a API de pagamentos: $e');
    }
  }
}
