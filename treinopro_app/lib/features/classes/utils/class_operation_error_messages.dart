/// Traduz erros técnicos de operações de aula para mensagens amigáveis na UI.
class ClassOperationErrorMessages {
  static String friendlyMessage(
    Object error, {
    String? action,
  }) {
    final raw = error.toString();
    final msg = raw
        .replaceFirst('Exception: ', '')
        .replaceFirst('Erro: ', '')
        .replaceFirst('Erro na requisição: Exception: ', '')
        .trim();

    if (_isMinDurationError(msg)) {
      final match = RegExp(r'Faltam (\d+) minuto').firstMatch(msg);
      if (match != null) {
        return 'Aguarde mais ${match.group(1)} minuto(s) para finalizar a aula.';
      }
      return 'Aguarde mais alguns instantes para finalizar a aula.';
    }

    if (msg.contains('só pode ser iniciada entre') ||
        msg.contains('iniciada entre') ||
        msg.contains('START_WINDOW')) {
      return 'Ainda não é o horário de iniciar a aula. Aguarde a janela permitida.';
    }

    if (msg.contains('Aula não pode ser iniciada neste momento')) {
      return 'Ainda não é possível iniciar a aula. Aguarde alguns instantes.';
    }

    if (msg.contains('Aula não pode ser finalizada no estado atual') ||
        msg.contains('Aula não pode ser finalizada')) {
      return 'Aguarde mais alguns instantes para finalizar a aula.';
    }

    if (msg.contains('já foi finalizada anteriormente') ||
        msg.contains('Esta aula já foi finalizada')) {
      return 'Esta aula já foi finalizada anteriormente.';
    }

    if (msg.contains('Apenas aulas agendadas podem ser iniciadas')) {
      return 'Esta aula não está mais disponível para início.';
    }

    if (msg.contains('Apenas aulas ativas podem ser finalizadas')) {
      return 'A aula precisa estar em andamento para ser finalizada.';
    }

    if (msg.contains('timeline indisponível')) {
      return 'Não foi possível validar o estado da aula. Tente novamente.';
    }

    if (action == 'start_class') {
      return 'Não foi possível iniciar a aula agora. Tente novamente em instantes.';
    }

    if (action == 'complete_class') {
      return 'Não foi possível finalizar a aula agora. Aguarde mais alguns instantes.';
    }

    if (msg.isNotEmpty && !msg.startsWith('Erro na requisição')) {
      return msg;
    }

    return 'Ocorreu um erro. Tente novamente.';
  }

  static bool _isMinDurationError(String msg) {
    return msg.contains('MIN_50_RULE') ||
        msg.contains('MIN_45_RULE') ||
        (msg.contains('pelo menos') && msg.contains('minuto'));
  }
}
