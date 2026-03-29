import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/classes_bloc.dart';
import '../bloc/classes_state.dart';
import '../../data/models/class_timer_state.dart';

/// Widget que exibe o timer global em todas as páginas quando há uma aula ativa
class GlobalTimerWidget extends StatelessWidget {
  const GlobalTimerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClassesBloc, ClassesState>(
      builder: (context, state) {
        print('🕐 [GLOBAL_TIMER_WIDGET] State: ${state.runtimeType}');
        
        if (state is ClassesLoaded) {
          print('🕐 [GLOBAL_TIMER_WIDGET] Timers disponíveis: ${state.timers.length}');
          
          // Encontrar timer ativo
          ClassTimerState? activeTimer;
          for (final entry in state.timers.entries) {
            print('🕐 [GLOBAL_TIMER_WIDGET] Timer ${entry.key}: isActive=${entry.value.isActive}, remainingSeconds=${entry.value.remainingSecondsCalculated}');
            if (entry.value.isActive) {
              activeTimer = entry.value;
              break;
            }
          }
          
          if (activeTimer != null) {
            print('🕐 [GLOBAL_TIMER_WIDGET] Timer ativo encontrado: ${activeTimer.classId}');
            return _buildTimerOverlay(activeTimer);
          } else {
            print('🕐 [GLOBAL_TIMER_WIDGET] Nenhum timer ativo encontrado');
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
  
  Widget _buildTimerOverlay(ClassTimerState timer) {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Aula em andamento',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Text(
              _formatTime(timer.remainingSecondsCalculated),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
