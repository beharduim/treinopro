enum AccountAccessDeniedReason {
  rejected,
  suspended,
  inactive,
}

class AccountAccessDeniedException implements Exception {
  final String message;
  final AccountAccessDeniedReason reason;

  const AccountAccessDeniedException({
    required this.message,
    required this.reason,
  });

  @override
  String toString() => message;
}
