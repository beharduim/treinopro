import 'dart:async';

import '../../../gamification/domain/entities/gamification_entity.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_state.dart';

/// Estabiliza qual missão exibir. Exibe na hora quando a API já define uma missão clara
/// (ex.: Primeira Aula ativa); só espera quando há ambiguidade (várias candidatas).
class MissionCardSettlement {
  static const Duration settleDelay = Duration(milliseconds: 500);
  static const Duration maxSettleWait = Duration(milliseconds: 2500);

  final void Function() onCommit;
  final GamificationBloc Function() readBloc;

  String? _settleFingerprint;
  DateTime? _settleStartedAt;
  Timer? _settleTimer;
  String? lockedUserMissionId;
  bool _hasCommitted = false;

  MissionCardSettlement({
    required this.onCommit,
    required this.readBloc,
  });

  bool get hasCommitted => _hasCommitted;

  void dispose() {
    _settleTimer?.cancel();
  }

  List<UserMission>? extractMissions(GamificationState state) {
    if (state is GamificationLoaded) return state.userMissions;
    if (state is GamificationMissionCompleted) return state.updatedMissions;
    return null;
  }

  void scheduleSettlement(List<UserMission> missions) {
    if (_hasCommitted) return;
    if (missions.isEmpty) return;

    final pick = pickDisplayMission(missions);
    if (pick != null && canCommitImmediately(missions, pick)) {
      commit(pick);
      return;
    }

    _settleStartedAt ??= DateTime.now();

    final maxWaitExceeded =
        DateTime.now().difference(_settleStartedAt!) >= maxSettleWait;
    if (maxWaitExceeded) {
      if (pick != null) commit(pick);
      return;
    }

    final fingerprint = pick?.id ?? 'none';

    if (fingerprint != _settleFingerprint) {
      _settleFingerprint = fingerprint;
      _armTimer(missions);
    } else if (_settleTimer == null || !_settleTimer!.isActive) {
      _armTimer(missions);
    }
  }

  void _armTimer(List<UserMission> fallbackMissions) {
    _settleTimer?.cancel();
    _settleTimer = Timer(settleDelay, () {
      if (_hasCommitted) return;

      final latest =
          extractMissions(readBloc().state) ?? fallbackMissions;
      if (latest.isEmpty) return;

      final pick = pickDisplayMission(latest);
      if (pick != null && canCommitImmediately(latest, pick)) {
        commit(pick);
        return;
      }

      final maxWait = _settleStartedAt != null &&
          DateTime.now().difference(_settleStartedAt!) >= maxSettleWait;

      final fingerprint = pick?.id ?? 'none';

      if (fingerprint == _settleFingerprint || maxWait) {
        if (pick != null) commit(pick);
      } else {
        _settleFingerprint = fingerprint;
        _armTimer(latest);
      }
    });
  }

  void commit(UserMission mission) {
    _settleTimer?.cancel();
    lockedUserMissionId = mission.id;
    _hasCommitted = true;
    onCommit();
  }

  /// Primeira Aula / attend_class — missão de primeiro acesso do aluno.
  static bool isPrimeiraAulaMission(UserMission mission) {
    if (mission.mission.action == 'attend_class') return true;
    final title = mission.mission.title.toLowerCase();
    return title.contains('primeira aula');
  }

  /// Exibe sem delay quando a API já retornou exatamente uma missão em andamento.
  static bool canCommitImmediately(List<UserMission> missions, UserMission pick) {
    if (pick.isCompleted || !pick.isActive) return false;

    final inProgress = missions.where((m) => m.isActive && !m.isCompleted).toList();
    if (inProgress.length == 1) return inProgress.first.id == pick.id;

    if (isPrimeiraAulaMission(pick) && pick.isActive && !pick.isCompleted) {
      final outrasAtivas = inProgress.where((m) => m.id != pick.id).toList();
      return outrasAtivas.isEmpty;
    }

    return false;
  }

  /// Ativa e incompleta primeiro; completada só se não houver nenhuma em andamento.
  static UserMission? pickDisplayMission(List<UserMission> missions) {
    final inProgress = missions.where((m) => m.isActive && !m.isCompleted).toList()
      ..sort((a, b) {
        final aPrimeira = isPrimeiraAulaMission(a) ? 0 : 1;
        final bPrimeira = isPrimeiraAulaMission(b) ? 0 : 1;
        if (aPrimeira != bPrimeira) return aPrimeira.compareTo(bPrimeira);
        return b.createdAt.compareTo(a.createdAt);
      });
    if (inProgress.isNotEmpty) return inProgress.first;

    final incomplete = missions
        .where((m) => !m.isCompleted && m.progress < m.totalRequired)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (incomplete.isNotEmpty) return incomplete.first;

    final completed = missions.where((m) => m.isCompleted).toList()
      ..sort((a, b) {
        final aDate = a.completedAt ?? a.updatedAt;
        final bDate = b.completedAt ?? b.updatedAt;
        return bDate.compareTo(aDate);
      });
    if (completed.isNotEmpty) return completed.first;

    if (missions.isEmpty) return null;
    return missions.first;
  }

  static UserMission? findMissionById(List<UserMission> missions, String? id) {
    if (id == null) return null;
    for (final mission in missions) {
      if (mission.id == id) return mission;
    }
    return null;
  }

  static UserMission? selectActiveMission(
    List<UserMission> missions, {
    String? excludeUserMissionId,
  }) {
    final actives = missions
        .where(
          (m) => m.isActive && !m.isCompleted && m.id != excludeUserMissionId,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (actives.isEmpty) return null;
    return actives.first;
  }
}
