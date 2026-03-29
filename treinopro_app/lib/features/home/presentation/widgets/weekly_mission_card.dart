import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/home_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_state.dart';
import '../../../gamification/presentation/widgets/animated_xp_bar.dart';

/// Widget do card da missão semanal
class WeeklyMissionCard extends StatelessWidget {
  final HomeState homeState;

  const WeeklyMissionCard({super.key, required this.homeState});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GamificationBloc, GamificationState>(
      builder: (context, gamificationState) {
        // Extrair dados da missão ativa
        final missionData = _getActiveMissionData(gamificationState);
        if (missionData == null) {
          // Sem missão ativa: mostrar card informativo
          return Container(
            width: double.infinity,
            height: 180,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
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
        // Logs para depuração de conteúdo
        // ignore: avoid_print
        print('🧭 MISSION CARD: estado=${gamificationState.runtimeType}');
        if (gamificationState is GamificationLoaded) {
          final actives = gamificationState.userMissions.where((m) => m.isActive).length;
          // ignore: avoid_print
          print('🧭 MISSION CARD: missoes=${gamificationState.userMissions.length}, ativas=$actives');
        } else {
          // ignore: avoid_print
          print('🧭 MISSION CARD: usando fallback');
        }
        
        return Container(
          width: double.infinity,
          height: 180, // Altura fixa de 180px
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.primaryOrange, // Laranja principal
                AppColors.primaryOrangeLight, // Laranja secundário
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribui o espaço uniformemente
            children: [
              // Título com ícone de troféu
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    missionData['isCompleted'] ? Icons.check_circle : Icons.emoji_events,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    missionData['title'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700, // bold
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ],
              ),

              // Descrição da missão
              Text(
                missionData['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Barra de progresso
              Column(
                children: [
                  // Texto de progresso
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
                        missionData['progressText'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700, // bold
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12), // Aumentado para melhor espaçamento

        // Barra de progresso animada - largura total
        SizedBox(
          width: double.infinity,
          child: AnimatedXPBar(
            currentXP: missionData['progress'] as double,
            maxXP: missionData['totalRequired'] as double,
            height: 8,
            // CSS antigo
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
      },
    );
  }

  /// Extrai dados da missão ativa ou completada para exibição. Retorna null se não houver missão.
  Map<String, dynamic>? _getActiveMissionData(GamificationState gamificationState) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    print('🧭 MISSION CARD [$timestamp]: Estado recebido: ${gamificationState.runtimeType}');
    
    if (gamificationState is GamificationLoaded) {
      // Regra: mostrar missão ATIVA; se não houver ativa, mostrar a última COMPLETADA nos últimos 7 dias
      final nowLocal = DateTime.now().toLocal();
      final sevenDaysAgo = nowLocal.subtract(const Duration(days: 7));

      // 1) Tentar missão ativa
      dynamic activeMission;
      for (final m in gamificationState.userMissions) {
        if (m.isActive == true) {
          activeMission = m;
          break;
        }
      }
      
      // 2) Se não houver ativa, pegar última completada dentro da janela de 7 dias
      final weeklyCompleted = gamificationState.userMissions
          .where((m) => (m.isCompleted == true) && (m.completedAt != null))
          .where((m) {
            final c = m.completedAt!.toLocal();
            return c.isAfter(sevenDaysAgo) && c.isBefore(nowLocal.add(const Duration(seconds: 1)));
          })
          .toList()
        ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

      final chosen = activeMission != null ? activeMission : (weeklyCompleted.isNotEmpty ? weeklyCompleted.first : null);

      print('🧭 MISSION CARD [$timestamp]: Total de missões: ${gamificationState.userMissions.length}, ativa=${activeMission != null}, completada7dias=${weeklyCompleted.isNotEmpty}');
      
      // Debug detalhado de todas as missões
      for (int i = 0; i < gamificationState.userMissions.length; i++) {
        final mission = gamificationState.userMissions[i];
        print('🧭 MISSION CARD [$timestamp]: Missão $i: ${mission.mission.title} - Status: ${mission.status} - Ativa: ${mission.isActive} - Completada: ${mission.isCompleted}');
      }

      if (chosen != null) {
        final mission = chosen;
        
        print('🧭 MISSION CARD [$timestamp]: ✅ USANDO MISSÃO REAL -> ${mission.mission.title}');
        print('🧭 MISSION CARD [$timestamp]: Progresso missão: ${mission.progress}/${mission.totalRequired}');
        
        return {
          'title': mission.mission.title,
          'description': mission.mission.description,
          'progressText': mission.isCompleted 
              ? 'Completada! ${mission.progress}/${mission.totalRequired}'
              : '${mission.progress} de ${mission.totalRequired}',
          'progressPercentage': mission.totalRequired > 0 
              ? mission.progress / mission.totalRequired 
              : 0.0,
          'progress': mission.progress.toDouble(),
          'totalRequired': mission.totalRequired.toDouble(),
          'isCompleted': mission.isCompleted,
          'isFallback': false,
        };
      } else {
        print('🧭 MISSION CARD [$timestamp]: ⚠️ Nenhuma missão ativa/recente encontrada, ocultando card');
        return null;
      }
    }

    // Sem dados de gamificação: ocultar card
    print('🧭 MISSION CARD [$timestamp]: Estado não carregado, ocultando card');
    return null;
  }
}
