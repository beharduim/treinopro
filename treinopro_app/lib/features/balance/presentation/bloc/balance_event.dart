import 'package:equatable/equatable.dart';

abstract class BalanceEvent extends Equatable {
  const BalanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadBalance extends BalanceEvent {
  final bool silent;
  const LoadBalance({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

class RefreshBalance extends BalanceEvent {}

class RequestWithdrawal extends BalanceEvent {
  final double amount;
  final String sourceBucket;

  const RequestWithdrawal(this.amount, {required this.sourceBucket});

  @override
  List<Object?> get props => [amount, sourceBucket];
}
