import 'package:equatable/equatable.dart';

/// Eventos do BLoC de onboarding
abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para inicializar o onboarding
class InitializeOnboarding extends OnboardingEvent {
  const InitializeOnboarding();
}

/// Evento para ir para a próxima página
class NextPage extends OnboardingEvent {
  const NextPage();
}

/// Evento para ir para a página anterior
class PreviousPage extends OnboardingEvent {
  const PreviousPage();
}

/// Evento para ir para uma página específica
class GoToPage extends OnboardingEvent {
  final int pageIndex;

  const GoToPage(this.pageIndex);

  @override
  List<Object?> get props => [pageIndex];
}

/// Evento para completar o onboarding
class CompleteOnboarding extends OnboardingEvent {
  const CompleteOnboarding();
}
