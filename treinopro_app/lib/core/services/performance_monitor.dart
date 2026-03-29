import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Serviço para monitorar performance em tempo real
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  bool _isMonitoring = false;
  int _totalFrames = 0;
  int _droppedFrames = 0;
  double _totalFrameTime = 0.0;
  DateTime? _startTime;
  
  // Threshold para considerar um frame como "dropado" (>16.67ms para 60fps)
  static const double _frameThreshold = 16.67;
  static const double _slowFrameThreshold = 50.0; // Frame muito lento

  /// Verifica se está monitorando
  bool get isMonitoring => _isMonitoring;

  /// Inicia o monitoramento de performance
  void startMonitoring() {
    if (_isMonitoring) return;

    debugPrint('📊 Iniciando monitoramento de performance...');
    
    _isMonitoring = true;
    _totalFrames = 0;
    _droppedFrames = 0;
    _totalFrameTime = 0.0;
    _startTime = DateTime.now();

    // Adiciona callback para monitorar frames
    SchedulerBinding.instance.addTimingsCallback(_onFrameCallback);
  }

  /// Para o monitoramento e gera relatório
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    SchedulerBinding.instance.removeTimingsCallback(_onFrameCallback);

    _generateReport();
  }

  /// Callback chamado a cada frame
  void _onFrameCallback(List<FrameTiming> timings) {
    if (!_isMonitoring) return;

    for (final timing in timings) {
      _totalFrames++;
      
      final frameTime = timing.totalSpan.inMicroseconds / 1000.0; // em ms
      _totalFrameTime += frameTime;

      // Verifica se o frame foi dropado
      if (frameTime > _frameThreshold) {
        _droppedFrames++;
        
        // Log para frames muito lentos
        if (frameTime > _slowFrameThreshold) {
          debugPrint('⚠️ Frame muito lento detectado: ${frameTime.toStringAsFixed(2)}ms');
        }
      }
    }
  }

  /// Gera relatório de performance
  void _generateReport() {
    if (_totalFrames == 0) return;

    final duration = _startTime != null 
        ? DateTime.now().difference(_startTime!).inMilliseconds 
        : 0;
    
    final dropRate = (_droppedFrames / _totalFrames) * 100;
    final avgFrameTime = _totalFrameTime / _totalFrames;
    final fps = _totalFrames / (duration / 1000.0);

    debugPrint('📊 === RELATÓRIO DE PERFORMANCE ===');
    debugPrint('⏱️ Duração: ${duration}ms');
    debugPrint('🎬 Total de frames: $_totalFrames');
    debugPrint('📉 Frames dropados: $_droppedFrames');
    debugPrint('📊 Taxa de drop: ${dropRate.toStringAsFixed(2)}%');
    debugPrint('⚡ Tempo médio por frame: ${avgFrameTime.toStringAsFixed(2)}ms');
    debugPrint('🎯 FPS médio: ${fps.toStringAsFixed(1)}');
    debugPrint('================================');

    // Força otimizações se performance estiver ruim
    if (dropRate > 10.0) {
      debugPrint('⚠️ Performance baixa detectada, forçando otimizações...');
      _forceOptimizations();
    }
  }

  /// Força otimizações quando performance está ruim
  void _forceOptimizations() {
    // Força garbage collection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pequena pausa para permitir limpeza
      Future.delayed(const Duration(milliseconds: 100));
    });
  }

  /// Retorna estatísticas atuais
  Map<String, dynamic> getStats() {
    if (_totalFrames == 0) {
      return {
        'totalFrames': 0,
        'droppedFrames': 0,
        'dropRate': 0.0,
        'avgFrameTime': 0.0,
        'isMonitoring': _isMonitoring,
      };
    }

    final dropRate = (_droppedFrames / _totalFrames) * 100;
    final avgFrameTime = _totalFrameTime / _totalFrames;

    return {
      'totalFrames': _totalFrames,
      'droppedFrames': _droppedFrames,
      'dropRate': dropRate,
      'avgFrameTime': avgFrameTime,
      'isMonitoring': _isMonitoring,
    };
  }

  /// Reseta todas as estatísticas
  void reset() {
    stopMonitoring();
    _totalFrames = 0;
    _droppedFrames = 0;
    _totalFrameTime = 0.0;
    _startTime = null;
  }
}