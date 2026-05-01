import 'package:equatable/equatable.dart';
import '../../domain/entities/payment_method.dart';

/// Estados para o BLoC de métodos de pagamento
abstract class PaymentMethodsState extends Equatable {
  const PaymentMethodsState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class PaymentMethodsInitial extends PaymentMethodsState {
  const PaymentMethodsInitial();
}

/// Estado de carregamento
class PaymentMethodsLoading extends PaymentMethodsState {
  const PaymentMethodsLoading();
}

/// Estado com dados carregados
class PaymentMethodsLoaded extends PaymentMethodsState {
  final StudentPaymentSettings settings;
  final bool isUpdating;
  final String? error;

  const PaymentMethodsLoaded({
    required this.settings,
    this.isUpdating = false,
    this.error,
  });

  @override
  List<Object?> get props => [settings, isUpdating, error];

  PaymentMethodsLoaded copyWith({
    StudentPaymentSettings? settings,
    bool? isUpdating,
    String? error,
  }) {
    return PaymentMethodsLoaded(
      settings: settings ?? this.settings,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
    );
  }
}

/// Estado de erro
class PaymentMethodsError extends PaymentMethodsState {
  final String message;

  const PaymentMethodsError(this.message);

  @override
  List<Object> get props => [message];
}

/// Estado de validação de cartão
class CardValidationState extends PaymentMethodsState {
  final bool isValid;
  final String? error;
  final CardBrand? detectedBrand;

  const CardValidationState({
    required this.isValid,
    this.error,
    this.detectedBrand,
  });

  @override
  List<Object?> get props => [isValid, error, detectedBrand];
}
