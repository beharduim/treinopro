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
