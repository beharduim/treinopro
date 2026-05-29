/// Prazo administrativo para uso do app enquanto cadastro está em análise.
const approvalGracePeriodDays = 3;

bool isWithinApprovalGracePeriod(DateTime? createdAt, [DateTime? now]) {
  if (createdAt == null) return false;
  final reference = now ?? DateTime.now();
  return reference.isBefore(
    createdAt.add(const Duration(days: approvalGracePeriodDays)),
  );
}

/// Personal bloqueado na tela de análise (fora do prazo ou recusado).
bool shouldBlockPersonalForApproval({
  required String? approvalStatus,
  required DateTime? createdAt,
}) {
  if (approvalStatus == 'rejected') return true;
  if (approvalStatus == 'approved') return false;
  if (approvalStatus == 'pending_review') {
    if (createdAt == null) return false;
    return !isWithinApprovalGracePeriod(createdAt);
  }
  // Status desconhecido — bloqueia por segurança
  return true;
}
