/// Eventos para o fluxo de recuperação de senha
abstract class ForgotPasswordEvent {}

/// Inicia o fluxo de recuperação de senha
class StartForgotPassword extends ForgotPasswordEvent {}

/// Envia código de verificação para o email
class SendResetCode extends ForgotPasswordEvent {
  final String email;

  SendResetCode(this.email);
}

/// Verifica o código OTP
class VerifyResetCode extends ForgotPasswordEvent {
  final String email;
  final String code;

  VerifyResetCode(this.email, this.code);
}

/// Atualiza a nova senha
class UpdateNewPassword extends ForgotPasswordEvent {
  final String password;
  final String confirmPassword;

  UpdateNewPassword(this.password, this.confirmPassword);
}

/// Reseta a senha
class ResetPassword extends ForgotPasswordEvent {
  final String email;
  final String code;
  final String newPassword;

  ResetPassword(this.email, this.code, this.newPassword);
}

/// Volta para o step anterior
class PreviousStep extends ForgotPasswordEvent {}

/// Avança para o próximo step
class NextStep extends ForgotPasswordEvent {}

/// Reenvia código de verificação
class ResendCode extends ForgotPasswordEvent {
  final String email;

  ResendCode(this.email);
}

/// Atualiza o timer
class UpdateTimer extends ForgotPasswordEvent {
  final int remainingTime;

  UpdateTimer(this.remainingTime);
}
