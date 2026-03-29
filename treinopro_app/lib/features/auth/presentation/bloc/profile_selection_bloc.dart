import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_selection_event.dart';
import 'profile_selection_state.dart';

/// BLoC responsável pela lógica da tela de seleção de perfil
class ProfileSelectionBloc
    extends Bloc<ProfileSelectionEvent, ProfileSelectionState> {
  ProfileSelectionBloc() : super(ProfileSelectionInitial()) {
    on<SelectStudentProfile>(_onSelectStudentProfile);
    on<SelectTrainerProfile>(_onSelectTrainerProfile);
    on<NavigateBack>(_onNavigateBack);
  }

  Future<void> _onSelectStudentProfile(
    SelectStudentProfile event,
    Emitter<ProfileSelectionState> emit,
  ) async {
    try {
      emit(ProfileSelectionLoading());

      // Aqui pode ser adicionada lógica de negócio se necessário
      // Por exemplo, salvar a escolha do usuário ou fazer alguma validação

      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Pequeno delay para feedback visual

      emit(NavigateToStudentRegistration());
    } catch (e) {
      emit(
        ProfileSelectionError(
          'Erro ao selecionar perfil de aluno: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onSelectTrainerProfile(
    SelectTrainerProfile event,
    Emitter<ProfileSelectionState> emit,
  ) async {
    try {
      emit(ProfileSelectionLoading());

      // Aqui pode ser adicionada lógica de negócio se necessário
      // Por exemplo, salvar a escolha do usuário ou fazer alguma validação

      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Pequeno delay para feedback visual

      emit(NavigateToTrainerRegistration());
    } catch (e) {
      emit(
        ProfileSelectionError(
          'Erro ao selecionar perfil de personal trainer: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onNavigateBack(
    NavigateBack event,
    Emitter<ProfileSelectionState> emit,
  ) async {
    emit(NavigateBackToInitial());
  }
}
