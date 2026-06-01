import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/home_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../gamification/domain/entities/gamification_entity.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_state.dart';
import '../../../gamification/presentation/widgets/animated_xp_bar.dart';
import 'mission_card_settlement.dart';

/// Card da missão semanal — estabiliza antes de exibir, sem trocar título.
class WeeklyMissionCard extends StatefulWidget {
  final HomeState homeState;

  const WeeklyMissionCard({super.key, required this.homeState});

  @override
  State<WeeklyMissionCard> createState() => _WeeklyMissionCardState();
}

class _WeeklyMissionCardState extends State<WeeklyMissionCard> {
  _MissionDisplayData? _committedDisplay;
  late final MissionCardSettlement _settlement;

  @override
  void initState() {
    super.initState();
    _settlement = MissionCardSettlement(
      readBloc: () => context.read<GamificationBloc>(),
      onCommit: () {
        final missions = _settlement.extractMissions(
          context.read<GamificationBloc>().state,
        );
        if (missions != null) {
          _syncCommittedFromMissions(missions);
        }
        if (mounted) setState(() {});
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final missions = _settlement.extractMissions(
        context.read<GamificationBloc>().state,
      );
      if (missions != null) {
        _settlement.scheduleSettlement(missions);
      }
    });
  }

  @override
  void dispose() {
    _settlement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GamificationBloc, GamificationState>(
      listenWhen: (previous, current) =>
          current is GamificationLoaded ||
          current is GamificationMissionCompleted,
      listener: (context, state) {
        final missions = _settlement.extractMissions(state);
        if (missions == null) return;
        if (_settlement.hasCommitted) {
          _syncCommittedFromMissions(missions);
          if (mounted) setState(() {});
        } else {
          _settlement.scheduleSettlement(missions);
        }
      },
      child: BlocBuilder<GamificationBloc, GamificationState>(
        buildWhen: (previous, current) {
          if (_committedDisplay == null) {
            return current is GamificationLoaded ||
                current is GamificationMissionCompleted;
          }
          return _shouldRefreshCommittedDisplay(current);
        },
        builder: (context, gamificationState) {
          final missions = _settlement.extractMissions(gamificationState);
          if (missions != null) {
            if (_settlement.hasCommitted) {
              _syncCommittedFromMissions(missions);
            } else {
              _settlement.scheduleSettlement(missions);
            }
          }

          if (_committedDisplay != null) {
            return _buildMissionCard(_committedDisplay!);
          }

          if (gamificationState is GamificationLoading ||
              gamificationState is GamificationInitial) {
            return _buildLoadingCard();
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _syncCommittedFromMissions(List<UserMission> missions) {
    final lockedId = _settlement.lockedUserMissionId;
    if (lockedId != null) {
      final locked = MissionCardSettlement.findMissionById(missions, lockedId);
      if (locked != null) {
        _committedDisplay = _MissionDisplayData.fromMission(locked);

        if (locked.isCompleted) {
          final successor = MissionCardSettlement.selectActiveMission(
            missions,
            excludeUserMissionId: locked.id,
          );
          if (successor != null) {
            _settlement.lockedUserMissionId = successor.id;
            _committedDisplay = _MissionDisplayData.fromMission(successor);
          }
        }
        return;
      }
    }

    final pick = MissionCardSettlement.pickDisplayMission(missions);
    if (pick != null) {
      _settlement.lockedUserMissionId = pick.id;
      _committedDisplay = _MissionDisplayData.fromMission(pick);
    }
  }

  bool _shouldRefreshCommittedDisplay(GamificationState state) {
    final missions = _settlement.extractMissions(state);
    if (missions == null || _committedDisplay == null) return false;

    final locked = MissionCardSettlement.findMissionById(
      missions,
      _settlement.lockedUserMissionId,
    );
    if (locked == null) return true;

    final next = _MissionDisplayData.fromMission(locked);
    return next.progress != _committedDisplay!.progress ||
        next.isCompleted != _committedDisplay!.isCompleted ||
        next.progressText != _committedDisplay!.progressText;
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primaryOrange,
            AppColors.primaryOrangeLight,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Carregando missão...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(_MissionDisplayData missionData) {
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primaryOrange,
            AppColors.primaryOrangeLight,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                missionData.isCompleted
                    ? Icons.check_circle
                    : Icons.emoji_events,
                size: 20,
                color: Colors.white.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  missionData.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            missionData.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progresso',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                  ),
                  Text(
                    missionData.progressText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AnimatedXPBar(
                  key: ValueKey(missionData.missionId),
                  currentXP: missionData.progress,
                  maxXP: missionData.totalRequired,
                  height: 8,
                  trackColor: Colors.white.withValues(alpha: 0.35),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionDisplayData {
  final String missionId;
  final String title;
  final String description;
  final String progressText;
  final double progress;
  final double totalRequired;
  final bool isCompleted;

  const _MissionDisplayData({
    required this.missionId,
    required this.title,
    required this.description,
    required this.progressText,
    required this.progress,
    required this.totalRequired,
    required this.isCompleted,
  });

  factory _MissionDisplayData.fromMission(UserMission mission) {
    return _MissionDisplayData(
      missionId: mission.id,
      title: mission.mission.title,
      description: mission.mission.description,
      progressText: mission.isCompleted
          ? 'Completada! ${mission.progress}/${mission.totalRequired}'
          : '${mission.progress} de ${mission.totalRequired}',
      progress: mission.progress.toDouble(),
      totalRequired: mission.totalRequired.toDouble(),
      isCompleted: mission.isCompleted,
    );
  }
}
