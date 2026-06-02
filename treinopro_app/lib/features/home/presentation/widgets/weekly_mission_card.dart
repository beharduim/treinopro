import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/home_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../gamification/domain/entities/gamification_entity.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_state.dart';
import '../../../gamification/presentation/widgets/animated_xp_bar.dart';
import 'mission_card_display.dart';

/// Card da missão semanal — trava na missão correta, sem flicker ou loading.
class WeeklyMissionCard extends StatefulWidget {
  final HomeState homeState;

  const WeeklyMissionCard({super.key, required this.homeState});

  @override
  State<WeeklyMissionCard> createState() => _WeeklyMissionCardState();
}

class _WeeklyMissionCardState extends State<WeeklyMissionCard> {
  static const double _cardHeight = 180;

  _MissionDisplayData? _display;
  String? _lockedMissionId;
  bool _initialPickDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyGamificationState(context.read<GamificationBloc>().state);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GamificationBloc, GamificationState>(
      listenWhen: _shouldListen,
      listener: (context, state) => _applyGamificationState(state),
      child: _display != null
          ? _buildMissionCard(_display!)
          : const SizedBox(height: _cardHeight),
    );
  }

  bool _shouldListen(GamificationState previous, GamificationState current) {
    if (current is! GamificationLoaded &&
        current is! GamificationMissionCompleted) {
      return false;
    }
    if (previous is GamificationLoaded && current is GamificationLoaded) {
      return !MissionCardDisplay.missionsSnapshotEqual(
        previous.userMissions,
        current.userMissions,
      );
    }
    return true;
  }

  void _applyGamificationState(GamificationState state) {
    final missions = MissionCardDisplay.extractMissions(state);
    if (missions == null || missions.isEmpty) return;

    _MissionDisplayData? next;

    if (_lockedMissionId != null) {
      final locked =
          MissionCardDisplay.findMissionById(missions, _lockedMissionId);
      if (locked != null) {
        if (locked.isCompleted) {
          final successor = MissionCardDisplay.selectActiveMission(
            missions,
            excludeUserMissionId: locked.id,
          );
          if (successor != null) {
            _lockedMissionId = successor.id;
            next = _MissionDisplayData.fromMission(successor);
          } else {
            next = _MissionDisplayData.fromMission(locked);
          }
        } else {
          next = _MissionDisplayData.fromMission(locked);
        }
      }
    }

    if (next == null && !_initialPickDone) {
      final pick = MissionCardDisplay.pickInitialMission(missions);
      if (pick != null) {
        _lockedMissionId = pick.id;
        _initialPickDone = true;
        next = _MissionDisplayData.fromMission(pick);
      }
    }

    if (next == null) return;
    if (_display?.sameAs(next) ?? false) return;

    setState(() => _display = next);
  }

  Widget _buildMissionCard(_MissionDisplayData missionData) {
    return Container(
      width: double.infinity,
      height: _cardHeight,
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

  bool sameAs(_MissionDisplayData other) {
    return missionId == other.missionId &&
        title == other.title &&
        progress == other.progress &&
        isCompleted == other.isCompleted &&
        progressText == other.progressText;
  }
}
