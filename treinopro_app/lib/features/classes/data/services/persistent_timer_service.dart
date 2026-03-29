import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service para persistir timer de aula localmente usando SharedPreferences
class PersistentTimerService {
  static const String _timerKey = 'active_class_timer';
  
  /// Salvar timer quando iniciado
  Future<void> saveTimer({
    required String classId,
    required DateTime startTime,
    required int durationMs,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_timerKey, json.encode({
        'classId': classId,
        'startTime': startTime.toIso8601String(),
        'durationMs': durationMs,
        'savedAt': DateTime.now().toIso8601String(),
      }));
      print('💾 [PERSISTENT_TIMER] Timer salvo: $classId');
    } catch (e) {
      print('❌ [PERSISTENT_TIMER] Erro ao salvar timer: $e');
    }
  }
  
  /// Carregar timer ao abrir app
  Future<Map<String, dynamic>?> loadTimer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timerData = prefs.getString(_timerKey);
      if (timerData != null) {
        final data = json.decode(timerData);
        print('💾 [PERSISTENT_TIMER] Timer carregado: ${data['classId']}');
        return data;
      }
    } catch (e) {
      print('❌ [PERSISTENT_TIMER] Erro ao decodificar timer: $e');
      await clearTimer(); // Limpar dados corrompidos
    }
    return null;
  }
  
  /// Limpar timer quando finalizado
  Future<void> clearTimer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_timerKey);
      print('💾 [PERSISTENT_TIMER] Timer limpo');
    } catch (e) {
      print('❌ [PERSISTENT_TIMER] Erro ao limpar timer: $e');
    }
  }
  
  /// Verificar se timer ainda é válido
  bool isTimerValid(Map<String, dynamic> timerData) {
    try {
      final startTime = DateTime.parse(timerData['startTime']);
      final durationMs = int.tryParse(timerData['durationMs'].toString()) ?? 0;
      final now = DateTime.now();
      
      final elapsed = now.difference(startTime).inMilliseconds;
      final remaining = durationMs - elapsed;
      
      return remaining > 0;
    } catch (e) {
      print('❌ [PERSISTENT_TIMER] Erro ao validar timer: $e');
      return false;
    }
  }
  
  /// Calcular tempo restante
  int calculateRemainingSeconds(Map<String, dynamic> timerData) {
    try {
      final startTime = DateTime.parse(timerData['startTime']);
      final durationMs = int.tryParse(timerData['durationMs'].toString()) ?? 0;
      final now = DateTime.now();
      
      final elapsed = now.difference(startTime).inMilliseconds;
      final remaining = (durationMs - elapsed).clamp(0, durationMs);
      
      return (remaining / 1000).round();
    } catch (e) {
      print('❌ [PERSISTENT_TIMER] Erro ao calcular tempo restante: $e');
      return 0;
    }
  }
  
  /// Verificar se existe timer salvo
  Future<bool> hasActiveTimer() async {
    final timerData = await loadTimer();
    return timerData != null && isTimerValid(timerData);
  }
}
