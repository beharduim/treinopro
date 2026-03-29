import '../entities/home_state.dart';

/// Repositório para a home do aluno
abstract class HomeRepository {
  /// Obtém o estado atual da home
  Future<HomeState> getHomeState();
  
  /// Atualiza o progresso da missão semanal
  Future<void> updateWeeklyMissionProgress(int progress);
  
  /// Marca o questionário de saúde como respondido
  Future<void> completeHealthQuestionnaire();
  
  /// Obtém o nome do usuário
  Future<String> getUserName();
  
  // ===== MÉTODOS PARA CARD DINÂMICO =====
  
  /// Carrega aulas agendadas do usuário
  Future<List<Map<String, dynamic>>> loadScheduledClasses(String userId);
  
  /// Carrega propostas pendentes do usuário
  Future<List<Map<String, dynamic>>> loadPendingProposals(String userId);
  
  /// Carrega dados completos do card de treinos
  Future<Map<String, dynamic>> loadWorkoutCardData(String userId);
  
  /// Cancela uma aula agendada
  Future<Map<String, dynamic>> cancelClass(String classId);
  
  /// Cancela uma proposta pendente
  Future<Map<String, dynamic>> cancelProposal(String proposalId);
}
