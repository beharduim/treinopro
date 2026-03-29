import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Estados possíveis de uma aula
enum ClassState {
  pending,    // Aguardando confirmação do aluno
  confirmed,  // Aluno confirmou, timer pode iniciar
  rejected,   // Aluno rejeitou/reportou problema
  active,     // Aula em andamento
  completed,  // Aula finalizada
}

/// Serviço para gerenciar o estado das aulas
class ClassStateService {
  static final ClassStateService _instance = ClassStateService._internal();
  factory ClassStateService() => _instance;
  ClassStateService._internal();

  final Map<String, ClassState> _classStates = {};
  final Map<String, StreamController<ClassState>> _stateControllers = {};

  /// Obtém o estado atual de uma aula
  ClassState getClassState(String classId) {
    return _classStates[classId] ?? ClassState.pending;
  }

  /// Define o estado de uma aula
  Future<void> setClassState(String classId, ClassState state) async {
    _classStates[classId] = state;
    await _saveToStorage(classId, state);
    
    // Notifica os listeners
    final controller = _stateControllers[classId];
    if (controller != null && !controller.isClosed) {
      controller.add(state);
    }
  }

  /// Stream do estado de uma aula
  Stream<ClassState> classStateStream(String classId) {
    if (!_stateControllers.containsKey(classId)) {
      _stateControllers[classId] = StreamController<ClassState>.broadcast();
    }
    return _stateControllers[classId]!.stream;
  }

  /// Inicia uma aula (personal trainer clica em "Iniciar")
  Future<void> startClass(String classId) async {
    await setClassState(classId, ClassState.pending);
  }

  /// Confirma uma aula (aluno clica em "Aceitar")
  Future<void> confirmClass(String classId) async {
    await setClassState(classId, ClassState.confirmed);
  }

  /// Rejeita uma aula (aluno clica em "Reportar problema")
  Future<void> rejectClass(String classId) async {
    await setClassState(classId, ClassState.rejected);
  }

  /// Marca aula como ativa (timer iniciado)
  Future<void> activateClass(String classId) async {
    await setClassState(classId, ClassState.active);
  }

  /// Marca aula como concluída
  Future<void> completeClass(String classId) async {
    await setClassState(classId, ClassState.completed);
  }


  /// Salva estado no storage
  Future<void> _saveToStorage(String classId, ClassState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('class_state_$classId', state.index);
    } catch (e) {
      print('Erro ao salvar estado da aula: $e');
    }
  }

  /// Limpa estado de uma aula
  Future<void> clearClassState(String classId) async {
    _classStates.remove(classId);
    final controller = _stateControllers[classId];
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
    _stateControllers.remove(classId);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('class_state_$classId');
    } catch (e) {
      print('Erro ao limpar estado da aula: $e');
    }
  }

  /// Dispose
  void dispose() {
    for (final controller in _stateControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _stateControllers.clear();
    _classStates.clear();
  }
}
