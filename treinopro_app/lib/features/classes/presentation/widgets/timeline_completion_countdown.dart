import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/class_timeline_dto.dart';

/// Countdown visual local sincronizado com `remainingToCompleteSeconds` da API.
/// SSOT das regras permanece no backend; o clique ainda é validado server-side.
class TimelineCompletionCountdownController extends ChangeNotifier {
  Timer? _timer;
  int _displayRemainingSeconds = 0;
  bool _apiCanComplete = false;
  bool _countdownStarted = false;
  int _minCompletionMinutes = 50;

  bool get effectiveCanComplete =>
      _apiCanComplete || (_countdownStarted && _displayRemainingSeconds <= 0);

  int get displayRemainingSeconds => _displayRemainingSeconds.clamp(0, 999999);

  int get minCompletionMinutes => _minCompletionMinutes;

  bool get showCountdown =>
      !effectiveCanComplete && _displayRemainingSeconds > 0;

  void syncFromTimeline(ClassTimelineDto? timeline) {
    if (timeline == null) return;

    _minCompletionMinutes = timeline.minCompletionMinutes ?? 50;
    _apiCanComplete = timeline.canComplete;

    if (_apiCanComplete) {
      _displayRemainingSeconds = 0;
      _countdownStarted = false;
      _stopTimer();
      notifyListeners();
      return;
    }

    final apiRemaining = timeline.remainingToCompleteSeconds ?? 0;
    if (apiRemaining <= 0) {
      _displayRemainingSeconds = 0;
      _stopTimer();
      notifyListeners();
      return;
    }

    _countdownStarted = true;
    final drift = (apiRemaining - _displayRemainingSeconds).abs();
    if (drift > 2 || _timer == null || !_timer!.isActive) {
      _displayRemainingSeconds = apiRemaining;
      _startTimer();
    }

    notifyListeners();
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_displayRemainingSeconds <= 0) {
        _stopTimer();
        notifyListeners();
        return;
      }
      _displayRemainingSeconds -= 1;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

String formatTimelineCountdown(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
