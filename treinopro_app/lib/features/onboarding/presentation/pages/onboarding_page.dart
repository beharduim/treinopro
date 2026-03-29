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

/// Página do onboarding seguindo exatamente o design do Figma
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Inicializa o onboarding
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
          // Anima para a página correspondente
          _pageController.animateToPage(
            state.currentPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else if (state is OnboardingCompleted) {
          // Navegar para a próxima tela (home, login, etc.)
          _navigateToNextScreen();
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

            // Estado inicial ou erro
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  /// Constrói o conteúdo do onboarding
  Widget _buildOnboardingContent(OnboardingDisplay state) {
    return Column(
      children: [
        // Área principal com PageView
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              context.read<OnboardingBloc>().add(GoToPage(index));
            },
            children: _buildOnboardingPages(),
          ),
        ),

        // Área inferior com indicador e botões
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 32,
              top: 16,
            ),
            child: Column(
              children: [
                // Indicador de páginas
                OnboardingPageIndicator(
                  currentPage: state.currentPage,
                  totalPages: state.totalPages,
                ),

                const SizedBox(height: 32),

                // Botões de navegação
                OnboardingButtons(
                  canGoPrevious: state.canGoPrevious,
                  canGoNext: state.canGoNext,
                  isLastPage: state.currentPage == state.totalPages - 1,
                  onPrevious: () {
                    context.read<OnboardingBloc>().add(const PreviousPage());
                  },
                  onNext: () {
                    context.read<OnboardingBloc>().add(const NextPage());
                  },
                  onComplete: () {
                    context.read<OnboardingBloc>().add(
                      const CompleteOnboarding(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Constrói as páginas do onboarding
  List<Widget> _buildOnboardingPages() {
    return StudentOnboardingPages.pages.map((pageModel) {
      return OnboardingPageContent(
        page: pageModel,
        isLastPage: pageModel == StudentOnboardingPages.pages.last,
      );
    }).toList();
  }

  /// Navega para a próxima tela após completar o onboarding
  void _navigateToNextScreen() {
    // Aqui você pode implementar a navegação para a tela principal
    // Por exemplo, para a home do aluno ou para um questionário inicial

    Navigator.of(context).pushReplacementNamed('/home');

    // Ou, se ainda não tiver a tela de home, pode mostrar um SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Onboarding concluído! Bem-vindo ao TreinoPro!'),
        backgroundColor: AppColors.primaryOrange,
      ),
    );
  }
}
