import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/support_contact.dart';
import '../di/dependency_injection.dart';
import '../errors/account_access_denied_exception.dart';
import '../navigation/app_navigator.dart';
import '../utils/account_access_error_parser.dart';
import '../../features/auth/presentation/bloc/login_initial_bloc.dart';
import '../../features/auth/presentation/pages/login_initial_page.dart';
import '../../features/home/data/services/auth_service.dart';
import 'api_service.dart';

class AccountAccessHandler {
  static bool _isPresenting = false;

  /// Retorna true se o erro foi de conta bloqueada/recusada e foi tratado.
  static Future<bool> handle(dynamic error) async {
    final parsed = parseAccountAccessError(error);
    if (parsed == null) return false;

    await present(parsed);
    return true;
  }

  static Future<void> present(AccountAccessDeniedException info) async {
    if (_isPresenting) return;
    _isPresenting = true;

    try {
      await _clearLocalSession();

      final context = await _waitForNavigatorContext();
      if (context == null || !context.mounted) return;

      final title = _titleFor(info.reason);
      final body = _bodyFor(info);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(body, style: const TextStyle(height: 1.45)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<LoginInitialBloc>(),
            child: const LoginInitialPage(),
          ),
        ),
        (_) => false,
      );
    } finally {
      _isPresenting = false;
    }
  }

  static Future<BuildContext?> _waitForNavigatorContext() async {
    for (var attempt = 0; attempt < 30; attempt++) {
      final context = AppNavigator.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        return context;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return AppNavigator.navigatorKey.currentContext;
  }

  static Future<void> _clearLocalSession() async {
    try {
      await sl<ApiService>().clearTokens();
    } catch (_) {}

    try {
      if (sl.isRegistered<AuthService>()) {
        await sl<AuthService>().clearTokens();
      }
    } catch (_) {}
  }

  static String _titleFor(AccountAccessDeniedReason reason) {
    switch (reason) {
      case AccountAccessDeniedReason.rejected:
        return 'Cadastro não aprovado';
      case AccountAccessDeniedReason.suspended:
        return 'Conta bloqueada';
      case AccountAccessDeniedReason.inactive:
        return 'Conta inativa';
    }
  }

  static String _bodyFor(AccountAccessDeniedException info) {
    switch (info.reason) {
      case AccountAccessDeniedReason.rejected:
        return SupportContact.resubmitDocumentsBody;
      case AccountAccessDeniedReason.suspended:
        return SupportContact.blockedAccountBody;
      case AccountAccessDeniedReason.inactive:
        return SupportContact.inactiveAccountBody;
    }
  }
}
