import '../entities/proposal.dart';
import '../repositories/proposals_repository.dart';

/// Caso de uso para salvar proposta
class SaveProposal {
  final ProposalsRepository repository;

  SaveProposal(this.repository);

  Future<void> call(Proposal proposal) async {
    // Atualizar timestamp de modificação
    final updatedProposal = proposal.copyWith(updatedAt: DateTime.now());

    await repository.saveProposal(updatedProposal);
  }
}
