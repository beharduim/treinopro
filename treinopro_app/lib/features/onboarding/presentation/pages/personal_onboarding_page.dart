import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../widgets/onboarding_page_content.dart';
import '../widgets/onboarding_page_indicator.dart';
import '../widgets/onboarding_buttons.dart';
import '../models/onboarding_page_model.dart';

class PersonalOnboardingPage extends StatefulWidget {
  const PersonalOnboardingPage({super.key});

  @override
  State<PersonalOnboardingPage> createState() => _PersonalOnboardingPageState();
}

class _PersonalOnboardingPageState extends State<PersonalOnboardingPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    context.read<OnboardingBloc>().add(const InitializeOnboarding());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingDisplay) {
          _pageController.animateToPage(
            state.currentPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else if (state is OnboardingCompleted) {
          Navigator.of(context).pushReplacementNamed('/personal-home');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.loginBackground,
        body: BlocBuilder<OnboardingBloc, OnboardingState>(
          builder: (context, state) {
            if (state is OnboardingLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryOrange,
                  ),
                ),
              );
            }

            if (state is OnboardingDisplay) {
              return _buildOnboardingContent(state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildOnboardingContent(OnboardingDisplay state) {
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              context.read<OnboardingBloc>().add(GoToPage(index));
            },
            children: _buildOnboardingPages(),
          ),
        ),
        SafeArea(
          child: Container(
            color: AppColors.loginBackground, // Background branco para os botões (branco puro)
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32, top: 16),
              child: Column(
              children: [
                OnboardingPageIndicator(
                  currentPage: state.currentPage,
                  totalPages: state.totalPages,
                ),
                const SizedBox(height: 32),
                OnboardingButtons(
                  canGoPrevious: state.canGoPrevious,
                  canGoNext: state.canGoNext,
                  isLastPage: state.currentPage == state.totalPages - 1,
                  onPrevious: () => context.read<OnboardingBloc>().add(const PreviousPage()),
                  onNext: () => context.read<OnboardingBloc>().add(const NextPage()),
                  onComplete: () => context.read<OnboardingBloc>().add(const CompleteOnboarding()),
                ),
              ],
            ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOnboardingPages() {
    return TeacherOnboardingPages.pages.map((pageModel) {
      return OnboardingPageContent(
        page: pageModel,
        isLastPage: pageModel == TeacherOnboardingPages.pages.last,
      );
    }).toList();
  }
}


