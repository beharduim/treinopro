import 'package:flutter/material.dart';
import '../../../../core/services/deep_link_service.dart';
import '../widgets/gamification_dev_notice_modal.dart';

/// Coordenador de exibição do aviso "Gamificação em Desenvolvimento".
///
/// Controla a política de exibição: 1x por sessão do app.
/// O estado é mantido em memória — não persiste entre sessões, garantindo que o
/// aviso reaparece a cada abertura do app.
///
/// Registrado como singleton no DI para que o estado seja compartilhado entre
/// [StudentHomePage] e [PersonalHomePage].
class GamificationDevNoticeCoordinator {
  bool _shownThisSession = false;

  /// Exibe o modal se ainda não foi exibido nesta sessão.
  ///
  /// Deve ser chamado dentro de um `addPostFrameCallback` para garantir que o
  /// contexto está montado e o frame já foi renderizado.
  void maybeShow(BuildContext context) {
    if (_shownThisSession) return;
    if (!context.mounted) return;

    // Não bloquear a tela se há deep link pendente (proposta/recontratação)
    // O modal de gamificação é barrierDismissible:false e impediria a navegação
    if (DeepLinkService.hasPendingDeepLink) {
      print('ℹ️ [GAMIFICATION] Deep link pendente — adiando modal de gamificação');
      return;
    }

    _shownThisSession = true;

    showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Aviso de gamificação',
      barrierColor: Colors.black.withOpacity(0.45),
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 520),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (context, _, __) => const GamificationDevNoticeModal(),
    );
  }

  /// Reseta o estado de sessão (útil apenas em testes).
  @visibleForTesting
  void resetForTesting() {
    _shownThisSession = false;
  }

  /// Retorna se o modal já foi exibido nesta sessão (útil em testes).
  @visibleForTesting
  bool get hasShownThisSession => _shownThisSession;
}
