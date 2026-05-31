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
  _ActiveMissionData? _cachedMission;
  String? _pinnedMissionId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GamificationBloc, GamificationState>(
      buildWhen: (previous, current) =>
          _displaySignature(previous) != _displaySignature(current),
      builder: (context, state) {
        final data = _extractActiveMission(state) ?? _cachedMission;
        if (data == null) {
          return const SizedBox.shrink();
        }

        _cachedMission = data;

        final String title = data.title;
        final String description = data.description;
        final int progress = data.progress;
        final int total = data.totalRequired;
        final double percent =
            total > 0 ? (progress / total).clamp(0.0, 1.0) : 0.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
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
                title.isNotEmpty ? title : description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2D3748),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data.isCompleted
                    ? 'Completada! $progress de $total'
                    : 'Progresso $progress de $total',
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

  _ActiveMissionData? _extractActiveMission(GamificationState state) {
    if (state is! GamificationLoaded) return null;

    final mission = _pickMission(state.userMissions);
    if (mission == null) return null;

    return _ActiveMissionData(
      title: mission.mission.title,
      description: mission.mission.description,
      progress: mission.progress,
      totalRequired: mission.totalRequired,
      isCompleted: mission.isCompleted,
    );
  }

  UserMission? _pickMission(List<UserMission> missions) {
    final actives = missions.where((mission) => mission.isActive).toList()
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
}
