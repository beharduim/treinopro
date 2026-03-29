import 'package:equatable/equatable.dart';

/// Estado de onboarding do usuário
class OnboardingState extends Equatable {
  final int currentPage;
  final int totalPages;
  final bool isCompleted;

  const OnboardingState({
    this.currentPage = 0,
    this.totalPages = 3,
    this.isCompleted = false,
  });

  OnboardingState copyWith({
    int? currentPage,
    int? totalPages,
    bool? isCompleted,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [currentPage, totalPages, isCompleted];
}
