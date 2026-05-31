import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../gamification/domain/entities/gamification_entity.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_state.dart';

class PersonalWeeklyMissionCard extends StatefulWidget {
  const PersonalWeeklyMissionCard({super.key});

  @override
  State<PersonalWeeklyMissionCard> createState() =>
      _PersonalWeeklyMissionCardState();
}

class _PersonalWeeklyMissionCardState extends State<PersonalWeeklyMissionCard> {
  static const Duration _settleDelay = Duration(milliseconds: 1200);

  _ActiveMissionData? _committedDisplay;
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
        builder: (context, state) {
          final missions = _extractMissions(state);
          if (missions != null && _committedDisplay != null) {
            _tryCommitFromMissions(missions, allowNewLock: true);
          }

          if (_committedDisplay == null) {
            return const SizedBox.shrink();
          }

          final data = _committedDisplay!;
          final percent = data.totalRequired > 0
              ? (data.progress / data.totalRequired).clamp(0.0, 1.0)
              : 0.0;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      data.isCompleted ? Icons.check_circle : Icons.flag,
                      size: 29,
                      color: AppColors.iconPrimary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Missão da semana',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data.title.isNotEmpty ? data.title : data.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2D3748),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data.isCompleted
                      ? 'Completada! ${data.progress} de ${data.totalRequired}'
                      : 'Progresso ${data.progress} de ${data.totalRequired}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                _ProgressBar(percent: percent),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Em breve: suas conquistas estarão disponíveis aqui!',
                        ),
                        backgroundColor: AppColors.primaryOrange,
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.primaryOrange, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Minhas conquistas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF6A00),
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
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

    return locked.progress != _committedDisplay!.progress ||
        locked.isCompleted != _committedDisplay!.isCompleted;
  }

  void _tryCommitFromMissions(
    List<UserMission> missions, {
    required bool allowNewLock,
  }) {
    if (_lockedUserMissionId != null) {
      final locked = _findMissionById(missions, _lockedUserMissionId);
      if (locked != null) {
        _committedDisplay = _ActiveMissionData.fromMission(locked);

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
    _committedDisplay = _ActiveMissionData.fromMission(mission);
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
}

class _ProgressBar extends StatelessWidget {
  final double percent;
  const _ProgressBar({required this.percent});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fill = (width * percent).clamp(0.0, width);
        return Stack(
          children: [
            Container(
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF42464D),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              width: fill,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActiveMissionData {
  final String title;
  final String description;
  final int progress;
  final int totalRequired;
  final bool isCompleted;

  _ActiveMissionData({
    required this.title,
    required this.description,
    required this.progress,
    required this.totalRequired,
    required this.isCompleted,
  });

  factory _ActiveMissionData.fromMission(UserMission mission) {
    return _ActiveMissionData(
      title: mission.mission.title,
      description: mission.mission.description,
      progress: mission.progress,
      totalRequired: mission.totalRequired,
      isCompleted: mission.isCompleted,
    );
  }
}
