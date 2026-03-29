import 'dart:async';
import 'package:flutter/material.dart';
import '../di/dependency_injection.dart';
import '../services/class_countdown_service.dart';

/// Widget reutilizável para exibir o tempo restante de uma aula
/// Usado em todas as telas: acompanhamento, card do personal, card do aluno
class SharedTimerWidget extends StatefulWidget {
  final String classId;
  final TextStyle? textStyle;
  final bool showSeconds;
  final String? suffix; // Ex: 'm' para minutos, ou null para minutos:segundos

  const SharedTimerWidget({
    super.key,
    required this.classId,
    this.textStyle,
    this.showSeconds = true,
    this.suffix,
  });

  @override
  State<SharedTimerWidget> createState() => _SharedTimerWidgetState();
}

class _SharedTimerWidgetState extends State<SharedTimerWidget> {
  late StreamSubscription<Duration> _subscription;
  Duration _remaining = Duration.zero;
  final ClassCountdownService _countdownService = sl<ClassCountdownService>();

  @override
  void initState() {
    super.initState();
    _initTimer();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _initTimer() async {
    // Obtém o tempo inicial
    _remaining = await _countdownService.getRemainingTime(widget.classId);
    
    if (mounted) {
      setState(() {});
    }

    // Assina o stream para atualizações em tempo real
    _subscription = _countdownService.remainingStream(widget.classId).listen((duration) {
      if (mounted) {
        setState(() {
          _remaining = duration;
        });
      }
    });
  }

  String _formatTime() {
    if (widget.showSeconds) {
      // Mostra minutos:segundos (ex: 58:30)
      return _countdownService.formatRemainingTime(_remaining);
    } else {
      // Mostra apenas minutos (ex: 58m)
      return '${_remaining.inMinutes}${widget.suffix ?? 'm'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatTime(),
      style: widget.textStyle ?? const TextStyle(
        fontFamily: 'Fira Sans',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}
