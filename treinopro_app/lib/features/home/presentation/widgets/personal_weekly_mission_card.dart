import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../gamification/domain/entities/gamification_entity.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_state.dart';
import 'mission_card_display.dart';

class PersonalWeeklyMissionCard extends StatefulWidget {
  const PersonalWeeklyMissionCard({super.key});

  @override
  State<PersonalWeeklyMissionCard> createState() =>
      _PersonalWeeklyMissionCardState();
}

class _PersonalWeeklyMissionCardState extends State<PersonalWeeklyMissionCard> {
  _ActiveMissionData? _display;
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
      child: _display == null
          ? const SizedBox(height: 120)
          : _buildCard(_display!),
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

    _ActiveMissionData? next;

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
            next = _ActiveMissionData.fromMission(successor);
          } else {
            next = _ActiveMissionData.fromMission(locked);
          }
        } else {
          next = _ActiveMissionData.fromMission(locked);
        }
      }
    }

    if (next == null && !_initialPickDone) {
      final pick = MissionCardDisplay.pickInitialMission(missions);
      if (pick != null) {
        _lockedMissionId = pick.id;
        _initialPickDone = true;
        next = _ActiveMissionData.fromMission(pick);
      }
    }

    if (next == null) return;
    if (_display?.sameAs(next) ?? false) return;

    setState(() => _display = next);
  }

  Widget _buildCard(_ActiveMissionData data) {
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
                border: Border.all(color: AppColors.primaryOrange, width: 2),
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

  bool sameAs(_ActiveMissionData other) {
    return title == other.title &&
        progress == other.progress &&
        isCompleted == other.isCompleted &&
        totalRequired == other.totalRequired;
  }
}
