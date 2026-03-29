import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/classes_bloc.dart';
import '../bloc/classes_state.dart';

class ClassTimerWidget extends StatelessWidget {
  final String classId;
  final bool showSeconds;
  final String? suffix;
  final TextStyle? textStyle;

  const ClassTimerWidget({
    super.key,
    required this.classId,
    this.showSeconds = false,
    this.suffix,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClassesBloc, ClassesState>(
      builder: (context, state) {        
        if (state is! ClassesLoaded) {
          return const SizedBox.shrink();
        }
        // Verificar se o timer existe e está ativo
        try {
          final timer = state.timers[classId];          
          if (timer == null || !timer.isActive) {
            return const SizedBox.shrink();
          }

          final remainingSeconds = timer.remainingSecondsCalculated;
          final hours = remainingSeconds ~/ 3600;
          final minutes = (remainingSeconds % 3600) ~/ 60;
          final seconds = remainingSeconds % 60;
          
          String timeText;
          if (hours > 0) {
            timeText = showSeconds 
                ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
                : '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
          } else {
            if (showSeconds) {
              timeText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
            } else {
              // Mostrar formato compacto: 60m, 45m, etc.
              // Garantir que sempre mostre pelo menos 1 minuto quando há tempo restante
              final displayMinutes = minutes > 0 ? minutes : 1;
              timeText = '${displayMinutes}m';
            }
          }

          // Aplicar suffix apenas se não for o formato compacto com 'm'
          if (suffix != null && !timeText.endsWith('m')) {
            timeText += suffix!;
          }

          return Text(
            timeText,
            style: textStyle ?? const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        } catch (e) {
          // Se houver erro ao acessar timers, retorna widget vazio
          return const SizedBox.shrink();
        }
      },
    );
  }
}
