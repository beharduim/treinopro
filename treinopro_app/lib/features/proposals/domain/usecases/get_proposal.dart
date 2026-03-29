import '../entities/proposal.dart';
import '../repositories/proposals_repository.dart';

/// Caso de uso para recuperar proposta
class GetProposal {
  final ProposalsRepository repository;

  GetProposal(this.repository);

  Future<Proposal?> call() async {
    return await repository.getProposal();
  }
}
