import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/proposals_bloc.dart';
import '../bloc/proposals_event.dart';
import '../bloc/proposals_state.dart';
import '../widgets/proposal_progress.dart';
import '../widgets/proposal_status_modal.dart';
import '../bloc/proposal_search_bloc.dart' as proposal_search;
import '../../../../core/di/dependency_injection.dart';
import '../../../payment_methods/domain/repositories/payment_methods_repository.dart';
import 'proposal_step1_page.dart';
import 'proposal_step2_page.dart';
import 'proposal_step3_page.dart';
import 'proposal_review_page.dart';
import '../../../../core/services/realtime_data_service.dart';
import '../../data/services/proposals_api_service.dart';

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
                ..add(const ProposalsClear())
                ..add(
                  const ProposalsInitialize(),
                ), // Limpa e inicializa para começar na etapa 1
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
          // Redirecionar para checkout ou mostrar modal de pagamento pendente
          _showSuccessAndNavigate(context);
        } else if (state is ProposalsPixPending) {
          _showPixModal(context, state);
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

        if (state is ProposalsSubmitted ||
            state is ProposalsPaymentPending ||
            state is ProposalsPixPending) {
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
    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header com botão voltar e título
            _buildHeader(context),

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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              // Reset do estado do ProposalSearchBloc antes de voltar
              context.read<proposal_search.ProposalSearchBloc>().add(
                const proposal_search.ResetProposalSearch(),
              );

              // Reset da proposta atual se estiver no meio do processo
              context.read<ProposalsBloc>().add(const ProposalsClear());

              Navigator.of(context).pop();
            },
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
                  context.read<ProposalsBloc>().add(
                    const ProposalsPreviousStep(),
                  );
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
      return () {
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

  void _showPixModal(BuildContext context, ProposalsPixPending state) {
    // Mostrar o QR code na página atual (contexto válido).
    // Decisão de UX intencional: após o usuário fechar/copiar o código PIX,
    // o app retorna à home onde o card de proposta mostra "aguardando pagamento".
    // Isso é o fluxo esperado — o usuário já tem o código e não precisa permanecer
    // na tela de criação.
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _PixQrCodeSheet(
        qrCode: state.qrCode,
        qrCodeBase64: state.qrCodeBase64,
        expiresAt: state.expiresAt,
        proposalId: state.proposalId,
      ),
    ).then((_) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showSuccessAndNavigate(BuildContext context) {
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
    String? proposalId;

    if (proposalsState is ProposalsSubmitted) {
      final proposal = proposalsState.submittedProposal;
      location = proposal.locationName ?? 'Local não informado';
      trainingDate = proposal.trainingDate;
      trainingTime = proposal.trainingTime;
      proposalId = proposalsState.proposalId;
      print('🔄 [PROPOSALS BLOC] ProposalId obtido: $proposalId');
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
          proposalId: proposalId,
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
                            proposalId: proposalId, // Passar o ID da proposta
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

/// Bottom sheet com QR Code PIX para pagamento
class _PixQrCodeSheet extends StatefulWidget {
  final String qrCode;
  final String? qrCodeBase64;
  final DateTime? expiresAt;
  final String proposalId;

  const _PixQrCodeSheet({
    required this.qrCode,
    this.qrCodeBase64,
    this.expiresAt,
    required this.proposalId,
  });

  @override
  State<_PixQrCodeSheet> createState() => _PixQrCodeSheetState();
}

class _PixQrCodeSheetState extends State<_PixQrCodeSheet> {
  Timer? _pollingTimer;
  Timer? _expiryTimer;
  bool _paymentConfirmed = false;
  final _proposalsApiService = sl<ProposalsApiService>();

  static const _confirmedStatuses = {'captured', 'approved', 'authorized'};

  @override
  void initState() {
    super.initState();
    _startPolling();
    // Atualiza o contador de expiração a cada 30 segundos
    _expiryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_paymentConfirmed || !mounted) return;
      try {
        final proposal =
            await _proposalsApiService.getProposalById(widget.proposalId);
        final status = (proposal.paymentStatus ?? '').toLowerCase();
        if (_confirmedStatuses.contains(status)) {
          _paymentConfirmed = true;
          _pollingTimer?.cancel();
          if (mounted) Navigator.of(context).pop();
        }
      } on Exception catch (e) {
        final msg = e.toString().toLowerCase();
        // Proposta deletada/expirada no servidor (404) — fechar o modal
        if (msg.contains('404') ||
            msg.contains('não encontrada') ||
            msg.contains('not found')) {
          _pollingTimer?.cancel();
          _expiryTimer?.cancel();
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Proposta expirada. Nenhum treino foi cobrado.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        // Outros erros de rede — continua tentando
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Ícone PIX + título
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF32BCAD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.qr_code, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pague com PIX',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Escaneie o QR Code ou copie o código abaixo',
            style: TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 14,
              color: Color(0xFF4A5568),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // QR Code image (base64) ou placeholder
          if (widget.qrCodeBase64 != null && widget.qrCodeBase64!.isNotEmpty)
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF32BCAD), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _decodeQrImage(widget.qrCodeBase64!),
              ),
            )
          else
            _buildQrPlaceholder(),

          const SizedBox(height: 20),

          // Expiração
          if (widget.expiresAt != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 14,
                    color: Color(0xFF856404),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Expira em ${_formatExpiry(widget.expiresAt!)}',
                    style: const TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 13,
                      color: Color(0xFF856404),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Campo de código copia-e-cola
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.qrCode,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 12,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _copyToClipboard(context),
                  child: const Icon(
                    Icons.copy,
                    size: 20,
                    color: Color(0xFF32BCAD),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Botão copiar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _copyToClipboard(context),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copiar código PIX'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF32BCAD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Botão fechar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFCBD5E0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Fechar',
                style: TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 15,
                  color: Color(0xFF4A5568),
                ),
              ),
            ),
          ),

          const Text(
            'Sua proposta foi criada. Após o pagamento, você será conectado a um personal trainer.',
            style: TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 12,
              color: Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Decodifica base64 em imagem; em caso de string inválida exibe placeholder.
  Widget _decodeQrImage(String base64Str) {
    try {
      final bytes = base64Decode(base64Str);
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildQrPlaceholder(),
      );
    } catch (_) {
      return _buildQrPlaceholder();
    }
  }

  Widget _buildQrPlaceholder() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF32BCAD), width: 2),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2, size: 80, color: Color(0xFF32BCAD)),
          SizedBox(height: 8),
          Text(
            'QR Code PIX',
            style: TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 14,
              color: Color(0xFF4A5568),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.qrCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código PIX copiado!'),
        backgroundColor: Color(0xFF32BCAD),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatExpiry(DateTime expiresAt) {
    final now = DateTime.now();
    final diff = expiresAt.difference(now);
    if (diff.isNegative) return 'Expirado';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h ${diff.inMinutes % 60}min';
    return '${diff.inDays} dias';
  }
}
