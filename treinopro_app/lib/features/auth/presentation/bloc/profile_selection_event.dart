import 'package:equatable/equatable.dart';

/// Eventos para a tela de seleção de perfil
abstract class ProfileSelectionEvent extends Equatable {
  const ProfileSelectionEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para selecionar perfil de aluno
class SelectStudentProfile extends ProfileSelectionEvent {
  const SelectStudentProfile();
}

/// Evento para selecionar perfil de personal trainer
class SelectTrainerProfile extends ProfileSelectionEvent {
  const SelectTrainerProfile();
}

/// Evento para voltar à tela anterior
class NavigateBack extends ProfileSelectionEvent {
  const NavigateBack();
}
