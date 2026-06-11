import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/home_state.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';
import '../bloc/home_event.dart';
import '../../../proposals/presentation/widgets/proposal_status_modal.dart';
import '../../../proposals/presentation/bloc/proposal_search_bloc.dart'
    as proposal_search;
import '../../../../core/di/dependency_injection.dart';
import '../../../classes/data/services/classes_api_service.dart';
import '../../../classes/data/models/class_timeline_dto.dart';

/// Widget dinâmico que gerencia todos os estados do card de treinos
class DynamicWorkoutCard extends StatefulWidget {
  const DynamicWorkoutCard({super.key});

  @override
  State<DynamicWorkoutCard> createState() => _DynamicWorkoutCardState();
}

class _DynamicWorkoutCardState extends State<DynamicWorkoutCard>
    with TickerProviderStateMixin {
  late AnimationController _searchAnimationController;
  // Removido pulse: manter apenas animação da lupa andando
  Timer? _cancelAvailabilityTimer;
  DateTime? _scheduledDeadlineForAutoHide;
  ClassTimelineDto? _classTimeline;
  Timer? _timelineRefreshTimer;
  String? _timelineClassId;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Controla a animação de "piscando lentamente" (scale suave)
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat();
  }

  void _scheduleAutoHideCancelButtonIfNeeded(ClassTimelineDto? timeline) {
    _cancelAvailabilityTimer?.cancel();
    _cancelAvailabilityTimer = null;
    _scheduledDeadlineForAutoHide = null;

    if (timeline?.cancellationDeadline == null) return;

    final hideAt = DateTime.tryParse(timeline!.cancellationDeadline!);
    if (hideAt == null) return;

    if (_scheduledDeadlineForAutoHide == hideAt) return;
    _scheduledDeadlineForAutoHide = hideAt;

    final wait = hideAt.difference(DateTime.now());
    if (wait.isNegative) {
      if (mounted) setState(() {});
      return;
    }

    _cancelAvailabilityTimer = Timer(wait, () {
      if (mounted) setState(() {});
    });
  }

  /// SSOT: timeline da aula via GET /classes/:id/timeline
  Future<void> _loadClassTimeline(String classId) async {
    if (_timelineClassId == classId && _classTimeline != null) return;

    try {
      final timeline = await sl<ClassesApiService>().getClassTimeline(classId);
      if (!mounted) return;
      setState(() {
        _classTimeline = timeline;
        _timelineClassId = classId;
      });
      _scheduleAutoHideCancelButtonIfNeeded(timeline);
    } catch (e) {
      print('⚠️ [DYNAMIC_WORKOUT_CARD] Falha ao carregar timeline: $e');
    }
  }

  void _startTimelineRefresh(String classId) {
    _timelineRefreshTimer?.cancel();
    _timelineRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _timelineClassId = null;
      _loadClassTimeline(classId);
    });
  }

  bool _canCancelFromTimeline() => _classTimeline?.canCancel ?? false;

  String _cancelUnavailableMessage() {
    final hours = _classTimeline?.cancellationWindowHours;
    if (hours != null) {
      final label = hours == hours.roundToDouble()
          ? '${hours.toInt()}h'
          : '${hours}h';
      return 'Cancelamento indisponível — prazo mínimo de $label antes da aula.';
    }
    return 'Cancelamento indisponível — prazo mínimo antes da aula já expirou.';
  }

  @override
  Widget build(BuildContext context) {
    print('🎯 [DYNAMIC_WORKOUT_CARD] ===== BUILD CHAMADO =====');
    
    // Verificar qual HomeBloc está sendo usado
    try {
      final homeBloc = context.read<HomeBloc>();
      print('🎯 [DYNAMIC_WORKOUT_CARD] HomeBloc no contexto: ${homeBloc.hashCode}');
      print('🎯 [DYNAMIC_WORKOUT_CARD] HomeBloc isClosed: ${homeBloc.isClosed}');
    } catch (e) {
      print('❌ [DYNAMIC_WORKOUT_CARD] Erro ao ler HomeBloc: $e');
    }
    
    return BlocBuilder<HomeBloc, HomeBlocState>(
      buildWhen: (previous, current) {
        print('🎯 [DYNAMIC_WORKOUT_CARD] buildWhen chamado');
        print('🎯 [DYNAMIC_WORKOUT_CARD] Previous: ${previous.runtimeType}');
        print('🎯 [DYNAMIC_WORKOUT_CARD] Current: ${current.runtimeType}');
        
        if (previous is HomeLoaded && current is HomeLoaded) {
          final prevState = previous.homeState.workoutCardState;
          final currState = current.homeState.workoutCardState;
          print('🎯 [DYNAMIC_WORKOUT_CARD] Previous workoutCardState: $prevState');
          print('🎯 [DYNAMIC_WORKOUT_CARD] Current workoutCardState: $currState');
          print('🎯 [DYNAMIC_WORKOUT_CARD] Deve reconstruir: ${prevState != currState || previous.homeState != current.homeState}');
        }
        
        return true; // Sempre reconstruir para debug
      },
      builder: (context, state) {
        print('🎯 [DYNAMIC_WORKOUT_CARD] BlocBuilder executado - Estado: ${state.runtimeType}');
        
        if (state is HomeLoaded) {
          final homeState = state.homeState;

          // DEBUG: Log detalhado do estado do card
          print('🎯 [DYNAMIC_WORKOUT_CARD] ===== BUILD DO CARD =====');
          print('🎯 [DYNAMIC_WORKOUT_CARD] Estado: ${homeState.workoutCardState}');
          print('🎯 [DYNAMIC_WORKOUT_CARD] workoutCardData: ${homeState.workoutCardData}');
          print('🎯 [DYNAMIC_WORKOUT_CARD] workoutCardDate: ${homeState.workoutCardDate}');
          print('🎯 [DYNAMIC_WORKOUT_CARD] workoutCardTime: ${homeState.workoutCardTime}');
          print('🎯 [DYNAMIC_WORKOUT_CARD] workoutCardLocation: ${homeState.workoutCardLocation}');
          
          // Se tiver dados, mostrar detalhes
          if (homeState.workoutCardData != null) {
            final data = homeState.workoutCardData!;
            print('🎯 [DYNAMIC_WORKOUT_CARD] === DADOS DO CARD ===');
            print('🎯 [DYNAMIC_WORKOUT_CARD] Keys disponíveis: ${data.keys.toList()}');
            print('🎯 [DYNAMIC_WORKOUT_CARD] id: ${data['id']}');
            print('🎯 [DYNAMIC_WORKOUT_CARD] status: ${data['status']}');
            print('🎯 [DYNAMIC_WORKOUT_CARD] proposalStatus: ${data['proposalStatus']}');
            print('🎯 [DYNAMIC_WORKOUT_CARD] classStatus: ${data['classStatus']}');
            print('🎯 [DYNAMIC_WORKOUT_CARD] personal: ${data['personal']}');
            print('🎯 [DYNAMIC_WORKOUT_CARD] personalName: ${data['personalName']}');
          }

          switch (homeState.workoutCardState) {
            case WorkoutCardState.searchingProfessional:
              print('🎯 [DYNAMIC_WORKOUT_CARD] Renderizando: SEARCHING CARD');
              return _buildSearchingCard(homeState);

            case WorkoutCardState.scheduledClass:
              print('🎯 [DYNAMIC_WORKOUT_CARD] Renderizando: SCHEDULED CLASS CARD');
              return _buildScheduledClassCard(homeState);

            case WorkoutCardState.pendingProposal:
              print('🎯 [DYNAMIC_WORKOUT_CARD] Renderizando: PENDING PROPOSAL CARD');
              return _buildPendingProposalCard(homeState);

            case WorkoutCardState.noWorkout:
              print('🎯 [DYNAMIC_WORKOUT_CARD] Renderizando: NO WORKOUT CARD');
              return _buildNoWorkoutCard();
          }
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Card de busca ativa (modal ativo) - Layout original do ProposalSearchCompactCard
  Widget _buildSearchingCard(HomeState homeState) {
    return GestureDetector(
      onTap: () => _showSearchModal(context, homeState),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, // Sempre branco como o original
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header com ícone animado e título
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lupa "piscando lentamente" (scale suave)
                AnimatedBuilder(
                  animation: _searchAnimationController,
                  builder: (context, child) {
                    final p = _searchAnimationController.value; // 0..1
                    final scale =
                        0.96 + 0.08 * (0.5 - 0.5 * math.cos(2 * math.pi * p));
                    return Transform.scale(
                      scale: scale,
                      child: const Icon(
                        Icons.search,
                        size: 26,
                        color: AppColors.primaryOrange,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),

                Text(
                  'Buscando Personal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2A2A2A),
                    height: 1.2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Descrição
            Text(
              'Buscando Personal disponível próximo da ${homeState.workoutCardLocation ?? 'localização'}',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF6B6B6B),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Timer para busca ativa
            _buildSearchTimer(),
          ],
        ),
      ),
    );
  }

  /// Timer de busca ativa
  Widget _buildSearchTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Aguarde...',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF42464D),
        ),
      ),
    );
  }

  /// Card de aula agendada - Layout original do ProposalSearchCompactCard
  Widget _buildScheduledClassCard(HomeState homeState) {
    final classData = homeState.workoutCardData ?? {};

    // Extrair dados do personal trainer
    final personal = classData['personal'] as Map<String, dynamic>? ?? {};
    final personalName =
        classData['personalName'] ??
        (personal['firstName'] != null && personal['lastName'] != null
            ? '${personal['firstName']} ${personal['lastName']}'
            : 'Nome não informado');
    final personalImage =
        classData['personalProfileImageUrl'] ??
        personal['profilePicture'] ??
        classData['personalImage'];
    final personalRating = classData['personalRating'] ?? 0.0;

    // DEBUG: Log dos dados extraídos
    print('🖼️ [DYNAMIC_WORKOUT_CARD] Dados do personal extraídos:');
    print('🖼️ [DYNAMIC_WORKOUT_CARD] personalName: $personalName');
    print('🖼️ [DYNAMIC_WORKOUT_CARD] personalImage: $personalImage');
    print('🖼️ [DYNAMIC_WORKOUT_CARD] personalRating: $personalRating');
    print('🖼️ [DYNAMIC_WORKOUT_CARD] personal object: $personal');
    print(
      '🖼️ [DYNAMIC_WORKOUT_CARD] classData keys: ${classData.keys.toList()}',
    );

    // SSOT: carregar timeline do backend para cancelamento e prazos
    final classId = classData['id']?.toString();
    if (classId != null && classId.isNotEmpty) {
      _loadClassTimeline(classId);
      _startTimelineRefresh(classId);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.5), // Borda verde para aula confirmada
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header com ícone do halter + "Próximo treino"
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                size: 29,
                color: AppColors.primaryOrange, // Cor laranja
              ),
              const SizedBox(width: 8),
              Text(
                'Próximo treino',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18, // Mesmo tamanho que "Missão da Semana"
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                  height: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Seção principal com dados do personal
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar do personal (lado esquerdo) com borda laranja
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: AppColors.primaryOrange, // Borda laranja
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    19,
                  ), // Ajustado para acomodar a borda
                  child: personalImage != null && personalImage.isNotEmpty
                      ? Image.network(
                          personalImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.person, color: Colors.grey[600]),
                        )
                      : Icon(Icons.person, color: Colors.grey[600]),
                ),
              ),

              const SizedBox(width: 12),

              // Nome, rating, horário e localização
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primeira linha: Nome + Horário
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Nome
                        Expanded(
                          child: Text(
                            personalName,
                            style: TextStyle(
                              fontFamily: 'Fira Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D3748),
                              height: 1.3,
                            ),
                          ),
                        ),
                        // Horário
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateTime(
                                homeState.workoutCardDate,
                                homeState.workoutCardTime,
                              ),
                              style: TextStyle(
                                fontFamily: 'Fira Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2D3748),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Segunda linha: Rating + Localização
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Rating
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16, // Mesmo tamanho que os outros ícones
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              personalRating.toString(),
                              style: TextStyle(
                                fontFamily: 'Fira Sans',
                                fontSize:
                                    12, // Mesmo tamanho que horário e localização
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2D3748),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                        // Localização
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                homeState.workoutCardLocation ??
                                    'Local não informado',
                                style: TextStyle(
                                  fontFamily: 'Fira Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF2D3748),
                                  height: 1.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Botão de cancelar aula (oculto se faltar menos de 2h)
          if (_canCancelFromTimeline())
            SizedBox(
              width: double.infinity, // 100% da largura
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () => _cancelClass(context, homeState),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Cancelar Aula',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          
          // Mensagem quando não pode mais cancelar
          if (!_canCancelFromTimeline())
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _cancelUnavailableMessage(),
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Card de proposta pendente - Layout âmbar
  Widget _buildPendingProposalCard(HomeState homeState) {
    final proposalData = homeState.workoutCardData ?? {};

    // Extrair dados da proposta
    final location =
        proposalData['locationName'] ??
        homeState.workoutCardLocation ??
        'Local não informado';
    final date = proposalData['trainingDate'] != null
        ? DateTime.parse(proposalData['trainingDate'])
        : homeState.workoutCardDate;
    final time =
        proposalData['trainingTime'] ??
        homeState.workoutCardTime ??
        'Horário não informado';
    final isRecontract = _isDirectRecontractProposal(proposalData);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header com ícone âmbar e título
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isRecontract ? Icons.person_pin : Icons.hourglass_empty,
                size: 24,
                color: Colors.amber[700],
              ),
              const SizedBox(width: 8),
              Text(
                isRecontract
                    ? 'Aguardando resposta do personal'
                    : 'Aguardando Match',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                  height: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Seção principal com dados da proposta
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar placeholder (lado esquerdo) com borda âmbar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: Colors.amber[400]!, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
                    color: Colors.amber[50],
                    child: Icon(
                      Icons.person_search,
                      color: Colors.amber[600],
                      size: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Informações da proposta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primeira linha: Status + Horário
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Status
                        Expanded(
                          child: Text(
                            'Proposta Pendente',
                            style: TextStyle(
                              fontFamily: 'Fira Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D3748),
                              height: 1.3,
                            ),
                          ),
                        ),
                        // Horário
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateTime(date, time),
                              style: TextStyle(
                                fontFamily: 'Fira Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF2D3748),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Segunda linha: Localização
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontFamily: 'Fira Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B6B6B),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status de espera (nova linha abaixo)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.amber[700]!,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  isRecontract
                      ? 'O personal receberá sua proposta de recontratação'
                      : 'Personais podem aceitar a qualquer momento',
                  style: TextStyle(
                    fontFamily: 'Fira Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.amber[600],
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Botão de cancelar
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _cancelProposal(context, homeState),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.red[300]!, width: 1),
                ),
                backgroundColor: Colors.red[50],
              ),
              child: Text(
                'Cancelar Proposta',
                style: TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card padrão "Sem treinos"
  Widget _buildNoWorkoutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Título com ícone ao lado
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                size: 22,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 8),
              Text(
                'Sem treinos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2A2A2A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Após criar e aprovar sua proposta, o seu próximo treino aparecerá aqui.',
            style: TextStyle(fontSize: 14, color: const Color(0xFF6B6B6B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Formatar data e hora para exibição
  String _formatDateTime(DateTime? date, String? time) {
    if (date == null) return 'Data não informada';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final trainingDay = DateTime(date.year, date.month, date.day);

    String dayText;
    if (trainingDay == today) {
      dayText = 'Hoje';
    } else if (trainingDay == tomorrow) {
      dayText = 'Amanhã';
    } else {
      dayText =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    }

    final timeText = time ?? '00:00';
    return '$dayText às $timeText';
  }

  void _showSearchModal(BuildContext context, HomeState homeState) {
    final searchBloc = context.read<proposal_search.ProposalSearchBloc>();
    final proposalId = homeState.workoutCardData?['id']?.toString();

    // Evita reutilizar tela de match de proposta/aula anterior.
    if (searchBloc.state is proposal_search.ProposalSearchMatched ||
        searchBloc.state is proposal_search.ProposalSearchConfirmingSessionCancel) {
      searchBloc.add(const proposal_search.ResetProposalSearch());
    }

    showProposalStatusModal(
      context,
      location: homeState.workoutCardLocation ?? 'Localização',
      onClose: () {},
      proposalSearchBloc: searchBloc,
      proposalId: proposalId,
    );
  }

  bool _isDirectRecontractProposal(Map<String, dynamic> proposalData) {
    final targetPersonalId =
        proposalData['targetPersonalId']?.toString().trim() ?? '';
    if (targetPersonalId.isNotEmpty) return true;
    return proposalData['isRecontract'] == true;
  }

  void _cancelProposal(BuildContext context, HomeState homeState) {
    final proposalData = homeState.workoutCardData;
    if (proposalData == null) return;

    final proposalId = proposalData['id'] as String?;
    if (proposalId == null) return;

    // Capturar blocs ANTES de abrir o dialog
    final homeBloc = context.read<HomeBloc>();
    final searchBloc = context.read<proposal_search.ProposalSearchBloc>();
    searchBloc.add(const proposal_search.ResetProposalSearch());

    // Mostrar diálogo de confirmação (mesmo estilo do cancelamento de aula)
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[600],
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Cancelar Proposta',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        content: Text(
          'Tem certeza que deseja cancelar esta proposta? Esta ação não pode ser desfeita.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Não',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _executeCancelProposal(context, proposalId, homeBloc);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Sim, cancelar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Executa o cancelamento da proposta
  void _executeCancelProposal(BuildContext context, String proposalId, HomeBloc homeBloc) {
    try {
      print('🗑️ [CANCEL_PROPOSAL] ===== INICIANDO CANCELAMENTO =====');
      print('🗑️ [CANCEL_PROPOSAL] ProposalId: $proposalId');
      print('🗑️ [CANCEL_PROPOSAL] HomeBloc recebido: ${homeBloc.hashCode}');
      print('🗑️ [CANCEL_PROPOSAL] HomeBloc isClosed: ${homeBloc.isClosed}');
      print('🗑️ [CANCEL_PROPOSAL] HomeBloc estado atual: ${homeBloc.state.runtimeType}');
      
      if (homeBloc.isClosed) {
        print('⚠️ [CANCEL_PROPOSAL] HomeBloc está fechado, não é possível cancelar');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao cancelar proposta. Por favor, tente novamente.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
        return;
      }

      // Disparar evento de cancelamento imediatamente
      print('🗑️ [CANCEL_PROPOSAL] Disparando evento ProposalCancelled...');
      try {
        context.read<proposal_search.ProposalSearchBloc>().add(
          const proposal_search.ResetProposalSearch(),
        );
      } catch (_) {}
      homeBloc.add(ProposalCancelled(proposalId: proposalId));
      print('🗑️ [CANCEL_PROPOSAL] Evento ProposalCancelled disparado com sucesso');

      // Mostrar feedback visual imediato
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Proposta cancelada com sucesso!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    } catch (e) {
      print('❌ [CANCEL_PROPOSAL] Erro ao cancelar proposta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao cancelar proposta. Por favor, tente novamente.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }
  }

  /// Cancela uma aula agendada
  void _cancelClass(BuildContext context, HomeState homeState) {
    final classData = homeState.workoutCardData;
    if (classData == null) return;

    final classId = classData['id'] as String?;
    if (classId == null) return;

    // Capturar o HomeBloc ANTES de abrir o dialog
    final homeBloc = context.read<HomeBloc>();
    print('🗑️ [CANCEL_CLASS_SETUP] HomeBloc capturado: ${homeBloc.hashCode}');

    // Mostrar diálogo de confirmação
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[600],
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Cancelar Aula',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        content: Text(
          'Tem certeza que deseja cancelar esta aula? Esta ação não pode ser desfeita.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100], // Background cinza claro
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Não',
                      style: TextStyle(
                        color: Colors.grey[700], // Texto cinza escuro
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12), // Espaçamento entre botões
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red, // Background vermelho
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _executeCancelClass(context, classId, homeBloc);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Sim',
                      style: TextStyle(
                        color: Colors.white, // Texto branco
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Executa o cancelamento da aula
  void _executeCancelClass(BuildContext context, String classId, HomeBloc homeBloc) {
    try {
      print('🗑️ [CANCEL_CLASS] ===== INICIANDO CANCELAMENTO =====');
      print('🗑️ [CANCEL_CLASS] ClassId: $classId');
      print('🗑️ [CANCEL_CLASS] HomeBloc recebido: ${homeBloc.hashCode}');
      print('🗑️ [CANCEL_CLASS] HomeBloc isClosed: ${homeBloc.isClosed}');
      print('🗑️ [CANCEL_CLASS] HomeBloc estado atual: ${homeBloc.state.runtimeType}');
      
      // Verificar se o BLoC ainda está ativo antes de adicionar evento
      if (homeBloc.isClosed) {
        print('⚠️ [CANCEL_CLASS] HomeBloc está fechado, não é possível cancelar');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao cancelar aula. Por favor, tente novamente.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
        return;
      }

      // Disparar evento de cancelamento imediatamente
      print('🗑️ [CANCEL_CLASS] Disparando evento ClassCancelled...');
      homeBloc.add(ClassCancelled(classId));
      print('🗑️ [CANCEL_CLASS] Evento ClassCancelled disparado com sucesso');

      // Mostrar feedback visual imediato
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aula cancelada com sucesso!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    } catch (e) {
      print('❌ [CANCEL_CLASS] Erro ao cancelar aula: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao cancelar aula. Por favor, tente novamente.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _cancelAvailabilityTimer?.cancel();
    _timelineRefreshTimer?.cancel();
    super.dispose();
  }
}
