import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/services/realtime_data_service.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../models/onboarding_page_model.dart';
import '../widgets/onboarding_page_content.dart';
import '../widgets/onboarding_pagination.dart';
import '../widgets/onboarding_navigation_buttons.dart';
import '../../../home/presentation/pages/student_home_page.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../classes/presentation/bloc/classes_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../proposals/presentation/bloc/proposal_search_bloc.dart';
import '../../../proposals/presentation/bloc/proposals_bloc.dart';

/// Página de onboarding para alunos
class StudentOnboardingPage extends StatefulWidget {
  const StudentOnboardingPage({super.key});

  @override
  State<StudentOnboardingPage> createState() => _StudentOnboardingPageState();
}

class _StudentOnboardingPageState extends State<StudentOnboardingPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Inicializa o onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OnboardingBloc>().add(const InitializeOnboarding());
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginBackground, // #fcfdfe
      body: BlocListener<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          print(
            'StudentOnboardingPage: BlocListener - estado: ${state.runtimeType}',
          );

          if (state is OnboardingCompleted) {
            print(
              'StudentOnboardingPage: OnboardingCompleted - navegando para home',
            );
            // Navegar para a tela principal do app
            _navigateToMainApp();
          } else if (state is OnboardingError) {
            print('StudentOnboardingPage: OnboardingError - ${state.message}');
            // Mostrar erro
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is OnboardingDisplay) {
            print(
              'StudentOnboardingPage: OnboardingDisplay - currentPage: ${state.currentPage}',
            );
          } else if (state is OnboardingLoading) {
            print('StudentOnboardingPage: OnboardingLoading');
          }
        },
        child: BlocBuilder<OnboardingBloc, OnboardingState>(
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
            return const Center(child: Text('Carregando onboarding...'));
          },
        ),
      ),
    );
  }

  Widget _buildOnboardingContent(OnboardingDisplay onboardingState) {
    final pages = StudentOnboardingPages.pages;
    final currentPage = onboardingState.currentPage;

    return Column(
      children: [
        // Conteúdo da página atual
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (pageIndex) {
              context.read<OnboardingBloc>().add(GoToPage(pageIndex));
            },
            itemBuilder: (context, index) {
              return OnboardingPageContent(
                page: pages[index],
                isLastPage: index == pages.length - 1,
              );
            },
          ),
        ),

        // Paginação - posicionada conforme design do Figma
        Container(
          margin: const EdgeInsets.only(bottom: 40), // Aumentado de 32 para 40
          child: OnboardingPagination(
            currentPage: currentPage,
            totalPages: pages.length,
          ),
        ),

        // Botões de navegação - posicionados com mais espaço da parte inferior
        Container(
          color: AppColors.loginBackground, // Background branco para os botões (branco puro)
          margin: const EdgeInsets.only(bottom: 60), // Aumentado de 24 para 60
          child: OnboardingNavigationButtons(
            currentPage: currentPage,
            totalPages: pages.length,
            onNext: () {
              if (currentPage < pages.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            onPrevious: () {
              if (currentPage > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            onComplete: () {
              context.read<OnboardingBloc>().add(const CompleteOnboarding());
            },
          ),
        ),
      ],
    );
  }

  void _navigateToMainApp() {
    // Navega para a home do aluno após completar o onboarding
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => sl<HomeBloc>()),
            BlocProvider(create: (context) => sl<ClassesBloc>()),
            BlocProvider(create: (context) => sl<GamificationBloc>()),
            BlocProvider.value(value: sl<RealtimeDataService>().proposalSearchBloc ?? sl<ProposalSearchBloc>()),
            BlocProvider(create: (context) => sl<ProposalsBloc>()),
          ],
          child: const StudentHomePage(),
        ),
      ),
    );
  }
}
