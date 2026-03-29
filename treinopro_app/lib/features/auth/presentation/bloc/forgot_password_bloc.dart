import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../auth/data/services/auth_service.dart';
import 'forgot_password_event.dart';
import 'forgot_password_state.dart';

/// BLoC para gerenciar o fluxo de recuperação de senha
class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final ForgotPasswordAuthService _authService = sl<ForgotPasswordAuthService>();
  Timer? _timer;

  ForgotPasswordBloc() : super(ForgotPasswordInitial()) {
    on<StartForgotPassword>(_onStartForgotPassword);
    on<SendResetCode>(_onSendResetCode);
    on<VerifyResetCode>(_onVerifyResetCode);
    on<UpdateNewPassword>(_onUpdateNewPassword);
    on<ResetPassword>(_onResetPassword);
    on<PreviousStep>(_onPreviousStep);
    on<NextStep>(_onNextStep);
    on<ResendCode>(_onResendCode);
    on<UpdateTimer>(_onUpdateTimer);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  void _onStartForgotPassword(
    StartForgotPassword event,
    Emitter<ForgotPasswordState> emit,
  ) {
    emit(ForgotPasswordEmailStep());
  }

  Future<void> _onSendResetCode(
    SendResetCode event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    try {
      emit(ForgotPasswordLoading());
      
      // Chamar API para enviar código de reset
      await _authService.sendPasswordResetCode(event.email);
      
      emit(ForgotPasswordEmailStep(
        email: event.email,
        isCodeSent: true,
      ));
      
      // Avançar automaticamente para o step de OTP
      add(NextStep());
      
    } catch (e) {
      emit(ForgotPasswordEmailStep(
        email: event.email,
        error: 'Erro ao enviar código: ${e.toString()}',
      ));
    }
  }

  void _onNextStep(
    NextStep event,
    Emitter<ForgotPasswordState> emit,
  ) {
    if (state is ForgotPasswordEmailStep) {
      final currentState = state as ForgotPasswordEmailStep;
      if (currentState.isCodeSent && currentState.email != null) {
        emit(ForgotPasswordOtpStep(
          email: currentState.email!,
          remainingTime: 300,
        ));
        _startTimer();
      }
    } else if (state is ForgotPasswordOtpStep) {
      final currentState = state as ForgotPasswordOtpStep;
      if (currentState.isCodeVerified) {
        emit(ForgotPasswordNewPasswordStep(
          email: currentState.email,
          code: '', // Será preenchido quando o código for verificado
        ));
      }
    }
  }

  Future<void> _onVerifyResetCode(
    VerifyResetCode event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    if (state is ForgotPasswordOtpStep) {
      try {
        // Limpar erro anterior e iniciar verificação
        emit((state as ForgotPasswordOtpStep).copyWith(
          isVerifying: true,
          error: null,
        ));

        // Chamar API para verificar código
        await _authService.verifyPasswordResetCode(event.email, event.code);

        emit((state as ForgotPasswordOtpStep).copyWith(
          isVerifying: false,
          isCodeVerified: true,
        ));

        // Avançar para o próximo step
        add(NextStep());

      } catch (e) {
        emit((state as ForgotPasswordOtpStep).copyWith(
          isVerifying: false,
          error: 'Código inválido: ${e.toString()}',
        ));
      }
    }
  }

  void _onUpdateNewPassword(
    UpdateNewPassword event,
    Emitter<ForgotPasswordState> emit,
  ) {
    if (state is ForgotPasswordNewPasswordStep) {
      emit((state as ForgotPasswordNewPasswordStep).copyWith(
        password: event.password,
        confirmPassword: event.confirmPassword,
      ));
    }
  }

  Future<void> _onResetPassword(
    ResetPassword event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    if (state is ForgotPasswordNewPasswordStep) {
      try {
        emit((state as ForgotPasswordNewPasswordStep).copyWith(
          isResetting: true,
          error: null,
        ));

        // Chamar API para resetar senha
        await _authService.resetPassword(
          event.email,
          event.code,
          event.newPassword,
        );

        emit(ForgotPasswordSuccess('Senha alterada com sucesso!'));

      } catch (e) {
        emit((state as ForgotPasswordNewPasswordStep).copyWith(
          isResetting: false,
          error: 'Erro ao alterar senha: ${e.toString()}',
        ));
      }
    }
  }

  void _onPreviousStep(
    PreviousStep event,
    Emitter<ForgotPasswordState> emit,
  ) {
    if (state is ForgotPasswordOtpStep) {
      final currentState = state as ForgotPasswordOtpStep;
      emit(ForgotPasswordEmailStep(
        email: currentState.email,
        isCodeSent: false,
      ));
    } else if (state is ForgotPasswordNewPasswordStep) {
      final currentState = state as ForgotPasswordNewPasswordStep;
      emit(ForgotPasswordOtpStep(
        email: currentState.email,
        remainingTime: 300,
      ));
      _startTimer();
    }
  }

  Future<void> _onResendCode(
    ResendCode event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    try {
      emit(ForgotPasswordLoading());
      
      // Chamar API para reenviar código
      await _authService.sendPasswordResetCode(event.email);
      
      emit(ForgotPasswordOtpStep(
        email: event.email,
        remainingTime: 300,
      ));
      
      _startTimer();
      
    } catch (e) {
      emit(ForgotPasswordError('Erro ao reenviar código: ${e.toString()}'));
    }
  }

  void _onUpdateTimer(
    UpdateTimer event,
    Emitter<ForgotPasswordState> emit,
  ) {
    if (state is ForgotPasswordOtpStep) {
      emit((state as ForgotPasswordOtpStep).copyWith(
        remainingTime: event.remainingTime,
      ));
    }
  }

  void _startTimer() {
    _timer?.cancel();
    int remainingTime = 300;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingTime--;
      
      if (state is ForgotPasswordOtpStep) {
        add(UpdateTimer(remainingTime));
      }
      
      if (remainingTime <= 0) {
        timer.cancel();
      }
    });
  }
}
