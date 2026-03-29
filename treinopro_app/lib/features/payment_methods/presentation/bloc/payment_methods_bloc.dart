import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/payment_methods_repository.dart';
import '../../domain/entities/payment_method.dart';
import 'payment_methods_event.dart';
import 'payment_methods_state.dart';

class PaymentMethodsBloc extends Bloc<PaymentMethodsEvent, PaymentMethodsState> {
  final PaymentMethodsRepository repository;

  PaymentMethodsBloc({
    required this.repository,
  }) : super(const PaymentMethodsInitial()) {
    on<LoadPaymentMethods>(_onLoadPaymentMethods);
    on<UpdatePreferredMethod>(_onUpdatePreferredMethod);
    on<UpdatePaymentSettings>(_onUpdatePaymentSettings);
    on<SaveCard>(_onSaveCard);
    on<ValidateCard>(_onValidateCard);
    on<RemoveCard>(_onRemoveCard);
    on<SetDefaultCard>(_onSetDefaultCard);
    on<ValidateMercadoPagoAccount>(_onValidateMercadoPagoAccount);
    on<ClearErrors>(_onClearErrors);
  }

  Future<void> _onLoadPaymentMethods(
    LoadPaymentMethods event,
    Emitter<PaymentMethodsState> emit,
  ) async {
    emit(const PaymentMethodsLoading());
    
    try {
      final settings = await repository.getStudentPaymentMethods();
      emit(PaymentMethodsLoaded(settings: settings));
    } catch (e) {
      emit(PaymentMethodsError(e.toString()));
    }
  }

  Future<void> _onUpdatePreferredMethod(
    UpdatePreferredMethod event,
    Emitter<PaymentMethodsState> emit,
  ) async {
    if (state is! PaymentMethodsLoaded) return;
    
    final currentState = state as PaymentMethodsLoaded;
    emit(currentState.copyWith(isUpdating: true));
    
    try {
      final settings = await repository.updatePaymentMethods(
        preferredMethod: event.method,
      );
      emit(PaymentMethodsLoaded(settings: settings));
    } catch (e) {
      emit(currentState.copyWith(
        isUpdating: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdatePaymentSettings(
    UpdatePaymentSettings event,
    Emitter<PaymentMethodsState> emit,
  ) async {
    if (state is! PaymentMethodsLoaded) return;
    
    final currentState = state as PaymentMethodsLoaded;
    emit(currentState.copyWith(isUpdating: true));
    
    try {
      final settings = await repository.updatePaymentMethods(
        preferredMethod: event.preferredMethod,
        enableAutoPayment: event.enableAutoPayment,
        mpEmail: event.mpEmail,
        mpAllowSaveCard: event.mpAllowSaveCard,
      );
      emit(PaymentMethodsLoaded(settings: settings));
    } catch (e) {
      emit(currentState.copyWith(
        isUpdating: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSaveCard(
    SaveCard event,
    Emitter<PaymentMethodsState> emit,
  ) async {
    if (state is! PaymentMethodsLoaded) return;
    
    final currentState = state as PaymentMethodsLoaded;
    emit(currentState.copyWith(isUpdating: true));
    
    try {
      await repository.saveCard(
        cardNumber: event.cardNumber,
        cardHolderName: event.cardHolderName,
        expiryMonth: event.expiryMonth,
        expiryYear: event.expiryYear,
        cvv: event.cvv,
        cardType: event.cardType,
      );
      
      // Recarregar métodos de pagamento para incluir o novo cartão
      final settings = await repository.getStudentPaymentMethods();
      emit(PaymentMethodsLoaded(settings: settings));
    } catch (e) {
      emit(currentState.copyWith(
        isUpdating: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onValidateCard(
    ValidateCard event,
    Emitter<PaymentMethodsState> emit,
  ) async {
    try {
      final isValid = await repository.validateCard(
        cardNumber: event.cardNumber,
        cardHolderName: event.cardHolderName,
        expiryMonth: event.expiryMonth,
        expiryYear: event.expiryYear,
        cvv: event.cvv,
      );
      
      final brand = _detectCardBrand(event.cardNumber);
      emit(CardValidationState(
        isValid: isValid,
        detectedBrand: brand,
      ));
    } catch (e) {
      emit(CardValidationState(
        isValid: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRemoveCard(
    RemoveCard event,
    Emitter<PaymentMethodsState> emit,
  ) async {
    if (state is! PaymentMethodsLoaded) return;
    
    final currentState = state as PaymentMethodsLoaded;
    emit(currentState.copyWith(isUpdating: true));
    
    try {
      await repository.removeCard(event.cardId);
      
      // Recarregar métodos de pagamento
      final settings = await repository.getStudentPaymentMethods();
      emit(PaymentMethodsLoaded(settings: settings));
    } catch (e) {
      emit(currentState.copyWith(
        isUpdating: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSetDefaultCard(
    SetDefaultCard event,
    Emitter<PaymentMethodsState> emit,
  ) async {
    if (state is! PaymentMethodsLoaded) return;
    
    final currentState = state as PaymentMethodsLoaded;
    emit(currentState.copyWith(isUpdating: true));
    
    try {
      await repository.setDefaultCard(event.cardId);
      
      // Recarregar métodos de pagamento
      final settings = await repository.getStudentPaymentMethods();
      emit(PaymentMethodsLoaded(settings: settings));
    } catch (e) {
      emit(currentState.copyWith(
        isUpdating: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onValidateMercadoPagoAccount(
    ValidateMercadoPagoAccount event,
    Emitter<PaymentMethodsState> emit,
  ) async {
    try {
      final isValid = await repository.validateMercadoPagoAccount(event.email);
      emit(MercadoPagoValidationState(isValid: isValid));
    } catch (e) {
      emit(MercadoPagoValidationState(
        isValid: false,
        error: e.toString(),
      ));
    }
  }

  void _onClearErrors(
    ClearErrors event,
    Emitter<PaymentMethodsState> emit,
  ) {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;
      emit(currentState.copyWith(error: null));
    }
  }

  CardBrand _detectCardBrand(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    if (cleanNumber.startsWith('4')) return CardBrand.visa;
    if (cleanNumber.startsWith('5') || cleanNumber.startsWith('2')) return CardBrand.mastercard;
    if (cleanNumber.startsWith('3')) {
      if (cleanNumber.startsWith('34') || cleanNumber.startsWith('37')) {
        return CardBrand.americanExpress;
      }
      return CardBrand.diners;
    }
    if (cleanNumber.startsWith('6')) return CardBrand.elo;
    if (cleanNumber.startsWith('38')) return CardBrand.hipercard;
    
    return CardBrand.unknown;
  }
}
