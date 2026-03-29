import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import '../../features/classes/data/services/classes_api_service.dart';
import '../di/dependency_injection.dart';

/// Gerencia a captura de snapshots de presença por aula.
/// - 1 snapshot por participante por aula (idempotente no backend).
/// - Tenta capturar em T0 (horário agendado da aula).
/// - Se falhar, mantém a pendência e tenta novamente até conseguir.
/// - Retry em foreground por timer e no primeiro `resumed` após T0.
class ClassPresenceSnapshotService {
  static const String _storageKey = 'pending_snapshots_json';
  static const Duration _defaultRetryInterval = Duration(minutes: 2);
  static ClassPresenceSnapshotService? _instance;
  static Duration _retryInterval = _defaultRetryInterval;
  static ClassPresenceSnapshotService get instance =>
      _instance ??= ClassPresenceSnapshotService._();

  static void resetForTesting() {
    _instance = null;
    _retryInterval = _defaultRetryInterval;
  }

  static void overrideRetryIntervalForTesting(Duration interval) {
    _retryInterval = interval;
  }

  ClassPresenceSnapshotService._() {
    _loadFromStorage();
  }

  // Mapa de snapshots pendentes: classId -> dados pendentes
  final Map<String, _PendingSnapshot> _pending = {};

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_storageKey);
      if (str == null) return;

      final Map<String, dynamic> raw = jsonDecode(str);
      for (final entry in raw.entries) {
        final Map<String, dynamic> data = entry.value;
        final pending = _PendingSnapshot(
          classId: entry.key,
          userId: data['userId'],
          role: data['role'],
          scheduledAt: DateTime.parse(data['scheduledAt']),
        );
        pending.captured = data['captured'] == true;
        pending.attemptCount = (data['attemptCount'] as num?)?.toInt() ?? 0;
        pending.lastAttemptAt = data['lastAttemptAt'] != null
            ? DateTime.tryParse(data['lastAttemptAt'].toString())
            : null;
        pending.nextRetryAt = data['nextRetryAt'] != null
            ? DateTime.tryParse(data['nextRetryAt'].toString())
            : null;
        _pending[entry.key] = pending;

        // Reagendar snapshot futuro ou retry pendente após restart.
        if (!pending.captured) {
          final now = DateTime.now();
          if (pending.scheduledAt.isAfter(now)) {
            _scheduleInitialAttempt(pending);
          } else if (pending.nextRetryAt != null &&
              pending.nextRetryAt!.isAfter(now)) {
            _scheduleRetry(pending, at: pending.nextRetryAt!);
          }
        }
      }
      onAppResumed(); // Tenta processar pendências carregadas que já venceram
    } catch (e) {
      print('❌ [SNAPSHOT] Erro ao carregar pendências: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSave = _pending.map(
        (k, v) => MapEntry(k, {
          'classId': v.classId,
          'userId': v.userId,
          'role': v.role,
          'scheduledAt': v.scheduledAt.toIso8601String(),
          'captured': v.captured,
          'attemptCount': v.attemptCount,
          'lastAttemptAt': v.lastAttemptAt?.toIso8601String(),
          'nextRetryAt': v.nextRetryAt?.toIso8601String(),
        }),
      );
      await prefs.setString(_storageKey, jsonEncode(mapToSave));
    } catch (e) {
      print('❌ [SNAPSHOT] Erro ao salvar pendências: $e');
    }
  }

  /// Agenda a captura de snapshot para uma aula no horário T0.
  /// Deve ser chamado quando a aula é agendada ou o app inicia com aula futura.
  void scheduleSnapshot({
    required String classId,
    required String userId,
    required String role, // 'student' | 'personal'
    required DateTime scheduledAt, // T0
  }) {
    if (_pending.containsKey(classId)) return; // Já agendado/capturado

    final now = DateTime.now();
    final delay = scheduledAt.difference(now);

    final pending = _PendingSnapshot(
      classId: classId,
      userId: userId,
      role: role,
      scheduledAt: scheduledAt,
    );
    _pending[classId] = pending;
    _saveToStorage();

    if (delay.isNegative || delay.inSeconds <= 0) {
      // T0 já passou — tentar imediatamente (catch-up)
      unawaited(_attemptCapture(pending, source: 'resume'));
    } else {
      // Agendar para T0
      _scheduleInitialAttempt(pending);
    }
  }

  /// Chamado quando o app retorna ao foreground (resumed).
  /// Verifica se há snapshots pendentes cujo T0 já passou.
  Future<void> onAppResumed() async {
    final now = DateTime.now();
    for (final entry in List<MapEntry<String, _PendingSnapshot>>.from(
      _pending.entries,
    )) {
      final pending = entry.value;
      if (!pending.captured && now.isAfter(pending.scheduledAt)) {
        await _attemptCapture(pending, source: 'resume');
      }
    }
  }

  /// Remove snapshot agendado (quando aula é cancelada, etc.)
  void cancelSnapshot(String classId) {
    _pending[classId]?.timer?.cancel();
    _pending.remove(classId);
    _saveToStorage();
  }

  /// Tenta capturar a localização sincronicamente AGORA.
  /// Usado logo antes de reportar um no-show (Disputa), se a timeline ainda marcar hasPresenceSnapshot == false.
  Future<bool> captureNow({
    required String classId,
    required String userId,
    required String role,
  }) async {
    print('🔍 [SNAPSHOT] Executando captureNow() síncrono para aula $classId');

    // Obter ou criar um PendingSnapshot forçado para hoje
    var pending = _pending[classId];
    if (pending == null) {
      pending = _PendingSnapshot(
        classId: classId,
        userId: userId,
        role: role,
        scheduledAt: DateTime.now(),
      );
      _pending[classId] = pending;
      _saveToStorage();
    }

    // Tenta capturar e aguarda o resultado booleano
    final success = await _attemptCapture(pending, source: 'foreground_manual');
    return success;
  }

  Future<bool> _attemptCapture(
    _PendingSnapshot pending, {
    required String source,
  }) async {
    if (pending.captured) return true;
    if (pending.isCapturing) return false;

    pending.isCapturing = true;
    pending.lastAttemptAt = DateTime.now();
    pending.attemptCount += 1;
    pending.nextRetryAt = null;
    await _saveToStorage();

    try {
      final locationService = LocationService.instance;
      final position = await locationService.getLocationWithFallback();
      if (position == null) {
        print(
          '📍 [SNAPSHOT] Localização não disponível para aula ${pending.classId}',
        );
        _scheduleRetry(pending);
        return false;
      }

      final api = sl<ClassesApiService>();
      await api.createPresenceSnapshot(
        classId: pending.classId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        capturedAt: DateTime.now().toIso8601String(),
        captureSource: source,
        appState: source.startsWith('foreground') ? 'foreground' : 'resumed',
      );

      pending.captured = true;
      pending.timer?.cancel();
      pending.nextRetryAt = null;
      await _saveToStorage();
      print(
        '✅ [SNAPSHOT] Presença registrada para aula ${pending.classId} (source: $source)',
      );
      return true;
    } catch (e) {
      print(
        '❌ [SNAPSHOT] Erro ao capturar presença para aula ${pending.classId}: $e',
      );
      _scheduleRetry(pending);
      return false;
    } finally {
      pending.isCapturing = false;
    }
  }

  void _scheduleInitialAttempt(_PendingSnapshot pending) {
    pending.timer?.cancel();
    final now = DateTime.now();
    final delay = pending.scheduledAt.difference(now);
    if (delay.isNegative || delay.inSeconds <= 0) {
      unawaited(_attemptCapture(pending, source: 'resume'));
      return;
    }

    pending.timer = Timer(delay, () {
      unawaited(_attemptCapture(pending, source: 'foreground'));
    });
  }

  void _scheduleRetry(_PendingSnapshot pending, {DateTime? at}) {
    if (pending.captured) return;

    pending.timer?.cancel();
    final retryAt = at ?? DateTime.now().add(_retryInterval);
    pending.nextRetryAt = retryAt;
    final delay = retryAt.difference(DateTime.now());

    pending.timer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () => unawaited(_attemptCapture(pending, source: 'retry')),
    );

    _saveToStorage();
    print(
      '⏳ [SNAPSHOT] Retry agendado para aula ${pending.classId} em ${retryAt.toIso8601String()}',
    );
  }
}

class _PendingSnapshot {
  final String classId;
  final String userId;
  final String role;
  final DateTime scheduledAt;
  bool captured = false;
  bool isCapturing = false;
  int attemptCount = 0;
  DateTime? lastAttemptAt;
  DateTime? nextRetryAt;
  Timer? timer;

  _PendingSnapshot({
    required this.classId,
    required this.userId,
    required this.role,
    required this.scheduledAt,
  });
}
