import 'package:equatable/equatable.dart';

/// Estados do onboarding
abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object> get props => [];
}

/// Estado inicial do onboarding
class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

/// Estado quando o onboarding está carregando
class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

/// Estado quando o onboarding está sendo exibido
class OnboardingDisplay extends OnboardingState {
  final int currentPage;
  final int totalPages;
  final bool canGoNext;
  final bool canGoPrevious;

  const OnboardingDisplay({
    required this.currentPage,
    required this.totalPages,
    required this.canGoNext,
    required this.canGoPrevious,
  });

  @override
  List<Object> get props => [currentPage, totalPages, canGoNext, canGoPrevious];
}

/// Estado quando o onboarding foi completado
class OnboardingCompleted extends OnboardingState {
  const OnboardingCompleted();
}

/// Estado de erro do onboarding
class OnboardingError extends OnboardingState {
  final String message;

  const OnboardingError(this.message);

  @override
  List<Object> get props => [message];
}
