import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/home_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../gamification/domain/entities/gamification_entity.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_state.dart';
import '../../../gamification/presentation/widgets/animated_xp_bar.dart';

/// Card da missão semanal — exibe só depois de estabilizar, sem trocar título.
class WeeklyMissionCard extends StatefulWidget {
  final HomeState homeState;

  const WeeklyMissionCard({super.key, required this.homeState});

  @override
  State<WeeklyMissionCard> createState() => _WeeklyMissionCardState();
}

class _WeeklyMissionCardState extends State<WeeklyMissionCard> {
  static const Duration _settleDelay = Duration(milliseconds: 1200);

  _MissionDisplayData? _committedDisplay;
  String? _lockedUserMissionId;
  Timer? _settleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final missions = _extractMissions(context.read<GamificationBloc>().state);
      if (missions != null) {
        _scheduleMissionSettlement(missions);
      }
    });
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GamificationBloc, GamificationState>(
      listenWhen: (previous, current) =>
          current is GamificationLoaded || current is GamificationMissionCompleted,
      listener: (context, state) {
        if (state is GamificationLoaded) {
          _scheduleMissionSettlement(state.userMissions);
        } else if (state is GamificationMissionCompleted) {
          _scheduleMissionSettlement(state.updatedMissions);
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
          final missions = _extractMissions(gamificationState);
          if (missions != null && _committedDisplay != null) {
            _tryCommitFromMissions(missions, allowNewLock: true);
          }

          if (_committedDisplay != null) {
            return _buildMissionCard(_committedDisplay!);
          }

          return _buildLoadingCard();
        },
      ),
    );
  }

  List<UserMission>? _extractMissions(GamificationState state) {
    if (state is GamificationLoaded) return state.userMissions;
    if (state is GamificationMissionCompleted) return state.updatedMissions;
    return null;
  }

  void _scheduleMissionSettlement(List<UserMission> missions) {
    _settleTimer?.cancel();

    if (_committedDisplay != null) {
      _tryCommitFromMissions(missions, allowNewLock: true);
      if (mounted) setState(() {});
      return;
    }

    _settleTimer = Timer(_settleDelay, () {
      if (!mounted) return;
      final latest =
          _extractMissions(context.read<GamificationBloc>().state) ?? missions;
      _tryCommitFromMissions(latest, allowNewLock: true);
      setState(() {});
    });
  }

  bool _shouldRefreshCommittedDisplay(GamificationState state) {
    final missions = _extractMissions(state);
    if (missions == null || _committedDisplay == null) return false;

    final locked = _findMissionById(missions, _lockedUserMissionId);
    if (locked == null) return true;

    final next = _MissionDisplayData.fromMission(locked);
    return next.progress != _committedDisplay!.progress ||
        next.isCompleted != _committedDisplay!.isCompleted ||
        next.progressText != _committedDisplay!.progressText;
  }

  void _tryCommitFromMissions(
    List<UserMission> missions, {
    required bool allowNewLock,
  }) {
    if (_lockedUserMissionId != null) {
      final locked = _findMissionById(missions, _lockedUserMissionId);
      if (locked != null) {
        final next = _MissionDisplayData.fromMission(locked);
        _committedDisplay = next;

        if (locked.isCompleted) {
          final successor = _selectActiveMission(
            missions,
            excludeUserMissionId: locked.id,
          );
          if (successor != null && allowNewLock) {
            _lockMission(successor);
          }
        }
        return;
      }
    }

    if (!allowNewLock) return;

    final candidate = _selectActiveMission(missions);
    if (candidate != null) {
      _lockMission(candidate);
    }
  }

  void _lockMission(UserMission mission) {
    _lockedUserMissionId = mission.id;
    _committedDisplay = _MissionDisplayData.fromMission(mission);
  }

  UserMission? _findMissionById(List<UserMission> missions, String? id) {
    if (id == null) return null;
    for (final mission in missions) {
      if (mission.id == id) return mission;
    }
    return null;
  }

  UserMission? _selectActiveMission(
    List<UserMission> missions, {
    String? excludeUserMissionId,
  }) {
    final actives = missions
        .where(
          (m) => m.isActive && m.id != excludeUserMissionId,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (actives.isEmpty) return null;
    return actives.first;
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
