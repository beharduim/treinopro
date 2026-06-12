import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/class_timer_state.dart';

/// Widget de timer fluido que atualiza a cada segundo sem depender do BlocBuilder
class FluidTimerWidget extends StatefulWidget {
  final ClassTimerState timerState;
  final double size;
  final TextStyle? textStyle;
  final bool showSeconds;
  final VoidCallback? onExpired;

  const FluidTimerWidget({
    super.key,
    required this.timerState,
    this.size = 250.0,
    this.textStyle,
    this.showSeconds = true,
    this.onExpired,
  });

  @override
  State<FluidTimerWidget> createState() => _FluidTimerWidgetState();
}

class _FluidTimerWidgetState extends State<FluidTimerWidget> {
  Timer? _timer;
  int _remainingSeconds = 0;
  double _progress = 0.0;
  bool _expiredCallbackFired = false;

  @override
  void initState() {
    super.initState();
    _updateTimer();
    _startTimer();
  }

  @override
  void didUpdateWidget(FluidTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timerState != widget.timerState) {
      if (oldWidget.timerState.classId != widget.timerState.classId) {
        _expiredCallbackFired = false;
      }
      _updateTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTimer();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateTimer() {
    final startTime = widget.timerState.startTime;
    if (startTime == null) {
      _remainingSeconds = 0;
      _progress = 0.0;
    } else {
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      final totalSeconds = widget.timerState.durationMinutes * 60;
      _remainingSeconds = (totalSeconds - elapsed).clamp(0, totalSeconds);
      _progress = totalSeconds > 0 ? _remainingSeconds / totalSeconds : 0.0;

      if (_remainingSeconds <= 0 &&
          !_expiredCallbackFired &&
          widget.onExpired != null) {
        _expiredCallbackFired = true;
        widget.onExpired!();
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (widget.showSeconds) {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress indicator
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 14,
              color: AppColors.primaryOrange,
              backgroundColor: const Color(0xFFF1F5F9),
            ),
          ),
          // Timer text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Duração do treino',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Color(0xFF0F131A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatTime(_remainingSeconds),
                style: widget.textStyle ?? const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 34,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tempo restante',
                style: TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
