import '../../../gamification/domain/entities/gamification_entity.dart';
import '../../../gamification/presentation/bloc/gamification_state.dart';

/// Lógica pura de seleção/exibição da missão no card — sem timers nem side effects.
class MissionCardDisplay {
  static List<UserMission>? extractMissions(GamificationState state) {
    if (state is GamificationLoaded) return state.userMissions;
    if (state is GamificationMissionCompleted) return state.updatedMissions;
    return null;
  }

  static bool missionsSnapshotEqual(
    List<UserMission> a,
    List<UserMission> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.id != right.id ||
          left.progress != right.progress ||
          left.isCompleted != right.isCompleted ||
          left.isActive != right.isActive) {
        return false;
      }
    }
    return true;
  }

  static bool isPrimeiraAulaMission(UserMission mission) {
    if (mission.mission.action == 'attend_class') return true;
    return mission.mission.title.toLowerCase().contains('primeira aula');
  }

  /// Seleção inicial estável.
  /// Prioriza ativa/incompleta; se não existir, usa incompleta recente;
  /// depois completada recente para não sumir o card.
  static UserMission? pickInitialMission(List<UserMission> missions) {
    final active = missions.where((m) => m.isActive && !m.isCompleted).toList()
      ..sort((a, b) {
        final aPrimeira = isPrimeiraAulaMission(a) ? 0 : 1;
        final bPrimeira = isPrimeiraAulaMission(b) ? 0 : 1;
        if (aPrimeira != bPrimeira) return aPrimeira.compareTo(bPrimeira);
        return b.createdAt.compareTo(a.createdAt);
      });
    if (active.isNotEmpty) return active.first;

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
          (m) =>
              m.isActive &&
              !m.isCompleted &&
              m.id != excludeUserMissionId,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (actives.isEmpty) return null;
    return actives.first;
  }
}
