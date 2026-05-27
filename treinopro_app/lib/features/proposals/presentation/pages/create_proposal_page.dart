import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/proposals_bloc.dart';
import '../bloc/proposals_event.dart';
import '../bloc/proposals_state.dart';
import '../widgets/proposal_progress.dart';
import '../widgets/proposal_status_modal.dart';
import '../widgets/pix_payment_pending_dialog.dart';
import '../bloc/proposal_search_bloc.dart' as proposal_search;
import '../../../../core/di/dependency_injection.dart';
import '../../../payment_methods/domain/repositories/payment_methods_repository.dart';
import 'proposal_step1_page.dart';
import 'proposal_step2_page.dart';
import 'proposal_step3_page.dart';
import 'proposal_review_page.dart';
import '../../../../core/services/realtime_data_service.dart';
import '../../domain/entities/proposal.dart';

/// Página principal de criação de proposta
class CreateProposalPage extends StatelessWidget {
  const CreateProposalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              ProposalsBloc(
                  saveProposal: context.read(),
                  getProposal: context.read(),
                  searchLocations: context.read(),
                  getModalities: context.read(),
                  submitProposal: context.read(),
                  createProposal: context.read(),
                  repository: context.read(),
                  paymentMethodsRepository: sl<PaymentMethodsRepository>(),
                )
                ..add(
                  const ProposalsInitialize(),
                ), // Carrega rascunho salvo; não limpa ao voltar
        ),
        BlocProvider.value(
          value:
              sl<RealtimeDataService>().proposalSearchBloc ??
              sl<proposal_search.ProposalSearchBloc>(),
        ),
      ],
      child: const _CreateProposalView(),
    );
  }
}

class _CreateProposalView extends StatelessWidget {
  const _CreateProposalView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProposalsBloc, ProposalsState>(
      listener: (context, state) {
        if (state is ProposalsError) {
          final detailMessage = state.details
              ?.replaceFirst('Exception: ', '')
              .trim();
          final snackMessage =
              (detailMessage != null && detailMessage.isNotEmpty)
              ? detailMessage
              : state.message;

          // Mostrar snackbar de erro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(snackMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Tentar novamente',
                textColor: Colors.white,
                onPressed: () {
                  // Voltar para o step 3 (seleção de pagamento)
                  context.read<ProposalsBloc>().add(ProposalsNavigateToStep(3));
                },
              ),
            ),
          );

          // Voltar para o step 3 após um pequeno delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              context.read<ProposalsBloc>().add(ProposalsNavigateToStep(3));
            }
          });
        } else if (state is ProposalsSubmitted) {
          _showSuccessAndNavigate(context);
        } else if (state is ProposalsPaymentPending) {
          showPixPaymentPendingDialog(
            context,
            state.payment,
            onAcknowledged: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/student-home',
                (route) => false,
              );
            },
          );
        }
      },
      builder: (context, state) {
        if (state is ProposalsLoading) {
          return const Scaffold(
            backgroundColor: AppColors.loginBackground,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryOrange,
                ),
              ),
            ),
          );
        }

        if (state is ProposalsLoaded) {
          return _buildLoadedContent(context, state);
        }

        if (state is ProposalsError) {
          return _buildErrorContent(context, state);
        }

        if (state is ProposalsSubmitted || state is ProposalsPaymentPending) {
          // Não mostrar nada aqui - o listener vai tratar cada estado
          return const SizedBox.shrink();
        }

        return const Scaffold(
          backgroundColor: AppColors.loginBackground,
          body: Center(child: Text('Estado não reconhecido')),
        );
      },
    );
  }

  Widget _buildLoadedContent(BuildContext context, ProposalsLoaded state) {
    return PopScope(
      canPop: state.currentStep == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context, state);
      },
      child: Scaffold(
        backgroundColor: AppColors.loginBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Header com botão voltar e título
              _buildHeader(context, state),

              // Barra de progresso (oculta na revisão)
              if (state.currentStep <= 3) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ProposalProgress(
                    currentStep: state.currentStep,
                    totalSteps: 3,
                    stepTitles: const ['Onde & Quando', 'Como será', 'Valor'],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Conteúdo da etapa atual
              Expanded(child: _buildStepContent(state.currentStep)),

              // Botões de navegação
              _buildNavigationButtons(context, state),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBack(BuildContext context, ProposalsLoaded state) {
    if (state.canGoToPreviousStep) {
      context.read<ProposalsBloc>().add(const ProposalsPreviousStep());
      return;
    }

    context.read<proposal_search.ProposalSearchBloc>().add(
      const proposal_search.ResetProposalSearch(),
    );
    context.read<ProposalsBloc>().add(const ProposalsClear());
    Navigator.of(context).pop();
  }

  Widget _buildHeader(BuildContext context, ProposalsLoaded state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _handleBack(context, state),
            icon: const Icon(
              Icons.chevron_left,
              color: AppColors.secondary,
              size: 24,
            ),
          ),
          Expanded(
            child: Text(
              'Criar proposta',
              style: AppTextStyles.h6Semibold.copyWith(
                color: AppColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Para centralizar o título
        ],
      ),
    );
  }

  Widget _buildStepContent(int currentStep) {
    switch (currentStep) {
      case 1:
        return const ProposalStep1Page();
      case 2:
        return const ProposalStep2Page();
      case 3:
        return const ProposalStep3Page();
      case 4:
        return const ProposalReviewPage();
      default:
        return const ProposalStep1Page();
    }
  }

  Widget _buildNavigationButtons(BuildContext context, ProposalsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Botão principal
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _getMainButtonAction(context, state),
              style: ElevatedButton.styleFrom(
                backgroundColor: state.canGoToNextStep || state.canSubmit
                    ? AppColors.primaryOrange
                    : AppColors.inputBackground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _getMainButtonText(state),
                      style: AppTextStyles.buttonPrimary.copyWith(
                        color: state.canGoToNextStep || state.canSubmit
                            ? AppColors.white
                            : AppColors.secondaryDark.withOpacity(0.6),
                      ),
                    ),
            ),
          ),

          // Botão voltar (apenas se não for a primeira etapa)
          if (state.canGoToPreviousStep) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _handleBack(context, state);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryOrange,
                  side: const BorderSide(
                    color: AppColors.primaryOrange,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Voltar',
                  style: AppTextStyles.buttonPrimary.copyWith(
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  VoidCallback? _getMainButtonAction(
    BuildContext context,
    ProposalsLoaded state,
  ) {
    if (state.isSubmitting) return null;

    if (state.canSubmit) {
      return () async {
        final canSubmit = await _ensureSavedCardCvvIfNeeded(context, state);
        if (!canSubmit || !context.mounted) return;
        context.read<ProposalsBloc>().add(const ProposalsSubmit());
      };
    }

    if (state.canGoToNextStep) {
      return () {
        context.read<ProposalsBloc>().add(const ProposalsNextStep());
      };
    }

    return null;
  }

  String _getMainButtonText(ProposalsLoaded state) {
    if (state.canSubmit) {
      return 'Confirmar';
    }

    if (state.canGoToNextStep) {
      return 'Continuar';
    }

    return '';
  }

  bool _requiresSavedCardCvv(ProposalsLoaded state) {
    return false;
  }

  Future<bool> _ensureSavedCardCvvIfNeeded(
    BuildContext context,
    ProposalsLoaded state,
  ) async {
    if (!_requiresSavedCardCvv(state)) {
      return true;
    }

    return true;
  }

  Widget _buildErrorContent(BuildContext context, ProposalsError state) {
    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'Ops! Algo deu errado',
                style: AppTextStyles.h6Semibold.copyWith(
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                state.message,
                style: AppTextStyles.paragraph.copyWith(
                  color: AppColors.secondaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              if (state.details != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.details!,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.secondaryDark.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<ProposalsBloc>().add(
                      const ProposalsInitialize(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Tentar novamente',
                    style: AppTextStyles.buttonPrimary.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessAndNavigate(
    BuildContext context, {
    Proposal? submittedProposal,
    String? proposalId,
  }) {
    print('🔄 [PROPOSALS BLOC] _showSuccessAndNavigate iniciado');

    // Verificar se o contexto ainda está montado
    if (!context.mounted) {
      print('❌ [PROPOSALS BLOC] Contexto não está montado, abortando');
      return;
    }

    // Obter os dados da proposta antes de navegar
    final proposalsState = context.read<ProposalsBloc>().state;
    String location = 'Local não informado';
    DateTime? trainingDate;
    String? trainingTime;
    Proposal? proposal = submittedProposal;
    String? resolvedProposalId = proposalId;

    if (proposalsState is ProposalsSubmitted) {
      proposal = proposalsState.submittedProposal;
      resolvedProposalId ??= proposalsState.proposalId;
    }

    if (proposal != null) {
      location = proposal.locationName ?? 'Local não informado';
      trainingDate = proposal.trainingDate;
      trainingTime = proposal.trainingTime;
      print('🔄 [PROPOSALS BLOC] ProposalId obtido: $resolvedProposalId');
    }

    // 1. PRIMEIRO: Disparar estado de busca no HomeBloc (para o card dinâmico)
    // ✅ CORREÇÃO: Usar RealtimeDataService que tem a referência correta do HomeBloc
    // Em vez de context.read que pode pegar uma instância diferente
    try {
      final realtimeService = sl<RealtimeDataService>();
      print(
        '🔍 [PROPOSALS BLOC] Usando RealtimeDataService para notificar HomeBloc',
      );

      // Disparar evento através do RealtimeDataService que tem o HomeBloc correto
      realtimeService.notifyProposalCreated(
        location: location,
        trainingDate: trainingDate ?? DateTime.now(),
        trainingTime: trainingTime ?? '00:00',
      );

      print('✅ [PROPOSALS BLOC] HomeBloc notificado via RealtimeDataService');
      print('✅ [PROPOSALS BLOC] Location: $location');
      print('✅ [PROPOSALS BLOC] TrainingDate: $trainingDate');
      print('✅ [PROPOSALS BLOC] TrainingTime: $trainingTime');
    } catch (e) {
      print('❌ [PROPOSALS BLOC] Erro ao notificar HomeBloc: $e');
      print('❌ [PROPOSALS BLOC] Stack trace: ${StackTrace.current}');
    }

    // 2. SEGUNDO: Disparar StartProposalSearch diretamente no ProposalSearchBloc
    final searchBloc = context.read<proposal_search.ProposalSearchBloc>();
    try {
      print(
        '🔄 [PROPOSALS BLOC] Estado atual do ProposalSearchBloc: ${searchBloc.state.runtimeType}',
      );
      searchBloc.add(
        proposal_search.StartProposalSearch(
          location: location,
          trainingDate: trainingDate,
          trainingTime: trainingTime,
          proposalId: resolvedProposalId,
        ),
      );
      print(
        '✅ [PROPOSALS BLOC] ProposalSearchBloc evento adicionado com sucesso',
      );
      print(
        '🔄 [PROPOSALS BLOC] Estado após StartProposalSearch: ${searchBloc.state.runtimeType}',
      );
    } catch (e) {
      print(
        '❌ [PROPOSALS BLOC] Erro ao adicionar evento ao ProposalSearchBloc: $e',
      );
    }

    // 3. TERCEIRO: Aguardar processamento do estado e mostrar modal
    // Aguardar um pouco para garantir que o ProposalSearchBloc processe o StartProposalSearch
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!context.mounted) {
        print('❌ [PROPOSALS BLOC] Contexto não montado após delay, abortando');
        return;
      }

      print(
        '🔄 [PROPOSALS BLOC] Estado final do ProposalSearchBloc: ${searchBloc.state.runtimeType}',
      );

      // Criar modal no overlay global
      final overlay = Overlay.of(context, rootOverlay: true);
      OverlayEntry? overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (overlayContext) => Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // Blur background (igual ao showProposalStatusModal)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),
              ),
              // Modal content
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: BlocProvider.value(
                    value: searchBloc,
                    child:
                        BlocListener<
                          proposal_search.ProposalSearchBloc,
                          proposal_search.ProposalSearchState
                        >(
                          listener: (context, state) {
                            print(
                              '🔔 [PROPOSAL_MODAL] Estado recebido no listener: ${state.runtimeType}',
                            );
                            // Se a busca foi cancelada, expirou ou voltou ao estado inicial, fechar o modal
                            if (state
                                    is proposal_search.ProposalSearchCancelled ||
                                state
                                    is proposal_search.ProposalSearchInitial) {
                              print(
                                '🔔 [PROPOSAL_MODAL] Fechando modal (state=${state.runtimeType})',
                              );
                              // Garantir que a remoção aconteça após o ciclo de build atual
                              Future.microtask(() {
                                try {
                                  overlayEntry?.remove();
                                } catch (_) {}
                              });
                            } else if (state
                                is proposal_search.ProposalSearchMatched) {
                              // Match encontrado: manter modal aberto até o aluno fechar ou ir para o chat (comportamento do Personal)
                              print(
                                '🔔 [PROPOSAL_MODAL] Match confirmado! Mantendo modal aberto para o aluno.',
                              );
                              /*
                              Future.delayed(const Duration(seconds: 3), () {
                                try {
                                  overlayEntry?.remove();
                                } catch (_) {}
                              });
                              */
                            }
                          },
                          child: ProposalStatusModal(
                            location:
                                location, // Usar localização real da proposta
                            proposalId:
                                resolvedProposalId, // Passar o ID da proposta
                            onClose: () {
                              overlayEntry?.remove();
                              // Quando o modal for fechado, a busca continua em background
                              // O card da home mostrará a versão compacta
                            },
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // Inserir modal no overlay
      print('🔄 [PROPOSALS BLOC] Inserindo modal no overlay');
      overlay.insert(overlayEntry);
      print('✅ [PROPOSALS BLOC] Modal inserido no overlay com sucesso');

      // Navegar para home
      if (context.mounted) {
        print('🔄 [PROPOSALS BLOC] Navegando de volta para home');
        Navigator.of(context).pop();
      } else {
        print(
          '❌ [PROPOSALS BLOC] Contexto não montado, não é possível navegar',
        );
      }
    });
  }
}
