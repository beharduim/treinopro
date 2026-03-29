import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../models/proposal_response_dto.dart';
import 'auth_service.dart';

/// Serviço para consumir APIs de propostas
class ProposalsService {
  final http.Client _client;
  final String _baseUrl;
  final NetworkInfo _networkInfo;
  final AuthService _authService;

  ProposalsService({
    required http.Client client,
    required NetworkInfo networkInfo,
    required AuthService authService,
    String? baseUrl,
  }) : _client = client,
       _networkInfo = networkInfo,
       _authService = authService,
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  /// Obtém as propostas pendentes do usuário
  Future<List<ProposalResponseDto>> getPendingProposals(String userId) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    final token = await _authService.getValidToken();
    if (token == null) {
      throw UnauthorizedException('Usuário não autenticado');
    }

    try {
      // 🔍 DEBUG: Primeiro testar todas as propostas do usuário
      print('🔍 DEBUG: Testando TODAS as propostas do usuário: $userId');
      
      final allProposalsUri = Uri.parse('$_baseUrl/proposals').replace(queryParameters: {
        'limit': '50',
      });
      
      print('🔍 DEBUG: Buscando TODAS as propostas em: $allProposalsUri');
      
      final allResponse = await _client.get(
        allProposalsUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (allResponse.statusCode == 200) {
        final allData = json.decode(allResponse.body);
        print('📊 DEBUG: TODAS as propostas: ${allResponse.body}');
        
        if (allData.containsKey('proposals')) {
          final allProposals = allData['proposals'] as List;
          print('📊 DEBUG: Total de propostas encontradas: ${allProposals.length}');
          
          for (var prop in allProposals) {
            print('  - ID: ${prop['id']}, StudentId: ${prop['studentId']}, Status: ${prop['status']}');
          }
        }
      }
      
      // Agora buscar apenas as pendentes
      final uri = Uri.parse('$_baseUrl/proposals').replace(queryParameters: {
        'status': 'pending',
        'limit': '50',
      });

      print('🔍 DEBUG: Buscando propostas pendentes em: $uri');

      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📝 DEBUG: Resposta propostas - Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('📊 DEBUG: Estrutura da resposta: ${data.keys.toList()}');
        
        // Verificar se existe 'proposals' na resposta
        List<dynamic> proposalsList;
        if (data.containsKey('proposals')) {
          proposalsList = data['proposals'] as List;
          print('📊 DEBUG: Encontrado campo "proposals" com ${proposalsList.length} itens');
        } else if (data is List) {
          proposalsList = data;
          print('📊 DEBUG: Resposta é uma lista direta com ${proposalsList.length} itens');
        } else {
          print('❌ DEBUG: Estrutura de resposta inesperada: $data');
          return [];
        }
        
        final proposals = proposalsList
            .map((json) => ProposalResponseDto.fromJson(json))
            .toList();
        
        print('📊 DEBUG: ${proposals.length} propostas mapeadas com sucesso');
        
        // 🔍 DEBUG: Se não encontrou propostas "pending", verificar se há com outros status válidos
        if (proposals.isEmpty) {
          print('🔍 DEBUG: Nenhuma proposta "pending" encontrada, verificando outros status válidos...');
          
          // Status válidos da API: pending, matched, completed, cancelled
          final statusesToTest = ['matched', 'completed', 'cancelled'];
          
          for (String status in statusesToTest) {
            try {
              final testUri = Uri.parse('$_baseUrl/proposals').replace(queryParameters: {
                'status': status,
                'limit': '10',
              });
              
              print('🔍 DEBUG: Testando status "$status" em: $testUri');
              
              final testResponse = await _client.get(
                testUri,
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              );
              
              if (testResponse.statusCode == 200) {
                final testData = json.decode(testResponse.body);
                if (testData.containsKey('proposals')) {
                  final testProposals = testData['proposals'] as List;
                  print('📊 DEBUG: Status "$status": ${testProposals.length} propostas encontradas');
                  
                  if (testProposals.isNotEmpty) {
                    print('📊 DEBUG: Primeira proposta com status "$status": ${testProposals.first}');
                  }
                }
              }
            } catch (e) {
              print('❌ DEBUG: Erro ao testar status "$status": $e');
            }
          }
        }
        
        return proposals;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token de autenticação inválido');
      } else if (response.statusCode == 403) {
        throw UnauthorizedException('Sem permissão para acessar propostas');
      } else {
        throw ServerException('Erro ao buscar propostas pendentes: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao buscar propostas: $e');
    }
  }


  /// Obtém uma proposta específica por ID
  Future<ProposalResponseDto> getProposalById(String proposalId) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    final token = await _authService.getValidToken();
    if (token == null) {
      throw UnauthorizedException('Usuário não autenticado');
    }

    try {
      final uri = Uri.parse('$_baseUrl/proposals/$proposalId');

      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProposalResponseDto.fromJson(data);
      } else if (response.statusCode == 404) {
        throw ServerException('Proposta não encontrada');
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token de autenticação inválido');
      } else if (response.statusCode == 403) {
        throw UnauthorizedException('Sem permissão para acessar esta proposta');
      } else {
        throw ServerException('Erro ao buscar proposta: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao buscar proposta: $e');
    }
  }

  /// Cancela uma proposta
  Future<ProposalResponseDto> cancelProposal(String proposalId) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    final token = await _authService.getValidToken();
    if (token == null) {
      throw UnauthorizedException('Usuário não autenticado');
    }

    try {
      final uri = Uri.parse('$_baseUrl/proposals/$proposalId');

      final response = await _client.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProposalResponseDto.fromJson(data);
      } else if (response.statusCode == 404) {
        throw ServerException('Proposta não encontrada');
      } else if (response.statusCode == 400) {
        throw ServerException('Proposta não pode ser cancelada');
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token de autenticação inválido');
      } else if (response.statusCode == 403) {
        throw UnauthorizedException('Sem permissão para cancelar esta proposta');
      } else {
        throw ServerException('Erro ao cancelar proposta: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao cancelar proposta: $e');
    }
  }

  /// Obtém todas as propostas do usuário (compatibilidade)
  Future<Map<String, dynamic>> getMyProposals(String token, {int page = 1, int limit = 1}) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    try {
      final uri = Uri.parse('$_baseUrl/proposals/my').replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });
    
    final response = await _client.get(
        uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token de autenticação inválido');
      } else if (response.statusCode == 403) {
        throw UnauthorizedException('Sem permissão para acessar propostas');
    } else {
        throw ServerException('Erro ao buscar propostas: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao buscar propostas: $e');
    }
  }

  /// Obtém estatísticas das propostas
  Future<Map<String, dynamic>> getStats(String token) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('Sem conexão com a internet');
    }

    try {
      final uri = Uri.parse('$_baseUrl/proposals/stats');

    final response = await _client.get(
        uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token de autenticação inválido');
    } else {
        throw ServerException('Erro ao buscar estatísticas: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException('Erro inesperado ao buscar estatísticas: $e');
    }
  }
}
