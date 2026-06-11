import 'package:equatable/equatable.dart';
import '../../../payouts/data/models/financial_profile_model.dart';
import '../../../home/data/models/payment_models.dart';

import '../../../home/data/models/wallet_dashboard_model.dart';

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
  final WalletDashboardModel dashboard;
  final String? successMessage;

  const BalanceLoaded({
    required this.profile,
    required this.transactions,
    required this.dashboard,
    this.successMessage,
  });

  BalanceLoaded copyWith({
    FinancialProfileModel? profile,
    List<TransactionModel>? transactions,
    WalletDashboardModel? dashboard,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return BalanceLoaded(
      profile: profile ?? this.profile,
      transactions: transactions ?? this.transactions,
      dashboard: dashboard ?? this.dashboard,
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [profile, transactions, dashboard, successMessage];
}

class BalanceError extends BalanceState {
  final String message;
  const BalanceError(this.message);

  @override
  List<Object?> get props => [message];
}
