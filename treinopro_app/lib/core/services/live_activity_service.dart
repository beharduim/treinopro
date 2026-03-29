import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage iOS Live Activities for proposal notifications.
/// No-op on Android.
class LiveActivityService {
  static final LiveActivityService instance = LiveActivityService._();
  LiveActivityService._();

  static const _channel = MethodChannel('com.treinopro.oficial/live_activity');
  static const _kPendingToken = 'la_pending_token';
  static const _kPendingProposal = 'la_pending_proposal';

  /// Máximo de Live Activities simultâneas na lock screen.
  /// O iOS empilha as mais novas no topo — quando o limite é atingido,
  /// a mais antiga (fundo da tela) é encerrada automaticamente.
  static const int _maxConcurrent = 4;

  /// Fila de proposalIds ativos, ordem de chegada: [mais antigo, ..., mais novo]
  final List<String> _activeProposalIds = [];

  /// Called when a push token is received and needs to reach the backend.
  /// Set this callback after DI is ready (in main.dart).
  Future<void> Function(String proposalId, String token)? onTokenReceived;

  /// Initialize the service and listen for token callbacks from native side
  void initialize() {
    if (!Platform.isIOS) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onLiveActivityToken') {
        final args = call.arguments as Map<dynamic, dynamic>;
        final proposalId = args['proposalId'] as String;
        final token = args['token'] as String;
        print(
          '[LiveActivityService] Token received for proposal $proposalId',
        );
        await _dispatchToken(proposalId, token);
      }
    });
  }

  /// Dispatch token: try the callback; if unavailable persist for later.
  Future<void> _dispatchToken(String proposalId, String token) async {
    if (onTokenReceived != null) {
      try {
        await onTokenReceived!(proposalId, token);
        await _clearPendingToken(); // sent successfully
        return;
      } catch (e) {
        print('[LiveActivityService] Callback failed, persisting token: $e');
      }
    }
    // No callback or callback failed — persist for flush after login
    await _persistToken(proposalId, token);
  }

  Future<void> _persistToken(String proposalId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPendingToken, token);
    await prefs.setString(_kPendingProposal, proposalId);
    print('[LiveActivityService] Pending token persisted for proposal $proposalId');
  }

  Future<void> _clearPendingToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPendingToken);
    await prefs.remove(_kPendingProposal);
  }

  /// Call after login to flush any pending Live Activity token to the backend.
  Future<void> flushPendingToken() async {
    if (!Platform.isIOS) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kPendingToken);
    final proposalId = prefs.getString(_kPendingProposal);
    if (token == null || proposalId == null) return;
    if (onTokenReceived == null) return;
    print('[LiveActivityService] Flushing pending token for proposal $proposalId');
    try {
      await onTokenReceived!(proposalId, token);
      await _clearPendingToken();
    } catch (e) {
      print('[LiveActivityService] Failed to flush pending token: $e');
    }
  }

  /// Start a Live Activity for a proposal (iOS only, no-op on Android).
  /// Se o limite de atividades simultâneas for atingido, encerra a mais antiga
  /// (que está na parte inferior da lock screen) para dar lugar à nova (topo).
  Future<String?> startActivity({
    required String proposalId,
    required String studentName,
    required String location,
    required String modality,
    required String price,
    required String trainingTime,
    required int expiresIn,
  }) async {
    if (!Platform.isIOS) return null;

    // Ignorar se já existe uma atividade para esta proposta
    if (_activeProposalIds.contains(proposalId)) {
      print('[LiveActivityService] Activity already active for proposal $proposalId, skipping');
      return null;
    }

    // Se atingiu o limite, encerrar a mais antiga (primeiro da fila = fundo da tela)
    if (_activeProposalIds.length >= _maxConcurrent) {
      final oldest = _activeProposalIds.removeAt(0);
      print('[LiveActivityService] Limit reached — ending oldest activity: $oldest');
      await endActivity(proposalId: oldest);
    }

    try {
      final activityId = await _channel
          .invokeMethod<String>('startLiveActivity', {
            'proposalId': proposalId,
            'studentName': studentName,
            'location': location,
            'modality': modality,
            'price': price,
            'trainingTime': trainingTime,
            'expiresIn': expiresIn,
          });
      _activeProposalIds.add(proposalId);
      print('[LiveActivityService] Activity started: $activityId (active: ${_activeProposalIds.length})');
      return activityId;
    } on PlatformException catch (e) {
      print('[LiveActivityService] Error starting activity: ${e.message}');
      return null;
    } on MissingPluginException {
      print(
        '[LiveActivityService] MissingPluginException while starting activity (channel indisponível neste isolate/contexto)',
      );
      return null;
    }
  }

  /// Update a Live Activity's status
  Future<bool> updateActivity({
    required String proposalId,
    required String status,
    String? studentName,
    String? location,
    String? modality,
    String? price,
    String? trainingTime,
  }) async {
    if (!Platform.isIOS) return false;

    try {
      final updated = await _channel.invokeMethod<bool>('updateLiveActivity', {
        'proposalId': proposalId,
        'status': status,
        if (studentName != null) 'studentName': studentName,
        if (location != null) 'location': location,
        if (modality != null) 'modality': modality,
        if (price != null) 'price': price,
        if (trainingTime != null) 'trainingTime': trainingTime,
      });
      return updated ?? false;
    } on PlatformException catch (e) {
      print('[LiveActivityService] Error updating activity: ${e.message}');
      return false;
    } on MissingPluginException {
      print(
        '[LiveActivityService] MissingPluginException while updating activity (channel indisponível neste isolate/contexto)',
      );
      return false;
    }
  }

  /// End a Live Activity (specific proposal or all)
  Future<bool> endActivity({String? proposalId}) async {
    if (!Platform.isIOS) return false;

    // Atualizar fila local
    if (proposalId != null) {
      _activeProposalIds.remove(proposalId);
    } else {
      _activeProposalIds.clear();
    }

    try {
      final ended = await _channel.invokeMethod<bool>('endLiveActivity', {
        if (proposalId != null) 'proposalId': proposalId,
      });
      print('[LiveActivityService] Activity ended: ${proposalId ?? "all"} (active: ${_activeProposalIds.length})');
      return ended ?? false;
    } on PlatformException catch (e) {
      print('[LiveActivityService] Error ending activity: ${e.message}');
      return false;
    } on MissingPluginException {
      print(
        '[LiveActivityService] MissingPluginException while ending activity (channel indisponível neste isolate/contexto)',
      );
      return false;
    }
  }
}
