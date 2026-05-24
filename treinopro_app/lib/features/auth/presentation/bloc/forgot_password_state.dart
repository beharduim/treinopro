/// Estados para o fluxo de recuperação de senha
abstract class ForgotPasswordState {}

/// Estado inicial
class ForgotPasswordInitial extends ForgotPasswordState {}

/// Step 1: Inserir email
class ForgotPasswordEmailStep extends ForgotPasswordState {
  final String? email;
  final bool isCodeSent;
  final String? error;

  ForgotPasswordEmailStep({
    this.email,
    this.isCodeSent = false,
    this.error,
  });

  ForgotPasswordEmailStep copyWith({
    String? email,
    bool? isCodeSent,
    String? error,
  }) {
    return ForgotPasswordEmailStep(
      email: email ?? this.email,
      isCodeSent: isCodeSent ?? this.isCodeSent,
      error: error ?? this.error,
    );
  }
}

/// Step 2: Verificar código OTP
class ForgotPasswordOtpStep extends ForgotPasswordState {
  final String email;
  final bool isVerifying;
  final bool isCodeVerified;
  final String? verifiedCode;
  final String? error;
  final int remainingTime;

  ForgotPasswordOtpStep({
    required this.email,
    this.isVerifying = false,
    this.isCodeVerified = false,
    this.verifiedCode,
    this.error,
    this.remainingTime = 600,
  });

  ForgotPasswordOtpStep copyWith({
    String? email,
    bool? isVerifying,
    bool? isCodeVerified,
    String? verifiedCode,
    String? error,
    int? remainingTime,
  }) {
    return ForgotPasswordOtpStep(
      email: email ?? this.email,
      isVerifying: isVerifying ?? this.isVerifying,
      isCodeVerified: isCodeVerified ?? this.isCodeVerified,
      verifiedCode: verifiedCode ?? this.verifiedCode,
      error: error,
      remainingTime: remainingTime ?? this.remainingTime,
    );
  }
}

/// Step 3: Criar nova senha
class ForgotPasswordNewPasswordStep extends ForgotPasswordState {
  final String email;
  final String code;
  final String? password;
  final String? confirmPassword;
  final bool isResetting;
  final String? error;

  ForgotPasswordNewPasswordStep({
    required this.email,
    required this.code,
    this.password,
    this.confirmPassword,
    this.isResetting = false,
    this.error,
  });

  ForgotPasswordNewPasswordStep copyWith({
    String? email,
    String? code,
    String? password,
    String? confirmPassword,
    bool? isResetting,
    String? error,
  }) {
    return ForgotPasswordNewPasswordStep(
      email: email ?? this.email,
      code: code ?? this.code,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isResetting: isResetting ?? this.isResetting,
      error: error ?? this.error,
    );
  }
}

/// Sucesso - senha alterada
class ForgotPasswordSuccess extends ForgotPasswordState {
  final String message;

  ForgotPasswordSuccess(this.message);
}

/// Erro geral
class ForgotPasswordError extends ForgotPasswordState {
  final String message;

  ForgotPasswordError(this.message);
}

/// Loading
class ForgotPasswordLoading extends ForgotPasswordState {}
