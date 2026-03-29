import '../../data/models/class_response_dto.dart';

class ClassDisputeStatusHelper {
  static String getPersonalViewMessage(ClassResponseDto classData) {
    if (classData.status == ClassStatus.CUSTODY) {
      return 'Disputa em análise pela equipe. Aguarde a resolução.';
    }

    if (classData.status != ClassStatus.NO_SHOW_DISPUTE) {
      return 'Disputa finalizada. Verifique o histórico para mais detalhes.';
    }

    if (classData.noShowReportedBy == 'student') {
      return classData.personalDefenseSubmittedAt != null
          ? 'Você já enviou sua defesa. Aguardando resolução da disputa.'
          : 'O aluno reportou sua ausência. Envie sua defesa antes do prazo.';
    } else {
      return classData.studentDefenseSubmittedAt != null
          ? 'O aluno já enviou a defesa. Aguardando resolução da disputa.'
          : 'Aula em disputa - aguardando defesa do aluno';
    }
  }

  /// Retorna mensagem adaptada para a visão do ALUNO
  static String getStudentViewMessage(ClassResponseDto classData) {
    if (classData.status == ClassStatus.CUSTODY) {
      return 'Disputa em análise pela equipe. Aguarde a resolução.';
    }

    if (classData.status != ClassStatus.NO_SHOW_DISPUTE) {
      return 'Disputa finalizada. Verifique o histórico para mais detalhes.';
    }

    if (classData.noShowReportedBy == 'personal') {
      return classData.studentDefenseSubmittedAt != null
          ? 'Você já enviou sua defesa. Aguardando resolução da disputa.'
          : 'O personal reportou sua ausência. Envie sua defesa antes do prazo.';
    } else {
      return classData.personalDefenseSubmittedAt != null
          ? 'O personal já enviou a defesa. Aguardando resolução da disputa.'
          : 'Aula em disputa. Aguardando defesa do personal.';
    }
  }
}
