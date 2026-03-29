import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/gamification_bloc.dart';
import '../bloc/gamification_state.dart';
import '../../domain/entities/gamification_entity.dart';
import '../../data/models/gamification_dto.dart';

/// Widget de debug para mostrar o status das missões em tempo real
class MissionDebugWidget extends StatelessWidget {
  const MissionDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GamificationBloc, GamificationState>(
      builder: (context, state) {
        if (state is! GamificationLoaded) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Gamificação não carregada'),
            ),
          );
        }

        final missions = state.userMissions;
        
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🐛 DEBUG - Missões',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Total de missões: ${missions.length}'),
                const SizedBox(height: 8),
                ...missions.map((mission) => _buildMissionDebugItem(mission)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMissionDebugItem(UserMission mission) {
    Color statusColor;
    String statusText;
    
    switch (mission.status) {
      case MissionStatus.active:
        statusColor = Colors.blue;
        statusText = 'ATIVA';
        break;
      case MissionStatus.completed:
        statusColor = Colors.green;
        statusText = 'CONCLUÍDA';
        break;
      case MissionStatus.expired:
        statusColor = Colors.red;
        statusText = 'EXPIRADA';
        break;
      case MissionStatus.cancelled:
        statusColor = Colors.grey;
        statusText = 'CANCELADA';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: statusColor),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child:               Text(
                mission.mission.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Progresso: ${mission.progress}/${mission.totalRequired}',
            style: const TextStyle(fontSize: 12),
          ),
          if (mission.mission.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              mission.mission.description,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: mission.totalRequired > 0 ? mission.progress / mission.totalRequired : 0.0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ],
      ),
    );
  }
}
