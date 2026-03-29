import 'package:equatable/equatable.dart';

/// Estados para a tela de seleção de perfil
abstract class ProfileSelectionState extends Equatable {
  const ProfileSelectionState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial da tela de seleção de perfil
class ProfileSelectionInitial extends ProfileSelectionState {}

/// Estado de loading durante seleção
class ProfileSelectionLoading extends ProfileSelectionState {}

/// Estado para navegar para cadastro de aluno
class NavigateToStudentRegistration extends ProfileSelectionState {}

/// Estado para navegar para cadastro de personal trainer
class NavigateToTrainerRegistration extends ProfileSelectionState {}

/// Estado para voltar à tela inicial
class NavigateBackToInitial extends ProfileSelectionState {}

/// Estado de erro
class ProfileSelectionError extends ProfileSelectionState {
  final String message;

  const ProfileSelectionError(this.message);

  @override
  List<Object?> get props => [message];
}
