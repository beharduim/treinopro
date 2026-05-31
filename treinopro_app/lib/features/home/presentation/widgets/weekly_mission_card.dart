import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/home_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../gamification/domain/entities/gamification_entity.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_state.dart';
import '../../../gamification/presentation/widgets/animated_xp_bar.dart';

/// Widget do card da missão semanal
class WeeklyMissionCard extends StatefulWidget {
  final HomeState homeState;

  const WeeklyMissionCard({super.key, required this.homeState});

  @override
  State<WeeklyMissionCard> createState() => _WeeklyMissionCardState();
}

class _WeeklyMissionCardState extends State<WeeklyMissionCard> {
  _MissionDisplayData? _cachedMission;
  String? _pinnedMissionId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GamificationBloc, GamificationState>(
      buildWhen: (previous, current) =>
          _displaySignature(previous) != _displaySignature(current),
      builder: (context, gamificationState) {
        final missionData = _resolveMissionDisplay(gamificationState);

        if (missionData != null) {
          _cachedMission = missionData;
        } else if (_cachedMission != null &&
            gamificationState is! GamificationLoaded) {
          return _buildMissionCard(_cachedMission!);
        }

        if (missionData == null) {
          return _buildPlaceholderCard();
        }

        return _buildMissionCard(missionData);
      },
    );
  }

  String _displaySignature(GamificationState state) {
    if (state is GamificationLoaded) {
      final mission = _pickMission(state.userMissions);
      if (mission == null) return 'loaded:none';
      return 'loaded:${mission.id}:${mission.status.name}:${mission.progress}';
    }
    return state.runtimeType.toString();
  }

  _MissionDisplayData? _resolveMissionDisplay(GamificationState state) {
    if (state is GamificationLoaded) {
      final mission = _pickMission(state.userMissions);
      if (mission == null) return null;
      return _MissionDisplayData.fromMission(mission);
    }
    return null;
  }

  UserMission? _pickMission(List<UserMission> missions) {
    final actives = missions.where((m) => m.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (actives.isNotEmpty) {
      _pinnedMissionId = actives.first.id;
      return actives.first;
    }

    if (_pinnedMissionId != null) {
      for (final mission in missions) {
        if (mission.id == _pinnedMissionId) {
          return mission;
        }
      }
    }

    return null;
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
              Text(
                missionData.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
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

  Widget _buildPlaceholderCard() {
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
                Icons.emoji_events,
                size: 20,
                color: Colors.white.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 8),
              const Text(
                'Missão Semanal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
          Text(
            'você ainda não tem uma missão atribuída a você',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
            width: double.infinity,
            child: AnimatedXPBar(
              currentXP: 0,
              maxXP: 1,
              height: 8,
              trackColor: Colors.white.withValues(alpha: 0.35),
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
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
