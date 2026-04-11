import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/image_viewer_modal.dart';
import '../bloc/proposal_search_bloc.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../classes/data/services/classes_api_service.dart';
import '../../../users/data/services/users_api_service.dart';

/// Modal que mostra o status da busca por profissional
class ProposalStatusModal extends StatefulWidget {
  final String location;
  final VoidCallback? onClose;
  final Duration? currentDuration;
  final String? proposalId;
  final bool autoCloseOnMatched;

  const ProposalStatusModal({
    super.key,
    required this.location,
    this.onClose,
    this.currentDuration,
    this.proposalId,
    this.autoCloseOnMatched = false,
  });

  @override
  State<ProposalStatusModal> createState() => _ProposalStatusModalState();
}

class _ProposalStatusModalState extends State<ProposalStatusModal>
    with TickerProviderStateMixin {
  late AnimationController _searchAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _rippleAnimationController;
  late AnimationController _scaleAnimationController;

  late Animation<double> _searchAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _scaleAnimation;

  // Enriquecimento de dados do match (quando disponível via API/WS)
  String? _enrichedPersonalName;
  String? _enrichedPersonalPhoto;
  double? _enrichedPersonalRating;
  String? _enrichedPersonalTimeOnPlatform;
  String? _enrichedReceiverId; // personalId (para o aluno)
  String? _enrichedClassId;
  String? _enrichedLocation;
  String? _enrichedDate;
  String? _enrichedTime;
  String? _enrichedDuration;
  String? _enrichedModality;
  bool _isFetchingEnrichment = false;
  String? _enrichedForProposalId;
  int _enrichmentAttempts = 0;

  /// Formatar data para exibição (dd/mm)
  String _formatTrainingDate(DateTime? date) {
    if (date == null) return '--/--';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  /// Formatar horário para exibição
  String _formatTrainingTime(String? time) {
    return time ?? '--:--';
  }


  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Animação da lupa (rotação suave + oscilação)
    _searchAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Animação de pulso mais dinâmica
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Animação de ondas concêntricas
    _rippleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Animação de entrada do modal
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Iniciar animações
    _searchAnimationController.repeat();
    _pulseAnimationController.repeat(reverse: true);
    _rippleAnimationController.repeat();
    _scaleAnimationController.forward();
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _pulseAnimationController.dispose();
    _rippleAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: BlocListener<ProposalSearchBloc, ProposalSearchState>(
        listener: (context, state) {
          // Se habilitado, fechar modal automaticamente após 3 segundos quando match é encontrado
          // NOTA: Desativado para alinhar com o comportamento do Personal (manter aberto até fechar ou ir para o chat)
          /*
          if (state.modalState == ProposalModalState.matched && widget.autoCloseOnMatched) {
            Future.delayed(const Duration(seconds: 3), () {
              if (!mounted) return;
              // Priorizar callback externo para fechar corretamente (overlay ou dialog)
                if (widget.onClose != null) {
                  widget.onClose!();
              } else if (Navigator.canPop(context)) {
                // Fallback apenas se não houver callback
                Navigator.of(context).pop();
              }
            });
          }
          */
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: BlocBuilder<ProposalSearchBloc, ProposalSearchState>(
                builder: (context, state) {
                  final bool isMatched = state.modalState == ProposalModalState.matched;
                  return Container(
              decoration: BoxDecoration(
                    color: isMatched ? const Color(0xFFF9F9F9) : Colors.white,
                    borderRadius: isMatched ? BorderRadius.circular(12) : BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                  ),
                ],
              ),
                  child: Stack(
                  children: [
                      // Conteúdo do modal
                    _buildDynamicContent(),

                      // Botão X de fechar
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          onPressed: () {
                            if (widget.onClose != null) {
                              widget.onClose!();
                            }
                          },
                          icon: const Icon(
                            Icons.close,
                            size: 20,
                            color: Color(0xFF6B7280),
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ),
      ),
    );
  }


  Widget _buildDynamicContent() {
    return BlocBuilder<ProposalSearchBloc, ProposalSearchState>(
      builder: (context, state) {
        print('🔔 [PROPOSAL_STATUS_MODAL] BlocBuilder executado - Estado: ${state.runtimeType}');
        print('🔔 [PROPOSAL_STATUS_MODAL] ModalState: ${state.modalState}');
        if (state is ProposalSearchMatched) {
          print('🔔 [PROPOSAL_STATUS_MODAL] Estado é ProposalSearchMatched!');
          print('🔔 [PROPOSAL_STATUS_MODAL] personalName: ${state.personalName}');
          print('🔔 [PROPOSAL_STATUS_MODAL] personalPhoto: ${state.personalPhoto}');
        }
        
        return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildContentForModalState(state),
        );
      },
    );
  }

  Widget _buildContentForModalState(ProposalSearchState state) {
    // Estrutura única do modal - apenas o conteúdo muda
    return Column(
      mainAxisSize: MainAxisSize.min, // ✅ Igual ao proposal_modal.dart
      key: ValueKey(state.modalState), // Chave única para cada estado
      children: [
        // Animação (muda o ícone)
        _buildAnimationForState(state),

        // Título (muda o texto)
        _buildTitleForState(state),

        // Informações (muda o conteúdo)
        _buildInfoForState(state),

        // Progress indicator (muda o progresso)
        _buildProgressForState(state),

        // Timer (muda o conteúdo)
        _buildTimerForState(state),

        // Botão de ação (muda o texto e ação)
        _buildActionButtonForState(state),

        // Espaçamento inferior para evitar que o botão fique colado
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAnimationForState(ProposalSearchState state) {
    return _getAnimationForState(state);
  }

  Widget _getAnimationForState(ProposalSearchState state) {
    switch (state.modalState) {
      case ProposalModalState.searching:
        return _buildEnhancedSearchAnimation();
      case ProposalModalState.matched:
        return _buildMatchAnimation();
      case ProposalModalState.completed:
        return _buildSuccessAnimation();
      case ProposalModalState.cancelled:
        return _buildCancelledAnimation();
      case ProposalModalState.confirming_cancel:
        return _buildConfirmCancelAnimation();
      case ProposalModalState.confirming_cancel_session:
        return _buildConfirmSessionCancelAnimation();
      case ProposalModalState.initial:
        return _buildEnhancedSearchAnimation();
    }
  }

  Widget _buildTitleForState(ProposalSearchState state) {
    return _getTitleForState(state);
  }

  Widget _getTitleForState(ProposalSearchState state) {
    switch (state.modalState) {
      case ProposalModalState.searching:
        return _buildTitle();
      case ProposalModalState.matched:
        return const SizedBox.shrink();
      case ProposalModalState.completed:
        return _buildSuccessTitle();
      case ProposalModalState.cancelled:
        return _buildCancelledTitle();
      case ProposalModalState.confirming_cancel:
        return _buildConfirmCancelTitle();
      case ProposalModalState.confirming_cancel_session:
        return _buildConfirmSessionCancelTitle();
      case ProposalModalState.initial:
        return _buildTitle();
    }
  }

  Widget _buildInfoForState(ProposalSearchState state) {
    return _getInfoForState(state);
  }

  Widget _getInfoForState(ProposalSearchState state) {
    switch (state.modalState) {
      case ProposalModalState.searching:
        return _buildSearchInfo(state);
      case ProposalModalState.matched:
        return _buildMatchInfo(state as ProposalSearchMatched);
      case ProposalModalState.completed:
        return _buildSessionInfo(state as ProposalSearchCompleted);
      case ProposalModalState.cancelled:
        return _buildCancelledMessage();
      case ProposalModalState.confirming_cancel:
        return _buildConfirmCancelInfo();
      case ProposalModalState.confirming_cancel_session:
        return _buildConfirmSessionCancelInfo();
      case ProposalModalState.initial:
        return _buildSearchInfo(state);
    }
  }

  Widget _buildProgressForState(ProposalSearchState state) {
    return _getProgressForState(state);
  }

  Widget _getProgressForState(ProposalSearchState state) {
    switch (state.modalState) {
      case ProposalModalState.searching:
        return _buildProgressIndicator();
      case ProposalModalState.matched:
        return const SizedBox.shrink(); // Sem progress no match (Figma)
      case ProposalModalState.completed:
        return const SizedBox.shrink(); // Sem progress no completed
      case ProposalModalState.cancelled:
        return const SizedBox.shrink(); // Sem progress no cancelled
      case ProposalModalState.confirming_cancel:
        return const SizedBox.shrink(); // Sem progress na confirmação
      case ProposalModalState.confirming_cancel_session:
        return const SizedBox.shrink(); // Sem progress na confirmação de cancelamento de aula
      case ProposalModalState.initial:
        return _buildProgressIndicator();
    }
  }

  Widget _buildTimerForState(ProposalSearchState state) {
    return _getTimerForState(state);
  }

  Widget _getTimerForState(ProposalSearchState state) {
    switch (state.modalState) {
      case ProposalModalState.searching:
        return _buildEnhancedTimer();
      case ProposalModalState.matched:
        return const SizedBox.shrink(); // Sem timer no match (Figma)
      case ProposalModalState.completed:
        return const SizedBox.shrink(); // Sem timer no completed
      case ProposalModalState.cancelled:
        return const SizedBox.shrink(); // Sem timer no cancelled
      case ProposalModalState.confirming_cancel:
        return const SizedBox.shrink(); // Sem timer na confirmação
      case ProposalModalState.confirming_cancel_session:
        return const SizedBox.shrink(); // Sem timer na confirmação de cancelamento de aula
      case ProposalModalState.initial:
        return _buildEnhancedTimer();
    }
  }

  Widget _buildActionButtonForState(ProposalSearchState state) {
    return _getActionButtonForState(state);
  }

  Widget _getActionButtonForState(ProposalSearchState state) {
    switch (state.modalState) {
      case ProposalModalState.searching:
        return _buildActionButtons();
      case ProposalModalState.matched:
        return const SizedBox.shrink();
      case ProposalModalState.completed:
        return _buildContinueButton();
      case ProposalModalState.cancelled:
        return _buildTryAgainButton();
      case ProposalModalState.confirming_cancel:
        return _buildConfirmCancelButtons();
      case ProposalModalState.confirming_cancel_session:
        return _buildConfirmSessionCancelButtons();
      case ProposalModalState.initial:
        return _buildActionButtons();
    }
  }

  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.search, color: AppColors.primaryOrange, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Procurando personal',
            style: AppTextStyles.h6Semibold.copyWith(
              color: AppColors.secondary,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSearchAnimation() {
    return Container(
      height: 180, // ✅ Altura fixa para evitar crescimento da animação
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ondas concêntricas animadas
          AnimatedBuilder(
            animation: _rippleAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: List.generate(3, (index) {
                  final delay = index * 0.3;
                  final animationValue = (_rippleAnimation.value - delay).clamp(
                    0.0,
                    1.0,
                  );

                  return Container(
                    width: 80 + (animationValue * 120),
                    height: 80 + (animationValue * 120),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryOrange.withOpacity(
                          0.3 * (1 - animationValue),
                        ),
                        width: 2,
                      ),
                    ),
                  );
                }),
              );
            },
          ),

          // Círculo de fundo com gradiente
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryOrange.withOpacity(0.2),
                        AppColors.primaryOrange.withOpacity(0.1),
                        AppColors.primaryOrange.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Ícone da lupa com rotação suave e oscilação
          AnimatedBuilder(
            animation: _searchAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: math.sin(_searchAnimation.value * 2 * math.pi) * 0.3,
                child: Transform.scale(
                  scale:
                      1.0 +
                      math.sin(_searchAnimation.value * 4 * math.pi) * 0.1,
                  child: Icon(
                    Icons.search,
                    size: 40,
                    color: AppColors.primaryOrange,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInfo(ProposalSearchState state) {
        // Extrair informações do estado se disponível
        String location = widget.location;
        String? trainingInfo;

        if (state is ProposalSearchActive) {
          location = state.location;
          if (state.trainingDate != null || state.trainingTime != null) {
            final date = _formatTrainingDate(state.trainingDate);
            final time = _formatTrainingTime(state.trainingTime);
            trainingInfo = 'Data: $date • Horário: $time';
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Texto principal de busca
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.paragraph.copyWith(
                    color: const Color(0xFF42464D),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Procurando personal disponível próximo da ',
                    ),
                    TextSpan(
                      text: location,
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),

              // Informações de data e horário se disponível
              if (trainingInfo != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trainingInfo,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
    );
  }

  Widget _buildProgressIndicator() {
    return BlocBuilder<ProposalSearchBloc, ProposalSearchState>(
      builder: (context, state) {
        Duration currentDuration = widget.currentDuration ?? Duration.zero;
        if (state is ProposalSearchActive) {
          currentDuration = state.elapsedTime;
        }

        final progress = math.min(
          currentDuration.inSeconds / 180.0,
          1.0,
        ); // Progresso máximo em 3 minutos (180 segundos)

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(top: 16),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryOrange,
                ),
                minHeight: 6,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedTimer() {
    return BlocBuilder<ProposalSearchBloc, ProposalSearchState>(
      builder: (context, state) {
        Duration currentDuration = widget.currentDuration ?? Duration.zero;
        if (state is ProposalSearchActive) {
          currentDuration = state.elapsedTime;
        }

        final minutes = currentDuration.inMinutes;
        final seconds = currentDuration.inSeconds % 60;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule_rounded, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.paragraph.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: 'Tempo: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text:
                          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchAnimation() {
    return const SizedBox.shrink(); // Ícone agora está no título
  }

  Widget _buildSuccessAnimation() {
    return Container(
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 50),
        ),
      ),
    );
  }

  Widget _buildCancelledAnimation() {
    return Container(
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 50),
        ),
      ),
    );
  }

  // _buildMatchTitle removido (layout integrado no corpo igual ao MatchModal)

  Widget _buildMatchInfo(ProposalSearchMatched state) {
    // ✅ ESTRATÉGIA UBER: Não fazer enrichment interno - dados já vêm completos do RealtimeDataService
    final pid = (widget.proposalId != null && widget.proposalId!.isNotEmpty)
        ? widget.proposalId!
        : (state.proposalId ?? '');
    
    print('🚗 [PROPOSAL_STATUS_MODAL] Estratégia Uber: _buildMatchInfo chamado | proposalId=$pid');
    print('🚗 [PROPOSAL_STATUS_MODAL] Dados do estado (já completos): personalName=${state.personalName} | personalPhoto=${state.personalPhoto} | personalRating=${state.personalRating}');
    print('🚗 [PROPOSAL_STATUS_MODAL] Dados enriquecidos: _enrichedPersonalName=$_enrichedPersonalName | _enrichedPersonalPhoto=$_enrichedPersonalPhoto | _enrichedPersonalRating=$_enrichedPersonalRating');
    
    // ✅ CORREÇÃO: Só fazer enrichment UMA VEZ por proposalId e apenas se realmente necessário
    if (pid.isNotEmpty && 
        !_isFetchingEnrichment && 
        _enrichedForProposalId != pid &&
        _enrichedPersonalName == null && // ✅ Só fazer se ainda não temos dados enriquecidos
        (state.personalName == 'Personal Trainer' || state.personalName == 'Personal' || state.personalPhoto.isEmpty)) {
      final schedulePid = pid;
      print('⚠️ [PROPOSAL_STATUS_MODAL] Dados do estado estão vazios, fazendo enrichment de segurança para proposalId=$schedulePid');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_enrichedForProposalId == schedulePid) return;
        _enrichedForProposalId = schedulePid;
        _enrichmentAttempts = 0;
        print('🚀 [PROPOSAL_STATUS_MODAL] Disparando _fetchAndEnrichMatchData de segurança para proposalId=$schedulePid');
        _fetchAndEnrichMatchData(state);
      });
    } else {
      print('✅ [PROPOSAL_STATUS_MODAL] Estratégia Uber: Dados já estão completos ou enrichment já foi feito, sem necessidade de enrichment');
    }
    
    // DEBUG: Log dos dados do ProposalSearchBloc (igual ao proposal_modal.dart)
    print('🔍 [PROPOSAL_STATUS_MODAL] _buildMatchInfo - Dados do ProposalSearchBloc:');
    print('🔍 [PROPOSAL_STATUS_MODAL] state.personalName: ${state.personalName}');
    print('🔍 [PROPOSAL_STATUS_MODAL] state.personalPhoto: ${state.personalPhoto}');
    print('🔍 [PROPOSAL_STATUS_MODAL] state.personalRating: ${state.personalRating}');
    print('🔍 [PROPOSAL_STATUS_MODAL] state.personalResponseTime: ${state.personalResponseTime}');
    print('🔍 [PROPOSAL_STATUS_MODAL] _enrichedPersonalName: $_enrichedPersonalName');
    print('🔍 [PROPOSAL_STATUS_MODAL] _enrichedPersonalPhoto: $_enrichedPersonalPhoto');
    print('🔍 [PROPOSAL_STATUS_MODAL] _enrichedPersonalRating: $_enrichedPersonalRating');
    print('🔍 [PROPOSAL_STATUS_MODAL] _enrichedPersonalTimeOnPlatform: $_enrichedPersonalTimeOnPlatform');
    
    // Layout EXATAMENTE igual ao MatchModal do personal
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            // Header com ícone de handshake - EXATO do MatchModal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                      const Icon(
                        Icons.handshake,
                        size: 29,
              color: AppColors.primaryOrange,
          ),
          const SizedBox(width: 8),
                      const Text(
            'Match confirmado!',
                        style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
                          color: Color(0xFF42464D),
                          fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
                  const SizedBox(height: 8),
                  const Text(
            'Você foi conectado a um personal disponível para o seu treino.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
              fontSize: 16,
                      color: Color(0xFF2D3748),
                      fontFamily: 'Fira Sans',
              height: 1.3,
            ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Divisor - EXATO do MatchModal
          Container(
            height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 24),
            color: const Color(0xFFA6A6A6),
          ),

          const SizedBox(height: 16),

            // Informações do personal - EXATO do MatchModal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
                  // Foto e dados básicos - EXATO do MatchModal
          Row(
            children: [
                      // Foto do personal - EXATO do MatchModal
              GestureDetector(
                onTap: () {
                  // ✅ ESTRATÉGIA UBER: Prioridade: dados enriquecidos > estado WS (dados completos)
                  final photoUrl = (_enrichedPersonalPhoto?.isNotEmpty == true ? _enrichedPersonalPhoto! : 
                                   (state.personalPhoto.isNotEmpty ? state.personalPhoto : ''));
                  if (photoUrl.isNotEmpty) {
                    ImageViewerModal.show(
                      context,
                      imageUrl: photoUrl,
                      title: (_enrichedPersonalName?.isNotEmpty == true ? _enrichedPersonalName! : 
                              (state.personalName.isNotEmpty && state.personalName != 'Personal Trainer' && state.personalName != 'Personal' 
                               ? state.personalName 
                               : 'Personal Trainer')),
                      subtitle: 'Personal Trainer',
                    );
                  }
                },
                child: Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                            color: Colors.grey[300],
                  shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryOrange,
                              width: 3,
                            ),
                            image: ((_enrichedPersonalPhoto?.isNotEmpty == true ? _enrichedPersonalPhoto! : 
                                     (state.personalPhoto.isNotEmpty ? state.personalPhoto : ''))).isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(
                                      (_enrichedPersonalPhoto?.isNotEmpty == true ? _enrichedPersonalPhoto! : 
                                       (state.personalPhoto.isNotEmpty ? state.personalPhoto : '')),
                                    ),
                          fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: ((_enrichedPersonalPhoto?.isNotEmpty == true ? _enrichedPersonalPhoto! : 
                                   (state.personalPhoto.isNotEmpty ? state.personalPhoto : ''))).isEmpty
                              ? const Icon(
                                Icons.person,
                                size: 24,
                                  color: Colors.grey,
                                )
                              : null,
                ),
              ),
              const SizedBox(width: 12),
                      // Nome e avaliação - EXATO do MatchModal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                              (_enrichedPersonalName?.isNotEmpty == true ? _enrichedPersonalName! : 
                               (state.personalName.isNotEmpty && state.personalName != 'Personal Trainer' && state.personalName != 'Personal' 
                                ? state.personalName 
                                : 'Personal Trainer')),
                              style: const TextStyle(
                        fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3748),
                                fontFamily: 'Fira Sans',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                                const Icon(
                                  Icons.star,
                                  size: 22,
                                  color: AppColors.primaryOrange,
                                ),
                        const SizedBox(width: 4),
                        Text(
                                  ((_enrichedPersonalRating != null && _enrichedPersonalRating! > 0.0) ? _enrichedPersonalRating! : 
                                   (state.personalRating > 0.0 ? state.personalRating : 0.0)).toString(),
                                  style: const TextStyle(
                            fontSize: 16,
                                    color: Color(0xFF2D3748),
                                    fontFamily: 'Fira Sans',
                          ),
                        ),
                                const SizedBox(width: 8),
                                const Text(
                          '|',
                                  style: TextStyle(
                            fontSize: 16,
                                    color: Color(0xFF2D3748),
                                    fontFamily: 'Fira Sans',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  (_enrichedPersonalTimeOnPlatform?.isNotEmpty == true ? _enrichedPersonalTimeOnPlatform! : 
                                   (state.personalResponseTime.isNotEmpty && state.personalResponseTime != 'Rápido' 
                                    ? state.personalResponseTime 
                                    : 'Rápido')),
                                  style: const TextStyle(
                              fontSize: 16,
                                    color: Color(0xFF2D3748),
                                    fontFamily: 'Fira Sans',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

                  // Local - EXATO do ProposalModal do personal
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(width: 6),
            Text(
                              'Local',
                              style: TextStyle(
                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
          ),
        ],
      ),
                        const SizedBox(height: 2),
                        Padding( 
                         padding: const EdgeInsets.only(left: 3), // Alinhar com a borda esquerda do ícone
                          child: Text(
                            state.location.isNotEmpty
                                ? state.location
                                : (_enrichedLocation ?? 'Localização'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
          ),
        ],
      ),
                  ),

                  const SizedBox(height: 12),

                  // Data, Horário e Modalidade (uma linha) - EXATO do ProposalModal do personal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event,
                                size: 16,
            color: AppColors.primaryOrange,
                              ),
                              const SizedBox(width: 6),
              Text(
                                'Data',
                                style: TextStyle(
                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                ),
                              ),
                            ],
              ),
              const SizedBox(height: 2),
              Text(
                            _enrichedDate ?? _formatTrainingDate(state.trainingDate),
                            style: const TextStyle(
                        fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937),
                      ),
                            textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
            ],
          ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: AppColors.primaryOrange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Horário',
                                style: TextStyle(
          fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
          ),
        ),
      ],
              ),
              const SizedBox(height: 2),
                          Text(
                            _enrichedTime ?? _formatTrainingTime(state.trainingTime),
                            style: const TextStyle(
                        fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937),
                      ),
                            textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
            ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                              Icon(
                                Icons.fitness_center,
                                size: 16,
                                color: AppColors.primaryOrange,
                              ),
                              const SizedBox(width: 6),
                      Text(
                                'Modalidade',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                          const SizedBox(height: 2),
                          Text(
                            (state as ProposalSearchMatched?)?.modality ?? 
                            _enrichedModality ?? 'Personal Training',
                            style: const TextStyle(
          fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937),
        ),
                            textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
              ),

                  const SizedBox(height: 16),

                  // Botão Chat - EXATO do MatchModal
              SizedBox(
                width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleChatPressed(state),
                      icon: const Icon(
                        Icons.chat,
                        size: 16,
                        color: AppColors.primaryOrange,
                      ),
                      label: const Text(
                        'Chat',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryOrange,
                          fontFamily: 'Fira Sans',
                        ),
                      ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 40,
                    ),
                        side: const BorderSide(
                          color: AppColors.primaryOrange,
                          width: 2,
                        ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                        ),
                      ),
                    ],
                  ),
                ),

            const SizedBox(height: 24),

            // Divisor - EXATO do MatchModal
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              color: const Color(0xFFA6A6A6),
            ),

            const SizedBox(height: 24),

            // ✅ NOVO: Card de Atenção para o Aluno
            _buildAttentionCard(),
          ],
        ),
      );
  }

  /// Card de atenção com layout escuro (replicado do MatchModal do personal)
  Widget _buildAttentionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning,
                size: 21,
                color: Color(0xFFF9F9F9),
              ),
              const SizedBox(width: 8),
              const Text(
                'Atenção',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF9F9F9),
                  fontFamily: 'Fira Sans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Esta aula é individual e não pode ser compartilhada. O treino com amigo será liberado futuramente, conforme seu nível no app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFF9F9F9),
                fontFamily: 'Fira Sans',
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAndEnrichMatchData(ProposalSearchMatched state) async {
    final proposalId = (widget.proposalId != null && widget.proposalId!.isNotEmpty)
        ? widget.proposalId!
        : (state.proposalId ?? '');
    if (proposalId.isEmpty) return;
    if (_isFetchingEnrichment) return;
    print('🔎 [PROPOSAL_MODAL] Iniciando enrichment | proposalId=$proposalId | tentativa=$_enrichmentAttempts');
    setState(() {
      _isFetchingEnrichment = true;
    });
    try {
      final classesApi = sl<ClassesApiService>();
      final cls = await classesApi.getClassByProposalId(proposalId);
      if (!mounted) return;
      if (cls != null) {
        print('✅ [PROPOSAL_MODAL] Classe encontrada para proposalId=$proposalId | classId=${cls.id} | personalId=${cls.personalId}');
        print('✅ [PROPOSAL_MODAL] Dados do personal: name=${cls.personalName} | photo=${cls.personalProfileImageUrl} | rating=${cls.personalRating} | timeOnPlatform=${cls.personalTimeOnPlatform}');
        print('✅ [PROPOSAL_MODAL] Modalidade da proposta: ${cls.proposalModality}');
        
        // Primeiro, tentar obter dados completos do personal via UsersApiService
        String enrichedPersonalName = cls.personalName;
        String? enrichedPersonalPhoto = cls.personalProfileImageUrl;
        double? enrichedPersonalRating = cls.personalRating;
        String? enrichedPersonalTimeOnPlatform = cls.personalTimeOnPlatform;
        
        try {
          final usersApi = sl<UsersApiService>();
          final personalInfo = await usersApi.getUserBasicInfo(cls.personalId);
          if (!mounted) return;
          print('ℹ️ [PROPOSAL_MODAL] Complementando com UsersApiService para personalId=${cls.personalId}');
          
          final firstName = (personalInfo['firstName'] ?? '').toString();
          final lastName = (personalInfo['lastName'] ?? '').toString();
          final fullName = ('$firstName $lastName').trim();
          if (fullName.isNotEmpty) enrichedPersonalName = fullName;
          
          final photo = (personalInfo['profileImageUrl'] ?? '').toString();
          if (photo.isNotEmpty) enrichedPersonalPhoto = photo;
          
          final rating = double.tryParse((personalInfo['rating'] ?? '0.0').toString());
          if (rating != null && rating > 0.0) enrichedPersonalRating = rating;
          
          final timeOnPlatform = (personalInfo['timeOnPlatform'] ?? '').toString();
          if (timeOnPlatform.isNotEmpty) enrichedPersonalTimeOnPlatform = timeOnPlatform;
          
          print('✅ [PROPOSAL_MODAL] Dados enriquecidos: name=$enrichedPersonalName | photo=$enrichedPersonalPhoto | rating=$enrichedPersonalRating | timeOnPlatform=$enrichedPersonalTimeOnPlatform');
        } catch (e) {
          print('⚠️ [PROPOSAL_MODAL] Erro ao enriquecer dados do personal: $e');
        }
        
        setState(() {
          _enrichedClassId = cls.id;
          _enrichedReceiverId = cls.personalId; // aluno fala com personal
          _enrichedPersonalName = enrichedPersonalName.isNotEmpty ? enrichedPersonalName : state.personalName;
          _enrichedPersonalPhoto = enrichedPersonalPhoto ?? state.personalPhoto;
          _enrichedPersonalRating = enrichedPersonalRating ?? state.personalRating;
          _enrichedPersonalTimeOnPlatform = enrichedPersonalTimeOnPlatform ?? state.personalResponseTime;
          _enrichedLocation = cls.location;
          _enrichedDate = _formatTrainingDate(cls.date);
          _enrichedTime = cls.time;
          _enrichedDuration = '${cls.duration}min';
          _enrichedModality = cls.proposalModality;
        });
        
        // Se não havia classId no estado matched, atualiza-o via evento
        if (state.classId == null || state.classId!.isEmpty) {
          try {
            context.read<ProposalSearchBloc>().add(UpdateClassId(classId: cls.id));
          } catch (_) {}
        }
      } else {
        print('⏳ [PROPOSAL_MODAL] Classe ainda não disponível para proposalId=$proposalId (tentativa=$_enrichmentAttempts)');
        // Tenta novamente algumas vezes para aguardar a consistência da API
        if (_enrichmentAttempts < 5) {
          _enrichmentAttempts += 1;
          await Future.delayed(const Duration(milliseconds: 700));
          _isFetchingEnrichment = false;
          if (mounted) return _fetchAndEnrichMatchData(state);
        }
      }
    } catch (e) {
      print('❌ [PROPOSAL_MODAL] Erro no enrichment: $e');
      // Silencioso: se falhar, mantém dados atuais
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingEnrichment = false;
        });
      }
    }
  }

  void _handleChatPressed(ProposalSearchMatched state) async {
    print('💬 [PROPOSAL_MODAL] Botão Chat pressionado');
    
    final classId = _enrichedClassId ?? state.classId;
    String receiverId = _enrichedReceiverId ?? '';
    
    print('💬 [PROPOSAL_MODAL] classId: $classId, receiverId: $receiverId');
    
    if (classId == null || classId.isEmpty) {
      print('❌ [PROPOSAL_MODAL] classId não disponível, tentando enriquecer...');
      await _fetchAndEnrichMatchData(state);
      
      if (_enrichedClassId == null || _enrichedClassId!.isEmpty) {
        print('❌ [PROPOSAL_MODAL] Ainda não há classId disponível');
        // Mostrar snackbar de erro
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aula ainda não está disponível. Tente novamente em alguns segundos.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }
    
    // Garantir receiverId válido (UUID) antes de navegar
    if (receiverId.isEmpty) {
      try {
        print('🔎 [PROPOSAL_MODAL] receiverId vazio, buscando dados da aula por classId...');
        final classesApi = sl<ClassesApiService>();
        final cls = await classesApi.getClassById(classId ?? _enrichedClassId!);
        // Como este modal é do aluno, o destinatário é o personal
        receiverId = cls.personalId;
        _enrichedReceiverId = receiverId; // cache local
        print('✅ [PROPOSAL_MODAL] receiverId obtido via classId: $receiverId');
      } catch (e) {
        print('❌ [PROPOSAL_MODAL] Falha ao obter receiverId por classId: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível iniciar o chat agora. Tente novamente.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }
  
    print('✅ [PROPOSAL_MODAL] Navegando para ChatPage...');
    
    // Fechar modal em background e navegar imediatamente
    if (widget.onClose != null) {
      widget.onClose!();
    }
    
    // Navegar para ChatPage em background
    if (mounted) {
      try {
        await Future.microtask(() {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatPage(
                classId: classId ?? _enrichedClassId!,
                receiverId: receiverId,
                receiverName: state.personalName.isNotEmpty
                    ? state.personalName
                    : (_enrichedPersonalName ?? 'Personal Trainer'),
                location: state.location.isNotEmpty
                    ? state.location
                    : (_enrichedLocation ?? 'Localização'),
                date: _enrichedDate ?? _formatTrainingDate(state.trainingDate),
                time: _enrichedTime ?? _formatTrainingTime(state.trainingTime),
                duration: _enrichedDuration ?? '60min',
                currentUserIsStudent: true,
              ),
            ),
          );
        });
        print('✅ [PROPOSAL_MODAL] ChatPage aberta com sucesso');
      } catch (e) {
        print('❌ [PROPOSAL_MODAL] Erro ao navegar para ChatPage: $e');
      }
    }
  }





  // _buildMatchButton removido (no MatchModal original não há botão de ação aqui)

  Widget _buildSuccessTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        'Sessão Confirmada!',
        style: AppTextStyles.h6Semibold.copyWith(
          color: AppColors.secondary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSessionInfo(ProposalSearchCompleted state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            'Sua sessão foi confirmada com sucesso!',
            style: AppTextStyles.paragraph.copyWith(
              color: AppColors.secondaryDark,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Local: ${state.location}',
            style: AppTextStyles.paragraph.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tempo de busca: ${_formatDuration(state.totalTime)}',
            style: AppTextStyles.small.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        'Busca cancelada',
        style: AppTextStyles.h6Semibold.copyWith(
          color: AppColors.secondary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCancelledMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        'A busca por personal foi cancelada. Você pode tentar novamente quando quiser.',
        style: AppTextStyles.paragraph.copyWith(
          color: AppColors.secondaryDark,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTryAgainButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Fechar modal
            if (widget.onClose != null) {
              widget.onClose!();
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primaryOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Tentar novamente',
            style: AppTextStyles.paragraph.copyWith(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Fechar modal
            if (widget.onClose != null) {
              widget.onClose!();
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primaryOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Continuar',
            style: AppTextStyles.paragraph.copyWith(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            context.read<ProposalSearchBloc>().add(
              const ShowCancelConfirmation(),
            );
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: AppColors.primaryOrange, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Cancelar busca',
            style: AppTextStyles.paragraph.copyWith(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// Animação para confirmação de cancelamento
  Widget _buildConfirmCancelAnimation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
      ),
    );
  }

  /// Título para confirmação de cancelamento
  Widget _buildConfirmCancelTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Cancelar proposta',
        style: AppTextStyles.h6Semibold.copyWith(
          color: AppColors.secondary,
          fontSize: 22,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Informações para confirmação de cancelamento
  Widget _buildConfirmCancelInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        'Você tem certeza que deseja cancelar a proposta? Um profissional pode aceitar sua solicitação a qualquer momento.',
        style: AppTextStyles.paragraph.copyWith(
          color: AppColors.secondaryDark,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Botões para confirmação de cancelamento
  Widget _buildConfirmCancelButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(top: 16),
      child: Column(
        children: [
          // Botão "Continuar buscando"
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.read<ProposalSearchBloc>().add(
                  const BackFromCancelConfirmation(),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.primaryOrange, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continuar buscando',
                style: AppTextStyles.paragraph.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botão "Sim, cancelar"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                print('🔴 [PROPOSAL_MODAL] Botão "Sim, cancelar" pressionado');
                context.read<ProposalSearchBloc>().add(
                  const CancelProposalSearch(),
                );
                print('🔴 [PROPOSAL_MODAL] Evento CancelProposalSearch enviado');
                if (widget.onClose != null) {
                  print('🔴 [PROPOSAL_MODAL] Chamando onClose callback');
                  widget.onClose!();
                } else {
                  print('⚠️ [PROPOSAL_MODAL] onClose callback é null');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sim, Cancelar',
                style: AppTextStyles.paragraph.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Animação para confirmação de cancelamento de aula
  Widget _buildConfirmSessionCancelAnimation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
      ),
    );
  }

  /// Título para confirmação de cancelamento de aula
  Widget _buildConfirmSessionCancelTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Cancelar aula',
        style: AppTextStyles.h6Semibold.copyWith(
          color: AppColors.secondary,
          fontSize: 22,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Informações para confirmação de cancelamento de aula
  Widget _buildConfirmSessionCancelInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        'Você tem certeza que deseja cancelar a aula confirmada com o profissional? Esta ação não poderá ser desfeita.',
        style: AppTextStyles.paragraph.copyWith(
          color: AppColors.secondaryDark,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Botões para confirmação de cancelamento de aula
  Widget _buildConfirmSessionCancelButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(top: 16),
      child: Column(
        children: [
          // Botão "Manter aula"
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.read<ProposalSearchBloc>().add(
                  const BackFromSessionCancelConfirmation(),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.primaryOrange, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Manter aula',
                style: AppTextStyles.paragraph.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botão "Sim, cancelar aula"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<ProposalSearchBloc>().add(const CancelSession());
                if (widget.onClose != null) {
                  widget.onClose!();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sim, Cancelar Aula',
                style: AppTextStyles.paragraph.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Função helper para mostrar o modal
void showProposalStatusModal(
  BuildContext context, {
  required String location,
  VoidCallback? onClose,
  ProposalSearchBloc? proposalSearchBloc,
  String? proposalId,
  bool autoCloseOnMatched = false,
}) {
  // Capturar o Bloc do contexto atual antes de criar o Overlay
  final bloc = proposalSearchBloc ?? context.read<ProposalSearchBloc>();

  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (context) => Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Blur background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
          // Modal content
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: BlocProvider.value(
                value: bloc,
                child: ProposalStatusModal(
                  location: location,
                  onClose: () {
                    Navigator.of(context).pop();
      if (onClose != null) {
        onClose();
                    }
                  },
                proposalId: proposalId,
                autoCloseOnMatched: autoCloseOnMatched,
          ),
        ),
            ),
          ),
        ],
      ),
    ),
  );
}
