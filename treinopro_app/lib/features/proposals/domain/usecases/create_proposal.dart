import '../entities/proposal.dart';
import '../repositories/proposals_repository.dart';
import '../../data/models/proposal_response_dto.dart';
import '../../data/services/popular_locations_service.dart';

/// Caso de uso para criar proposta via API
class CreateProposal {
  final ProposalsRepository repository;

  CreateProposal(this.repository);

  Future<ProposalResponseDto> call(Proposal proposal) async {
    // Validar se a proposta está completa
    if (!proposal.isFullyValid) {
      throw Exception(
        'Proposta incompleta. Verifique todos os campos obrigatórios.',
      );
    }

    // Marcar como completa e definir timestamps
    final completedProposal = proposal.copyWith(
      isCompleted: true,
      createdAt: proposal.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Criar proposta via API
    final response = await repository.createProposal(completedProposal);

    // Garantir histórico de locais mesmo após limpar o rascunho
    await PopularLocationsService.rememberFromProposalFields(
      locationId: completedProposal.locationId,
      locationName: completedProposal.locationName,
      locationAddress: completedProposal.locationAddress,
      locationLat: completedProposal.locationLat,
      locationLng: completedProposal.locationLng,
    );

    // Limpar proposta salva localmente após sucesso
    await repository.clearProposal();

    return response;
  }
}
