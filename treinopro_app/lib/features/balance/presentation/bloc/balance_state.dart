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

  const BalanceLoaded({
    required this.profile,
    required this.transactions,
  });

  @override
  List<Object?> get props => [profile, transactions];
}

class BalanceError extends BalanceState {
  final String message;
  const BalanceError(this.message);

  @override
  List<Object?> get props => [message];
}
