import 'package:equatable/equatable.dart';
import '../../domain/entities/home_state.dart';

/// Estados do BLoC da home
abstract class HomeBlocState extends Equatable {
  const HomeBlocState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class HomeInitial extends HomeBlocState {
  const HomeInitial();
}

/// Estado de carregamento
class HomeLoading extends HomeBlocState {
  const HomeLoading();
}

/// Estado carregado com sucesso
class HomeLoaded extends HomeBlocState {
  final HomeState homeState;

  const HomeLoaded(this.homeState);

  @override
  List<Object?> get props => [homeState];
}

/// Estado de erro
class HomeError extends HomeBlocState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
