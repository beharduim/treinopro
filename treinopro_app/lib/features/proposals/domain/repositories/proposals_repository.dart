import '../entities/proposal.dart';
import '../entities/training_location.dart';
import '../entities/training_modality.dart';
import '../../data/models/proposal_response_dto.dart';

/// Interface do repositório de propostas
abstract class ProposalsRepository {
  /// Salvar proposta em progresso
  Future<void> saveProposal(Proposal proposal);

  /// Recuperar proposta salva
  Future<Proposal?> getProposal();

  /// Verificar se existe proposta em progresso
  Future<bool> hasProposalInProgress();

  /// Limpar proposta salva
  Future<void> clearProposal();

  /// Buscar locais de treino
  Future<List<TrainingLocation>> searchLocations(String query);

  /// Obter local por ID
  Future<TrainingLocation?> getLocationById(String id);

  /// Obter todas as modalidades
  Future<List<TrainingModality>> getModalities();

  /// Obter modalidade por ID
  Future<TrainingModality?> getModalityById(String id);

  /// Buscar modalidades por nome
  Future<List<TrainingModality>> searchModalities(String query);

  /// Obter horários disponíveis para uma data
  Future<List<String>> getAvailableTimeSlots(DateTime date);

  /// Validar se horário está disponível
  Future<bool> isTimeSlotAvailable(DateTime date, String time);

  /// Submeter proposta finalizada
  Future<bool> submitProposal(Proposal proposal);

  /// Criar proposta via API
  Future<ProposalResponseDto> createProposal(Proposal proposal);
}
