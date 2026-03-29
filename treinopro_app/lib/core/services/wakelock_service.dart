import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Manages screen wakelock for the personal trainer while online/available.
///
/// Usage:
///   WakelockService.instance.enable()   // personal goes online
///   WakelockService.instance.disable()  // personal goes offline / app pauses
///
/// No-op on non-mobile platforms (web, desktop).
class WakelockService {
  static final WakelockService instance = WakelockService._();
  WakelockService._();

  bool _enabled = false;

  bool get isEnabled => _enabled;

  /// Enable wakelock — screen will not auto-lock while personal is online.
  Future<void> enable() async {
    if (!_isMobile) return;
    if (_enabled) return;
    try {
      await WakelockPlus.enable();
      _enabled = true;
      if (kDebugMode) {
        print('[WAKELOCK] Screen lock disabled — personal online mode active');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[WAKELOCK] Failed to enable: $e');
      }
    }
  }

  /// Disable wakelock — system auto-lock resumes normally.
  Future<void> disable() async {
    if (!_isMobile) return;
    if (!_enabled) return;
    try {
      await WakelockPlus.disable();
      _enabled = false;
      if (kDebugMode) {
        print('[WAKELOCK] Screen lock re-enabled — personal offline or app paused');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[WAKELOCK] Failed to disable: $e');
      }
    }
  }

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;
}
