import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class ClassCountdownService {
  static final ClassCountdownService _instance = ClassCountdownService._internal();
  factory ClassCountdownService() => _instance;
  ClassCountdownService._internal();

  final Map<String, Timer> _timers = {};
  final Map<String, StreamController<Duration>> _streamControllers = {};
  final Map<String, Duration> _remainingTimes = {};
  final Map<String, DateTime> _startTimes = {};

  // Inicia um timer para uma aula específica
  Future<void> start(String classId, int durationMinutes) async {
    // Para timer existente se houver
    await stop(classId);

    final duration = Duration(minutes: durationMinutes);
    final startTime = DateTime.now();

    _remainingTimes[classId] = duration;
    _startTimes[classId] = startTime;

    // Salva no SharedPreferences
    await _saveToStorage(classId, durationMinutes, startTime);

    // Cria stream controller se não existir
    if (!_streamControllers.containsKey(classId)) {
      _streamControllers[classId] = StreamController<Duration>.broadcast();
    }

    // Inicia timer
    _timers[classId] = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _remainingTimes[classId];
      if (remaining != null && remaining.inSeconds > 0) {
        _remainingTimes[classId] = remaining - const Duration(seconds: 1);
        final controller = _streamControllers[classId];
        if (controller != null && !controller.isClosed) {
          controller.add(_remainingTimes[classId]!);
        }
        
        // Salva progresso no storage
        _saveProgressToStorage(classId, _remainingTimes[classId]!.inMinutes);
      } else {
        // Timer terminou
        timer.cancel();
        _timers.remove(classId);
        _remainingTimes[classId] = Duration.zero;
        final controller = _streamControllers[classId];
        if (controller != null && !controller.isClosed) {
          controller.add(Duration.zero);
        }
        _clearFromStorage(classId);
      }
    });

    // Emite valor inicial
    final controller = _streamControllers[classId];
    if (controller != null && !controller.isClosed) {
      controller.add(duration);
    }
  }

  // Para um timer específico
  Future<void> stop(String classId) async {
    _timers[classId]?.cancel();
    _timers.remove(classId);
    _streamControllers[classId]?.close();
    _streamControllers.remove(classId);
    _remainingTimes.remove(classId);
    _startTimes.remove(classId);
    await _clearFromStorage(classId);
  }

  // Obtém o tempo restante atual
  Future<Duration> getRemaining(String classId) async {
    // Tenta carregar do storage se não estiver em memória
    if (!_remainingTimes.containsKey(classId)) {
      await _loadFromStorage(classId);
    }

    final remaining = _remainingTimes[classId] ?? Duration.zero;
    return remaining;
  }

  // Stream do tempo restante
  Stream<Duration> remainingStream(String classId) {
    if (!_streamControllers.containsKey(classId)) {
      _streamControllers[classId] = StreamController<Duration>.broadcast();
    }
    return _streamControllers[classId]!.stream;
  }

  // Função única para formatar o tempo restante (minutos:segundos)
  String formatRemainingTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds % 60)}';
  }

  // Função única para obter o tempo restante de uma aula
  Future<Duration> getRemainingTime(String classId) async {
    return await getRemaining(classId);
  }

  // Carrega timer do storage ao inicializar
  Future<void> _loadFromStorage(String classId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startTimeStr = prefs.getString('class_${classId}_start_time');
      final durationMinutes = prefs.getInt('class_${classId}_duration');
      final remainingMinutes = prefs.getInt('class_${classId}_remaining');

      if (startTimeStr != null && durationMinutes != null) {
        final startTime = DateTime.parse(startTimeStr);
        final elapsed = DateTime.now().difference(startTime);
        final totalDuration = Duration(minutes: durationMinutes);
        
        // Sempre calcula baseado no tempo decorrido para consistência
        final remaining = totalDuration - elapsed;
        _remainingTimes[classId] = remaining.inSeconds > 0 ? remaining : Duration.zero;
        
      
        _startTimes[classId] = startTime;

        // Se o timer já terminou, limpa os dados do storage
        if (_remainingTimes[classId]!.inSeconds <= 0) {
          _clearFromStorage(classId);
          return;
        }

        // Se ainda há tempo restante, reinicia o timer
        if (_remainingTimes[classId]!.inSeconds > 0) {
          _timers[classId] = Timer.periodic(const Duration(seconds: 1), (timer) {
            final remaining = _remainingTimes[classId];
            if (remaining != null && remaining.inSeconds > 0) {
              _remainingTimes[classId] = remaining - const Duration(seconds: 1);
              final controller = _streamControllers[classId];
              if (controller != null && !controller.isClosed) {
                controller.add(_remainingTimes[classId]!);
              }
              _saveProgressToStorage(classId, _remainingTimes[classId]!.inMinutes);
            } else {
              timer.cancel();
              _timers.remove(classId);
              _remainingTimes[classId] = Duration.zero;
              final controller = _streamControllers[classId];
              if (controller != null && !controller.isClosed) {
                controller.add(Duration.zero);
              }
              _clearFromStorage(classId);
            }
          });

          // Cria stream controller se não existir
          if (!_streamControllers.containsKey(classId)) {
            _streamControllers[classId] = StreamController<Duration>.broadcast();
          }
        }
      }
    } catch (e) {
      print('Erro ao carregar timer do storage: $e');
    }
  }

  // Salva timer no storage
  Future<void> _saveToStorage(String classId, int durationMinutes, DateTime startTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('class_${classId}_start_time', startTime.toIso8601String());
      await prefs.setInt('class_${classId}_duration', durationMinutes);
      await prefs.setInt('class_${classId}_remaining', durationMinutes);
    } catch (e) {
      print('Erro ao salvar timer no storage: $e');
    }
  }

  // Salva progresso no storage
  Future<void> _saveProgressToStorage(String classId, int remainingMinutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('class_${classId}_remaining', remainingMinutes);
    } catch (e) {
      print('Erro ao salvar progresso no storage: $e');
    }
  }

  // Remove timer do storage
  Future<void> _clearFromStorage(String classId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('class_${classId}_start_time');
      await prefs.remove('class_${classId}_duration');
      await prefs.remove('class_${classId}_remaining');
    } catch (e) {
      print('Erro ao limpar timer do storage: $e');
    }
  }

  // Limpa todos os timers
  Future<void> clearAll() async {
    for (final classId in _timers.keys.toList()) {
      await stop(classId);
    }
  }

  // Verifica se há um timer ativo para uma aula
  bool isActive(String classId) {
    return _timers.containsKey(classId) && 
           _remainingTimes[classId]?.inSeconds != null && 
           _remainingTimes[classId]!.inSeconds > 0;
  }
}
