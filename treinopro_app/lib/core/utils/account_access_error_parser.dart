import 'dart:convert';

import 'package:dio/dio.dart';

import '../errors/account_access_denied_exception.dart';

AccountAccessDeniedException? parseAccountAccessError(dynamic error) {
  if (error is AccountAccessDeniedException) return error;

  if (error is DioException) {
    return parseAccountAccessFromResponse(error.response?.data);
  }

  return parseAccountAccessFromText(error?.toString() ?? '');
}

AccountAccessDeniedException? parseAccountAccessFromResponse(dynamic data) {
  if (data == null) return null;

  if (data is Map) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return _fromMessage(message.trim());
    }
  }

  if (data is String) {
    return parseAccountAccessFromText(data);
  }

  return null;
}

AccountAccessDeniedException? parseAccountAccessFromText(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  String? message = _extractJsonMessage(trimmed) ?? trimmed;
  message = message.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();

  final nested = _extractJsonMessage(message);
  if (nested != null) {
    message = nested;
  }

  return _fromMessage(message);
}

AccountAccessDeniedException? _fromMessage(String message) {
  final lower = message.toLowerCase();

  if (lower.contains('recusado') || lower.contains('documentação')) {
    return AccountAccessDeniedException(
      message: message,
      reason: AccountAccessDeniedReason.rejected,
    );
  }

  if (lower.contains('bloqueada') || lower.contains('bloqueado')) {
    return AccountAccessDeniedException(
      message: message,
      reason: AccountAccessDeniedReason.suspended,
    );
  }

  if (lower.contains('inativa')) {
    return AccountAccessDeniedException(
      message: message,
      reason: AccountAccessDeniedReason.inactive,
    );
  }

  return null;
}

String? _extractJsonMessage(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start == -1 || end <= start) return null;

  try {
    final decoded = json.decode(raw.substring(start, end + 1));
    if (decoded is Map && decoded['message'] is String) {
      return (decoded['message'] as String).trim();
    }
  } catch (_) {}

  return null;
}
