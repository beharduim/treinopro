import '../entities/proposal.dart';
import '../repositories/proposals_repository.dart';
import '../../data/services/popular_locations_service.dart';

/// Caso de uso para submeter proposta finalizada
class SubmitProposal {
  final ProposalsRepository repository;

  SubmitProposal(this.repository);

  Future<bool> call(Proposal proposal) async {
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

    // Submeter a proposta
    final success = await repository.submitProposal(completedProposal);

    if (success) {
      await PopularLocationsService.rememberFromProposalFields(
        locationId: completedProposal.locationId,
        locationName: completedProposal.locationName,
        locationAddress: completedProposal.locationAddress,
        locationLat: completedProposal.locationLat,
        locationLng: completedProposal.locationLng,
      );
      // Limpar proposta salva localmente após sucesso
      await repository.clearProposal();
    }

    return success;
  }
}
