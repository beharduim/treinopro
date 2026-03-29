import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/gamification_bloc.dart';
import '../bloc/gamification_state.dart';
import '../../domain/entities/gamification_entity.dart';

/// Widget para gerenciar animações de gamificação
class GamificationAnimations extends StatefulWidget {
  final Widget child;

  const GamificationAnimations({
    super.key,
    required this.child,
  });

  @override
  State<GamificationAnimations> createState() => _GamificationAnimationsState();
}

class _GamificationAnimationsState extends State<GamificationAnimations>
    with TickerProviderStateMixin {
  late AnimationController _xpAnimationController;
  late AnimationController _levelUpAnimationController;
  late AnimationController _missionCompletedAnimationController;
  
  late Animation<double> _levelUpScaleAnimation;
  late Animation<double> _missionCompletedScaleAnimation;
  late Animation<double> _levelUpOpacityAnimation;
  late Animation<double> _missionCompletedOpacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controller para animação de XP
    _xpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Controller para animação de level up
    _levelUpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Controller para animação de missão completada
    _missionCompletedAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Controller de XP preparado para futuras animações visuais pontuais

    // Animações de level up
    _levelUpScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _levelUpAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _levelUpOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _levelUpAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Animações de missão completada
    _missionCompletedScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _missionCompletedAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _missionCompletedOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _missionCompletedAnimationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));
  }

  @override
  void dispose() {
    _xpAnimationController.dispose();
    _levelUpAnimationController.dispose();
    _missionCompletedAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GamificationBloc, GamificationState>(
      listener: (context, state) {
        if (state is GamificationLevelUp) {
          _showLevelUpAnimation(context, state.levelUp);
        } else if (state is GamificationMissionCompleted) {
          _showMissionCompletedAnimation(context, state.completedMission);
        }
      },
      child: widget.child,
    );
  }

  /// Mostra animação de level up
  void _showLevelUpAnimation(BuildContext context, LevelUp levelUp) {
    _levelUpAnimationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        _levelUpAnimationController.reverse();
      });
    });

    // Mostrar overlay com animação
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LevelUpOverlay(
        levelUp: levelUp,
        scaleAnimation: _levelUpScaleAnimation,
        opacityAnimation: _levelUpOpacityAnimation,
        onAnimationComplete: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// Mostra animação de missão completada
  void _showMissionCompletedAnimation(BuildContext context, UserMission mission) {
    _missionCompletedAnimationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        _missionCompletedAnimationController.reverse();
      });
    });

    // Mostrar overlay com animação
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MissionCompletedOverlay(
        mission: mission,
        scaleAnimation: _missionCompletedScaleAnimation,
        opacityAnimation: _missionCompletedOpacityAnimation,
        onAnimationComplete: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

/// Overlay para animação de level up
class _LevelUpOverlay extends StatelessWidget {
  final LevelUp levelUp;
  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;
  final VoidCallback onAnimationComplete;

  const _LevelUpOverlay({
    required this.levelUp,
    required this.scaleAnimation,
    required this.opacityAnimation,
    required this.onAnimationComplete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([scaleAnimation, opacityAnimation]),
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: Container(
            color: Colors.black.withOpacity(0.7 * opacityAnimation.value),
            child: Center(
              child: Transform.scale(
                scale: scaleAnimation.value,
                child: Opacity(
                  opacity: opacityAnimation.value,
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ícone de troféu
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700), // Dourado
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Título
                        Text(
                          'LEVEL UP!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2A2A2A),
                            letterSpacing: 2,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Novo nível
                        Text(
                          'Nível ${levelUp.newLevel}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF666666),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // XP ganho
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '+${levelUp.xpGained} XP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Overlay para animação de missão completada
class _MissionCompletedOverlay extends StatelessWidget {
  final UserMission mission;
  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;
  final VoidCallback onAnimationComplete;

  const _MissionCompletedOverlay({
    required this.mission,
    required this.scaleAnimation,
    required this.opacityAnimation,
    required this.onAnimationComplete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([scaleAnimation, opacityAnimation]),
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: Container(
            color: Colors.black.withOpacity(0.6 * opacityAnimation.value),
            child: Center(
              child: Transform.scale(
                scale: scaleAnimation.value,
                child: Opacity(
                  opacity: opacityAnimation.value,
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ícone de missão completada
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50), // Verde
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 35,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Título
                        Text(
                          'MISSÃO COMPLETA!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2A2A2A),
                            letterSpacing: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Nome da missão
                        Text(
                          mission.mission.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF666666),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // XP ganho
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '+${mission.mission.xpReward} XP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
