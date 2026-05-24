import '../../data/models/class_dispute_dto.dart';

/// Rótulos claros de status para o hub "Minhas Disputas".
class DisputeHubLabels {
  static String statusTitle(ClassDisputeDto dispute) {
    if (dispute.isResolvedForStudent) {
      return 'Decisão favorável ao aluno';
    }
    if (dispute.isResolvedForPersonal) {
      return 'Decisão favorável ao personal';
    }
    if (dispute.isDefenseSubmitted || dispute.isPending) {
      return 'Em análise';
    }
    if (dispute.isStudentConfirmedAbsence) {
      return 'Ausência confirmada';
    }
    if (dispute.isStudentDeniedAbsence) {
      return 'Ausência contestada';
    }
    return 'Em andamento';
  }

  static String statusSubtitle(ClassDisputeDto dispute) {
    if (dispute.isResolved) {
      return dispute.resolution != null && dispute.resolution!.isNotEmpty
          ? dispute.resolution!
          : 'A equipe TreinoPro finalizou a análise desta disputa.';
    }
    if (dispute.isWithinDeadline) {
      return 'Prazo para defesa: ${dispute.formattedTimeUntilDeadline}';
    }
    return 'Aguardando análise da equipe TreinoPro.';
  }

  static bool canUserSubmitDefense({
    required ClassDisputeDto dispute,
    required String currentUserId,
  }) {
    if (dispute.isResolved || !dispute.isWithinDeadline) return false;
    if (currentUserId != dispute.reportedUserId) return false;

    if (dispute.reportedBy == 'personal') {
      return dispute.studentDefenseText == null;
    }
    if (dispute.reportedBy == 'student') {
      return dispute.personalDefenseText == null;
    }
    return false;
  }
}
