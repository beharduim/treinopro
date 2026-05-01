import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/proposal.dart';
import '../../domain/entities/training_location.dart';
import '../../domain/entities/training_modality.dart';
import '../../domain/repositories/proposals_repository.dart';
import '../services/locations_service.dart';
import '../services/proposals_api_service.dart';
import '../services/popular_locations_service.dart';
import '../models/create_proposal_dto.dart';
import '../models/proposal_response_dto.dart';
import '../../../../core/services/api_service.dart';
import '../../../profile/data/services/profile_api_service.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';

/// Implementação do repositório de propostas
class ProposalsRepositoryImpl implements ProposalsRepository {
  static const String _proposalKey = 'current_proposal';

  final LocationsService _locationsService;
  final ApiService _apiService;
  final ProposalsApiService _proposalsApiService;
  final ProfileApiService _profileApiService;

  ProposalsRepositoryImpl({
    required LocationsService locationsService,
    required ApiService apiService,
    required ProposalsApiService proposalsApiService,
    required ProfileApiService profileApiService,
  }) : _locationsService = locationsService,
       _apiService = apiService,
       _proposalsApiService = proposalsApiService,
       _profileApiService = profileApiService;

  @override
  Future<void> saveProposal(Proposal proposal) async {
    final prefs = await SharedPreferences.getInstance();
    final proposalJson = _proposalToJson(proposal);
    await prefs.setString(_proposalKey, json.encode(proposalJson));
  }

  @override
  Future<Proposal?> getProposal() async {
    final prefs = await SharedPreferences.getInstance();
    final proposalString = prefs.getString(_proposalKey);

    if (proposalString == null) return null;

    try {
      final proposalJson = json.decode(proposalString) as Map<String, dynamic>;
      return _proposalFromJson(proposalJson);
    } catch (e) {
      // Se houver erro na deserialização, limpar dados corrompidos
      await clearProposal();
      return null;
    }
  }

  @override
  Future<bool> hasProposalInProgress() async {
    final proposal = await getProposal();
    return proposal != null && !proposal.isCompleted;
  }

  @override
  Future<void> clearProposal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_proposalKey);
  }

  @override
  Future<List<TrainingLocation>> searchLocations(String query) async {
    try {
      // Para queries vazias, mostrar locais populares
      if (query.isEmpty) {
        return await PopularLocationsService.getPopularLocations();
      }

      // Tentar buscar na API real primeiro
      final token = _apiService.getAccessToken();
      if (token != null) {
        return await _locationsService.searchLocations(
          query,
          token: token,
          limit: 10,
          radius: 10000, // 10km de raio
          useCurrentLocation: true, // Usar localização atual
        );
      }
    } catch (e) {
      print('🔍 DEBUG: Erro na API de locais, usando busca local: $e');
    }

    // Fallback para busca local se a API falhar
    await Future.delayed(const Duration(milliseconds: 300));

    // Buscar nos locais populares que correspondem à query
    final popularLocations =
        await PopularLocationsService.getPopularLocations();
    final lowerQuery = query.toLowerCase();

    return popularLocations
        .where(
          (location) =>
              location.name.toLowerCase().contains(lowerQuery) ||
              location.address.toLowerCase().contains(lowerQuery) ||
              (location.description?.toLowerCase().contains(lowerQuery) ??
                  false),
        )
        .toList();
  }

  @override
  Future<TrainingLocation?> getLocationById(String id) async {
    // Primeiro tentar buscar nos locais populares
    final popularLocations =
        await PopularLocationsService.getPopularLocations();
    final location = popularLocations.where((l) => l.id == id).firstOrNull;
    if (location != null) return location;

    // Fallback para busca nos locais conhecidos
    return TrainingLocationOptions.getLocationById(id);
  }

  @override
  Future<List<TrainingModality>> getModalities() async {
    // Simular delay de rede
    await Future.delayed(const Duration(milliseconds: 200));
    return TrainingModalityOptions.predefinedModalities;
  }

  @override
  Future<TrainingModality?> getModalityById(String id) async {
    return TrainingModalityOptions.getModalityById(id);
  }

  @override
  Future<List<TrainingModality>> searchModalities(String query) async {
    // Simular delay de rede
    await Future.delayed(const Duration(milliseconds: 200));
    return TrainingModalityOptions.searchModalities(query);
  }

  @override
  Future<List<String>> getAvailableTimeSlots(DateTime date) async {
    // Simular delay de rede
    await Future.delayed(const Duration(milliseconds: 400));

    // Horários base disponíveis
    final baseSlots = [
      '06:00',
      '06:30',
      '07:00',
      '07:30',
      '08:00',
      '08:30',
      '09:00',
      '09:30',
      '10:00',
      '10:30',
      '11:00',
      '11:30',
      '14:00',
      '14:30',
      '15:00',
      '15:30',
      '16:00',
      '16:30',
      '17:00',
      '17:30',
      '18:00',
      '18:30',
      '19:00',
      '19:30',
      '20:00',
      '20:30',
      '21:00',
    ];

    // Simular alguns horários ocupados baseado no dia
    final dayOfWeek = date.weekday;
    final occupiedSlots = <String>[];

    // Fins de semana têm menos horários ocupados
    if (dayOfWeek >= 6) {
      occupiedSlots.addAll(['08:00', '15:00', '19:00']);
    } else {
      // Dias úteis têm mais horários ocupados
      occupiedSlots.addAll([
        '07:00',
        '08:00',
        '12:00',
        '18:00',
        '19:00',
        '20:00',
      ]);
    }

    return baseSlots.where((slot) => !occupiedSlots.contains(slot)).toList();
  }

  @override
  Future<bool> isTimeSlotAvailable(DateTime date, String time) async {
    final availableSlots = await getAvailableTimeSlots(date);
    return availableSlots.contains(time);
  }

  @override
  Future<bool> submitProposal(Proposal proposal) async {
    // Simular envio para servidor (sem delay para melhor UX)
    // await Future.delayed(const Duration(seconds: 2)); // REMOVIDO

    // Sempre retorna sucesso (simulação de falha removida)
    return true;
  }

  @override
  Future<ProposalResponseDto> createProposal(Proposal proposal) async {
    try {
      print('🚀 REPOSITORY: Criando proposta via API');
      print('🚀 REPOSITORY: Proposal: ${proposal.toString()}');

      // ===== VALIDAR CONFLITOS DE HORÁRIO ANTES DE CRIAR =====
      if (proposal.trainingDate != null) {
        try {
          final dateString = proposal.trainingDate!.toIso8601String().split(
            'T',
          )[0];
          final conflicts = await _proposalsApiService.getTimeConflicts(
            dateString,
          );

          // Verificar se o horário selecionado está bloqueado
          if (proposal.trainingTime != null &&
              conflicts.blockedTimeSlots.contains(proposal.trainingTime)) {
            // Verificar se é conflito com proposta existente
            final existingProposal = conflicts.existingProposals.firstWhere(
              (p) => p.trainingTime == proposal.trainingTime,
              orElse: () => throw StateError('No element'),
            );

            if (existingProposal.trainingTime == proposal.trainingTime) {
              throw Exception(
                'Você já possui uma proposta agendada para este horário',
              );
            }

            // Verificar se é conflito com aula em match
            final matchedClass = conflicts.matchedClasses.firstWhere(
              (c) => c.time == proposal.trainingTime,
              orElse: () => throw StateError('No element'),
            );

            if (matchedClass.time == proposal.trainingTime) {
              throw Exception(
                'Este horário está indisponível (aula já agendada)',
              );
            }

            throw Exception('Este horário não está disponível');
          }

          print('✅ REPOSITORY: Validação de conflitos passou');
        } catch (e) {
          if (e is StateError) {
            // Não encontrou conflito específico, mas horário está bloqueado
            throw Exception('Este horário não está disponível');
          }
          print('❌ REPOSITORY: Erro na validação de conflitos: $e');
          // Se houver erro na validação, BLOQUEAR a criação
          rethrow;
        }
      }

      // Converter Proposal para CreateProposalDto
      final dto = await _createProposalDtoFromProposal(proposal);

      print('🚀 REPOSITORY: DTO criado: ${dto.toJson()}');

      // Chamar API
      final response = await _proposalsApiService.createProposal(dto);

      print('🚀 REPOSITORY: Resposta da API: ${response.toString()}');

      return response;
    } catch (e) {
      print('🚀 REPOSITORY: Erro ao criar proposta: $e');
      rethrow;
    }
  }

  /// Converter Proposal para JSON
  Map<String, dynamic> _proposalToJson(Proposal proposal) {
    return {
      'locationId': proposal.locationId,
      'locationName': proposal.locationName,
      'locationAddress': proposal.locationAddress,
      'trainingDate': proposal.trainingDate?.toIso8601String(),
      'trainingTime': proposal.trainingTime,
      'modalityId': proposal.modalityId,
      'modalityName': proposal.modalityName,
      'price': proposal.price,
      'additionalNotes': proposal.additionalNotes,
      'isCompleted': proposal.isCompleted,
      'createdAt': proposal.createdAt?.toIso8601String(),
      'updatedAt': proposal.updatedAt?.toIso8601String(),
    };
  }

  /// Converter JSON para Proposal
  Proposal _proposalFromJson(Map<String, dynamic> json) {
    return Proposal(
      locationId: json['locationId'] as String?,
      locationName: json['locationName'] as String?,
      locationAddress: json['locationAddress'] as String?,
      trainingDate: json['trainingDate'] != null
          ? DateTime.parse(json['trainingDate'] as String)
          : null,
      trainingTime: json['trainingTime'] as String?,
      modalityId: json['modalityId'] as String?,
      modalityName: json['modalityName'] as String?,
      price: json['price'] as double?,
      additionalNotes: json['additionalNotes'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Converter Proposal para CreateProposalDto
  Future<CreateProposalDto> _createProposalDtoFromProposal(
    Proposal proposal,
  ) async {
    // Mapear paymentMethodId para o tipo esperado pela API
    String paymentMethod = 'credit_card'; // default
    if (proposal.paymentMethodId != null) {
      switch (proposal.paymentMethodId) {
        case 'stripe_payment_sheet':
          paymentMethod = 'credit_card';
          break;
        case 'credit_card':
        case 'debit_card':
          paymentMethod = proposal.paymentMethodId!;
          break;
        default:
          // Se for um UUID de cartão salvo, verificar o tipo pelo selectedPaymentMethod
          if (proposal.selectedPaymentMethod != null) {
            switch (proposal.selectedPaymentMethod!.type) {
              case PaymentMethodType.creditCard:
                paymentMethod = 'credit_card';
                break;
              case PaymentMethodType.debitCard:
                paymentMethod = 'debit_card';
                break;
            }
          }
          break;
      }
    }

    // Combinar data e horário para criar uma data/hora completa
    DateTime? combinedDateTime;
    if (proposal.trainingDate != null &&
        proposal.trainingTime != null &&
        proposal.trainingTime!.isNotEmpty) {
      final timeParts = proposal.trainingTime!.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;

        // Criar DateTime em UTC para evitar problemas de fuso horário
        combinedDateTime = DateTime.utc(
          proposal.trainingDate!.year,
          proposal.trainingDate!.month,
          proposal.trainingDate!.day,
          hour,
          minute,
        );
        print(
          '🔍 [PROPOSAL] Data combinada criada: ${combinedDateTime.toIso8601String()}',
        );
        print(
          '🔍 [PROPOSAL] Data original: ${proposal.trainingDate!.toIso8601String()}',
        );
        print('🔍 [PROPOSAL] Horário: ${proposal.trainingTime}');
        print(
          '🔍 [PROPOSAL] Data local atual: ${DateTime.now().toIso8601String()}',
        );
        print(
          '🔍 [PROPOSAL] Diferença em minutos: ${combinedDateTime.difference(DateTime.now()).inMinutes}',
        );
      }
    }

    // Buscar dados do usuário logado (email e CPF)
    String? userEmail;
    String? userCpf;
    try {
      print('👤 [PROPOSAL] Buscando dados do usuário logado...');
      final userProfile = await _profileApiService.getUserProfile();
      userEmail = userProfile['email']?.toString().trim();
      userCpf = userProfile['documentNumber']?.toString().trim();

      // Limpar CPF (remover pontos, traços, espaços)
      if (userCpf != null) {
        userCpf = userCpf.replaceAll(RegExp(r'[^\d]'), '');
      }

      // Não enviar campos vazios/inválidos para evitar erro de validação no backend.
      if (userEmail == null || userEmail.isEmpty) {
        userEmail = null;
      }
      if (userCpf == null || userCpf.isEmpty || userCpf.length != 11) {
        userCpf = null;
      }

      print('👤 [PROPOSAL] Dados do usuário encontrados:');
      print('   - Email: $userEmail');
      print(
        '   - CPF: ${userCpf != null ? userCpf.replaceRange(3, 9, '***.***') : 'não informado'}',
      ); // Mascarar CPF no log
    } catch (e) {
      print('⚠️ [PROPOSAL] Erro ao buscar dados do usuário: $e');
      // Continuar sem os dados - backend pode usar fallback
    }

    return CreateProposalDto(
      locationId: null, // Não enviar locationId se não for UUID válido
      locationName: proposal.locationName ?? '',
      locationAddress: proposal.locationAddress ?? proposal.locationName ?? '',
      locationLat: proposal.locationLat, // ✅ Enviar coordenadas se disponíveis
      locationLng: proposal.locationLng, // ✅ Enviar coordenadas se disponíveis
      trainingDate:
          combinedDateTime?.toIso8601String() ??
          proposal.trainingDate!.toIso8601String(),
      trainingTime: proposal.trainingTime ?? '',
      durationMinutes: proposal.durationMinutes ?? 60,
      modalityId: null, // Não enviar modalityId se não for UUID válido
      modalityName: proposal.modalityName ?? '',
      price: proposal.price ?? 0.0,
      additionalNotes: proposal.additionalNotes,
      paymentMethod: paymentMethod,
      cardId: _resolveCardId(paymentMethod, proposal.selectedPaymentMethod?.id),
      savedCardCvv: proposal.savedCardCvv,
      cardData: null, // TODO: Implementar captura de dados de cartão novo
      installments: '1',
      saveCard: false,
      cardNickname: null,
      payerEmail: userEmail,
      payerCpf: userCpf,
    );
  }

  /// Retorna o cardId apenas quando o cartão salvo é um UUID válido.
  String? _resolveCardId(String paymentMethod, String? id) {
    if (id == null) return null;
    const uuidPattern =
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';
    return RegExp(uuidPattern).hasMatch(id) ? id : null;
  }
}
