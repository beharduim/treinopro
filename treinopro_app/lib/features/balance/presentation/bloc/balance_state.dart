import 'package:equatable/equatable.dart';
import '../../../payouts/data/models/financial_profile_model.dart';
import '../../../home/data/models/payment_models.dart';

abstract class BalanceState extends Equatable {
  const BalanceState();

  @override
  List<Object?> get props => [];
}

class BalanceInitial extends BalanceState {}

class BalanceLoading extends BalanceState {}

class BalanceLoaded extends BalanceState {
  final FinancialProfileModel profile;
  final List<TransactionModel> transactions;
  final String? successMessage;

  const BalanceLoaded({
    required this.profile,
    required this.transactions,
    this.successMessage,
  });

  BalanceLoaded copyWith({
    FinancialProfileModel? profile,
    List<TransactionModel>? transactions,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return BalanceLoaded(
      profile: profile ?? this.profile,
      transactions: transactions ?? this.transactions,
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [profile, transactions, successMessage];
}

class BalanceError extends BalanceState {
  final String message;
  const BalanceError(this.message);

  @override
  List<Object?> get props => [message];
}
