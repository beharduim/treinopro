import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/services/websocket_service.dart';
import '../../data/models/class_response_dto.dart';
import '../../data/models/class_timeline_dto.dart';
import '../../data/models/class_timeline_calculator.dart';
import '../../data/models/class_timer_state.dart';
import '../../data/models/get_classes_dto.dart';
// DTO imports não são necessários aqui, pois os tipos são usados nos eventos
import '../../data/services/classes_api_service.dart';
import '../../data/services/persistent_timer_service.dart';
import '../../data/services/student_photo_cache_service.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_event.dart';

export 'classes_event.dart';
export 'classes_state.dart';
import 'classes_event.dart';
import 'classes_state.dart';

/// Bloc responsável por centralizar o estado das aulas (aluno e personal)
class ClassesBloc extends Bloc<ClassesEvent, ClassesState> {
  final ClassesApiService _classesApi = sl<ClassesApiService>();
  final WebSocketService _ws = sl<WebSocketService>();
  final PersistentTimerService _persistentTimer = PersistentTimerService();
  final StudentPhotoCacheService _photoCache = sl<StudentPhotoCacheService>();

  // Estado interno
  List<ClassResponseDto> _classes = [];
  final Map<String, ClassTimelineDto> _timelines = {};
  final Map<String, ClassTimerState> _timers = {};
  String? _currentUserId; // Variável cacheada para userId

  // Filtros atuais
  String? _selectedDate;
  String? _selectedTime;
  String? _selectedStatus;

  // Subscriptions
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  StreamSubscription<bool>? _connSub;
  Timer? _timerUpdateTimer;

  // Rastreamento de conexão para sincronização após reconexão
  bool _wasDisconnected = false;

  // Mapa de códigos de confirmação pendentes, indexado por classId
  final Map<String, String> _pendingStartCodes = {};

  ClassesBloc() : super(const ClassesInitial()) {
    on<ClassesInitialize>(_onInitialize);
    on<ClassesConnectWebSocket>(_onConnectWs);
    on<ClassesDisconnectWebSocket>(_onDisconnectWs);
    on<ClassesLoad>(_onLoad);
    on<ClassesRefresh>(_onRefresh);
    on<ClassesUpdateFilters>(_onUpdateFilters);
    on<ClassesClearFilters>(_onClearFilters);
    on<ClassesUpdateStudentPhotos>(_onUpdateStudentPhotos);
    on<ClassesUpdateFromWebSocket>(_onUpdateFromWs);
    on<ClassesUpdateClass>(_onUpdateClass);
    on<ClassesAddClass>(_onAddClass);
    on<ClassesUpdateTimeline>(_onUpdateTimeline);
    on<ClassesStartClass>(_onStartClass);
    on<ClassesConfirmClassStart>(_onConfirmStart);
    on<ClassesCompleteClass>(_onCompleteClass);
    on<ClassesCancelClass>(_onCancelClass);
    on<ClassesReportNoShow>(_onReportNoShow);
    on<ClassesReportPersonalNoShow>(_onReportPersonalNoShow);
    on<ClassesStartTimer>(_onStartTimer);
    on<ClassesStopTimer>(_onStopTimer);
    on<ClassesUpdateTimer>(_onUpdateTimer);
    on<ClassesStartGlobalTimer>(_onStartGlobalTimer);

    // Evento de reset (logout)
    on<ClassesReset>(_onReset);

    // Evento de defesa em disputa
    on<ClassesSubmitDisputeDefense>(_onSubmitDisputeDefense);
  }

  /// Busca o ID do usuário logado do SharedPreferences.
  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  /// Obtém a aula pelo id do cache local
  ClassResponseDto? _getClassById(String classId) {
    try {
      // ✅ CORREÇÃO: Criar cópia antes de iterar para evitar concurrent modification
      final classesCopy = List<ClassResponseDto>.from(_classes);
      return classesCopy.firstWhere((c) => c.id == classId);
    } catch (_) {
      return null;
    }
  }

  /// Garante que o timeline esteja atualizado no cache para uma aula específica
  Future<ClassTimelineDto?> _ensureTimelineFresh(String classId) async {
    try {
      final tl = await _classesApi.getClassTimeline(classId);
      _timelines[classId] = tl;
      return tl;
    } catch (_) {
      return _timelines[classId];
    }
  }

  String? _mapSelectedStatusToApiStatus() {
    // ✅ Como as novas opções ('Aula futura', etc) são agrupamentos ou mapeamentos complexos,
    // vamos buscar todas as aulas do servidor e filtrar localmente para garantir consistência.
    // Retornamos null para o status na API.
    return null;
  }

  /// Filtra as aulas localmente baseado no status selecionado na UI
  List<ClassResponseDto> _applyLocalStatusFilter(List<ClassResponseDto> classes) {
    if (_selectedStatus == null || _selectedStatus!.isEmpty) return classes;

    print('🔍 [CLASSES_BLOC] Aplicando filtro local de status: $_selectedStatus');

    switch (_selectedStatus) {
      case 'Aula futura':
        // Agrupa todos os status que representam aulas não finalizadas
        return classes.where((c) => 
          c.status == ClassStatus.SCHEDULED || 
          c.status == ClassStatus.ACTIVE || 
          c.status == ClassStatus.PENDING_CONFIRMATION || 
          c.status == ClassStatus.CUSTODY
        ).toList();
      case 'Aula concluída':
        return classes.where((c) => c.status == ClassStatus.COMPLETED).toList();
      case 'Aula em disputa':
        return classes.where((c) => c.status == ClassStatus.NO_SHOW_DISPUTE).toList();
      default:
        return classes;
    }
  }

  /// Valida se uma ação é permitida com base no estado e no timeline atual
  Future<bool> _validateAction({
    required String classId,
    required String
    action, // start_class | confirm_start | complete_class | cancel_class | report_personal_no_show
    required Emitter<ClassesState> emit,
  }) async {
    final current = _getClassById(classId);
    if (current == null) {
      emit(
        ClassesOperationFailure(
          classes: _classes,
          timelines: _timelines,
          timers: _timers,
          error: 'Aula não encontrada',
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedStatus: _selectedStatus,
          isWebSocketConnected: _ws.isConnected,
        ),
      );
      return false;
    }

    // Atualiza timeline antes de validar
    final tl = await _ensureTimelineFresh(classId);
    if (tl == null) {
      emit(
        ClassesOperationFailure(
          classes: _classes,
          timelines: _timelines,
          timers: _timers,
          error:
              'Não foi possível validar o estado da aula (timeline indisponível).',
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedStatus: _selectedStatus,
          isWebSocketConnected: _ws.isConnected,
        ),
      );
      return false;
    }

    // Mapear permissões por ação com base no timeline
    bool allowed = true;
    String? reason;

    switch (action) {
      case 'start_class':
        allowed = tl.canStart == true;
        if (!allowed) reason = 'Aula não pode ser iniciada neste momento.';
        break;
      case 'confirm_start':
        allowed = tl.canConfirmStart == true;
        if (!allowed)
          reason = 'Confirmação de início indisponível para esta aula.';
        break;
      case 'complete_class':
        allowed = tl.canComplete == true;
        if (!allowed) reason = 'Aula não pode ser finalizada no estado atual.';
        break;
      case 'cancel_class':
        allowed = tl.canCancel == true;
        if (!allowed) reason = 'Aula não pode ser cancelada no estado atual.';
        break;
      case 'report_personal_no_show':
        allowed = tl.canReportPersonalNoShow == true;
        if (!allowed) {
          if (tl.noShowReportDeadline != null) {
            final deadline = DateTime.tryParse(tl.noShowReportDeadline!);
            if (deadline != null) {
              final h = deadline.hour.toString().padLeft(2, '0');
              final m = deadline.minute.toString().padLeft(2, '0');
              reason = 'O reporte de ausência estará disponível a partir das $h:$m (10 minutos após o horário da aula).';
            } else {
              reason = 'O reporte de ausência estará disponível 10 minutos após o horário da aula.';
            }
          } else {
            reason = 'O reporte de ausência estará disponível 10 minutos após o horário da aula.';
          }
        }
        break;
      default:
        allowed = true;
    }

    if (!allowed) {
      // Forçar um refresh leve para garantir consistência visual
      add(const ClassesRefresh());
      emit(
        ClassesOperationFailure(
          classes: _classes,
          timelines: _timelines,
          timers: _timers,
          error: reason ?? 'Ação não permitida.',
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedStatus: _selectedStatus,
          isWebSocketConnected: _ws.isConnected,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _onInitialize(
    ClassesInitialize event,
    Emitter<ClassesState> emit,
  ) async {
    print('🚀 [CLASSES_BLOC] Inicializando ClassesBloc...');

    // Carregar userId do SharedPreferences
    _currentUserId = await _getUserId();
    print('🚀 [CLASSES_BLOC] userId carregado: $_currentUserId');

    // Carregar timer persistente PRIMEIRO
    await _loadPersistentTimer();

    // Iniciar loop de atualização dos timers
    _startTimerUpdateLoop();

    // Emitir estado inicial com timer restaurado (se houver)
    emit(
      ClassesLoaded(
        classes: _classes,
        timelines: Map<String, ClassTimelineDto>.from(_timelines),
        timers: Map<String, ClassTimerState>.from(_timers),
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        selectedStatus: _selectedStatus,
        isWebSocketConnected: _ws.isConnected,
      ),
    );

    print('✅ [CLASSES_BLOC] ClassesBloc inicializado (sem carregar dados)');
  }

  Future<void> _onConnectWs(
    ClassesConnectWebSocket event,
    Emitter<ClassesState> emit,
  ) async {
    print('🔌 [CLASSES_BLOC] Conectando WebSocket...');
    print('🔌 [CLASSES_BLOC] WebSocketService isConnected: ${_ws.isConnected}');

    // Tentar conectar se não estiver conectado E app não estiver em background
    if (!_ws.isConnected) {
      // CRÍTICO: Verificar se app está em background antes de conectar
      if (_ws.isInBackground) {
        print('⏸️ [CLASSES_BLOC] App em background - NÃO conectando WebSocket');
        print('⏸️ [CLASSES_BLOC] App em background - operação bloqueada');
        return; // Não conectar em background
      }

      print('🔌 [CLASSES_BLOC] WebSocket não conectado, tentando conectar...');
      await _ws.connect();
    }

    // Conexão
    _connSub?.cancel();
    _connSub = _ws.connectionStream.listen((connected) {
      print('🔌 [CLASSES_BLOC] WebSocket connection status: $connected');

      if (!isClosed && !emit.isDone) {
        final current = state;
        if (current is ClassesLoaded) {
          emit(current.copyWith(isWebSocketConnected: connected));
        }
      }

      // ✅ CORREÇÃO: Quando reconecta após desconexão, sincronizar aulas ativas
      if (connected && _wasDisconnected) {
        print(
          '🔄 [CLASSES_BLOC] WebSocket reconectado após desconexão - sincronizando aulas ativas...',
        );
        _wasDisconnected = false;
        // Aguardar um momento para garantir que a conexão está estável
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!isClosed) {
            // Sincronizar aulas com timer ativo para recuperar eventos perdidos
            _syncActiveClassesAfterReconnect();
          }
        });
      } else if (!connected) {
        _wasDisconnected = true;
        print('⚠️ [CLASSES_BLOC] WebSocket desconectado');
      }
    });

    // Mensagens
    _wsSub?.cancel();
    _wsSub = _ws.messageStream.listen((message) {
      if (isClosed) return; // Verificar se o BLoC foi fechado

      print(
        '📥 [CLASSES_BLOC] Mensagem WebSocket recebida: ${message['type']}',
      );
      final type = message['type'] as String?;
      if (type == 'class_update') {
        print('✅ [CLASSES_BLOC] Evento class_update detectado, processando...');
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null && !isClosed) {
          add(ClassesUpdateFromWebSocket(data: data));
        } else {
          print(
            '❌ [CLASSES_BLOC] Data é null no evento class_update ou BLoC fechado',
          );
        }
      } else if (type == 'class_created') {
        // Garantir que novas aulas apareçam em tempo real
        print('🆕 [CLASSES_BLOC] Evento class_created detectado');
        final data = message['data'] as Map<String, dynamic>?;
        final classJson = data != null
            ? data['class'] as Map<String, dynamic>?
            : null;
        if (classJson != null && !isClosed) {
          try {
            final created = ClassResponseDto.fromJson(classJson);
            add(ClassesAddClass(classData: created));
          } catch (e) {
            print(
              '⚠️ [CLASSES_BLOC] Erro ao mapear class_created, fazendo refresh: $e',
            );
            add(const ClassesRefresh());
          }
        } else {
          print(
            '⚠️ [CLASSES_BLOC] Payload sem class em class_created, fazendo refresh',
          );
          add(const ClassesRefresh());
        }
      } else if (type == 'class_timer_started') {
        print(
          '🕐 [CLASSES_BLOC] ===== EVENTO class_timer_started DETECTADO =====',
        );
        print('🕐 [CLASSES_BLOC] Mensagem completa: $message');
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null && !isClosed) {
          print(
            '🕐 [CLASSES_BLOC] Data válida, disparando ClassesStartGlobalTimer',
          );
          add(ClassesStartGlobalTimer(data: data));
        } else {
          print(
            '❌ [CLASSES_BLOC] Data é null no evento class_timer_started ou BLoC fechado',
          );
        }
      } else if (type == 'class_timer_expired') {
        print(
          '⏰ [CLASSES_BLOC] ===== EVENTO class_timer_expired DETECTADO =====',
        );
        print('⏰ [CLASSES_BLOC] Mensagem completa: $message');
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null) {
          print('⏰ [CLASSES_BLOC] Data válida: $data');
          print('⏰ [CLASSES_BLOC] ClassId: ${data['classId']}');
          print('⏰ [CLASSES_BLOC] Action: ${data['action']}');

          // Limpar timer local
          final classId = data['classId'] as String;
          _timers.remove(classId);
          _persistentTimer.clearTimer();

          print('⏰ [CLASSES_BLOC] Timer local removido e dados atualizados');
          if (!isClosed) {
            add(const ClassesRefresh());
          } else {
            print(
              '⚠️ [CLASSES_BLOC] Bloc já fechado, não é possível adicionar ClassesRefresh',
            );
          }
        } else {
          print('❌ [CLASSES_BLOC] Data é null no evento class_timer_expired');
        }
      } else if (type == 'match_confirmed') {
        // Garante atualização imediata da lista de aulas após match
        print(
          '🤝 [CLASSES_BLOC] Evento match_confirmed detectado - recarregando aulas',
        );
        if (!isClosed) add(const ClassesRefresh());
      } else if (type == 'rating_created') {
        // Garantir que cards COMPLETED sumam imediatamente após avaliação
        print(
          '⭐ [CLASSES_BLOC] Evento rating_created detectado - recarregando aulas',
        );
        if (!isClosed) add(const ClassesRefresh());
      }
    });

    print('🔌 [CLASSES_BLOC] WebSocket listeners configurados');
    // Se ainda não temos estado carregado, não emite aqui (será emitido após load)
  }

  Future<void> _onDisconnectWs(
    ClassesDisconnectWebSocket event,
    Emitter<ClassesState> emit,
  ) async {
    await _wsSub?.cancel();
    await _connSub?.cancel();
    if (!isClosed) {
      final current = state;
      if (current is ClassesLoaded) {
        emit(current.copyWith(isWebSocketConnected: false));
      }
    }
  }

  Future<void> _onLoad(ClassesLoad event, Emitter<ClassesState> emit) async {
    emit(const ClassesLoading());
    try {
      // ✅ CORREÇÃO: Carregar timer persistente ANTES de criar novos timers
      // Isso garante que timers salvos sejam restaurados mesmo com BLoC factory
      await _loadPersistentTimer();

      // Iniciar loop de atualização se ainda não estiver rodando
      if (_timerUpdateTimer == null || !_timerUpdateTimer!.isActive) {
        _startTimerUpdateLoop();
      }

      // Persistir filtros locais
      _selectedDate = event.filters.date;
      _selectedTime = event.filters.timeRange;

      final response = await _classesApi.getClasses(event.filters);
      final List<dynamic> classesData = response['classes'] ?? [];
      _classes = classesData.map((e) => ClassResponseDto.fromJson(e)).toList();

      // Carregar timelines para cada aula
      _timelines.clear();
      for (final c in _classes) {
        try {
          final tl = await _classesApi.getClassTimeline(c.id);
          _timelines[c.id] = tl;
        } catch (_) {}
      }

      // Buscar fotos dos alunos em paralelo (não bloqueia a UI)
      _loadStudentPhotos(); // Sem emit para evitar loop

      // ✅ CORREÇÃO: Verificar se há aulas ativas que precisam de timer
      // MAS não sobrescrever timers já restaurados do persistente
      for (final classData in _classes) {
        if (classData.status == ClassStatus.ACTIVE &&
            !_timers.containsKey(classData.id)) {
          print(
            '🕐 [CLASSES_BLOC] Iniciando timer para aula ativa: ${classData.id}',
          );
          _timers[classData.id] = ClassTimerState(
            classId: classData.id,
            startTime: classData.startTime ?? DateTime.now(),
            durationMinutes: classData.duration,
            isActive: true,
          );
        }
      }

      // ✅ CORREÇÃO: Verificar se aulas com timer ativo foram finalizadas no servidor
      // Isso recupera eventos perdidos durante desconexão do WebSocket
      final activeTimerClassIds = _timers.entries
          .where((entry) => entry.value.isActive)
          .map((entry) => entry.key)
          .toList();

      for (final classId in activeTimerClassIds) {
        final serverClass = _classes.firstWhere(
          (c) => c.id == classId,
          orElse: () => ClassResponseDto(
            id: classId,
            proposalId: '',
            studentId: '',
            personalId: '',
            location: '',
            date: DateTime.now(),
            time: '',
            duration: 0,
            status: ClassStatus.SCHEDULED,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        if (serverClass.status == ClassStatus.COMPLETED) {
          print(
            '🔄 [CLASSES_BLOC] Aula $classId foi finalizada no servidor durante desconexão',
          );
          // Parar timer local
          final timer = _timers[classId];
          if (timer != null) {
            _timers[classId] = timer.copyWith(
              isActive: false,
              isCompleted: true,
              remainingSeconds: 0,
            );
          }
          // Processar conclusão
          _processClassCompletionForGamification(serverClass);
          // Emitir estado de conclusão via evento
          if (!isClosed) {
            add(
              ClassesUpdateClass(
                classData: serverClass,
                action: 'class_completed',
              ),
            );
          }
        }
      }

      // Aplicar o filtro local de status na lista antes de emitir o estado
      final filteredClasses = _applyLocalStatusFilter(_classes);

      emit(
        ClassesLoaded(
          classes: filteredClasses,
          timelines: Map<String, ClassTimelineDto>.from(_timelines),
          timers: Map<String, ClassTimerState>.from(_timers),
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedStatus: _selectedStatus,
          isWebSocketConnected: true,
        ),
      );
    } catch (e) {
      emit(
        ClassesError(
          message: e.toString(),
          classes: _classes,
          timelines: _timelines,
          timers: _timers,
        ),
      );
    }
  }

  Future<void> _onRefresh(
    ClassesRefresh event,
    Emitter<ClassesState> emit,
  ) async {
    print('🔄 [CLASSES_BLOC] ClassesRefresh chamado - recarregando dados...');
    final filters = GetClassesDto(
      page: 1,
      limit: 50,
      date: _selectedDate,
      timeRange: _selectedTime,
      status: _mapSelectedStatusToApiStatus(),
    );
    add(ClassesLoad(filters: filters));
  }

  Future<void> _onUpdateFilters(
    ClassesUpdateFilters event,
    Emitter<ClassesState> emit,
  ) async {
    _selectedDate = event.selectedDate;
    _selectedTime = event.selectedTime;
    _selectedStatus = event.selectedStatus;
    add(
      ClassesLoad(
        filters: GetClassesDto(
          page: 1,
          limit: 50,
          date: _selectedDate,
          timeRange: _selectedTime,
          status: _mapSelectedStatusToApiStatus(),
        ),
      ),
    );
  }

  Future<void> _onClearFilters(
    ClassesClearFilters event,
    Emitter<ClassesState> emit,
  ) async {
    _selectedDate = null;
    _selectedTime = null;
    _selectedStatus = null;
    add(ClassesLoad(filters: GetClassesDto(page: 1, limit: 50)));
  }

  Future<void> _onUpdateFromWs(
    ClassesUpdateFromWebSocket event,
    Emitter<ClassesState> emit,
  ) async {
    try {
      final classJson = event.data['class'] as Map<String, dynamic>?;
      if (classJson == null) {
        return;
      }

      final updated = ClassResponseDto.fromJson(classJson);

      // SEGURANÇA: Se o ID cacheado for null, tentar carregar uma última vez (auto-recuperação)
      if (_currentUserId == null) {
        _currentUserId = await _getUserId();
      }

      // SEGURANÇA: Ignorar eventos de aulas que não pertencem ao usuário logado
      if (_currentUserId == null ||
          (updated.studentId != _currentUserId &&
              updated.personalId != _currentUserId)) {
        print(
          '🔐 [CLASSES_BLOC] Ignorando evento de WebSocket para aula de outro usuário: ${updated.id}',
        );
        return;
      }

      final action = event.data['action'] as String?;
      print('🔄 [CLASSES_BLOC] Action: $action, ClassJson: $classJson');
      print(
        '🔄 [CLASSES_BLOC] Class atualizada: ${updated.id} - Status: ${updated.status}',
      );

      switch (action) {
        case 'class_created':
          add(ClassesAddClass(classData: updated));
          break;
        case 'class_started':
        case 'class_confirmed':
        case 'class_completed':
        case 'class_completed_by_timer':
        case 'class_cancelled':
        case 'class_no_show_reported':
        case 'class_personal_no_show_reported':
        case 'class_dispute_defense_submitted':
        case 'class_reverted_to_scheduled':
          add(ClassesUpdateClass(classData: updated, action: action!));
          break;
        default:
          if (!isClosed) add(const ClassesRefresh());
          break;
      }
    } catch (e) {
      print('❌ [CLASSES_BLOC] Erro ao processar WebSocket update: $e');
    }
  }

  Future<void> _onAddClass(
    ClassesAddClass event,
    Emitter<ClassesState> emit,
  ) async {
    // SEGURANÇA: Se o ID cacheado for null, tentar carregar uma última vez (auto-recuperação)
    if (_currentUserId == null) {
      _currentUserId = await _getUserId();
    }

    // SEGURANÇA: Verificar se a aula pertence ao usuário antes de adicionar
    if (_currentUserId == null ||
        (event.classData.studentId != _currentUserId &&
            event.classData.personalId != _currentUserId)) {
      print(
        '🔐 [CLASSES_BLOC] Ignorando adição de aula de outro usuário: ${event.classData.id}',
      );
      return;
    }

    // Evitar duplicatas
    final classesCopy = List<ClassResponseDto>.from(_classes);
    final exists = classesCopy.any((c) => c.id == event.classData.id);
    if (!exists) {
      _classes.insert(0, event.classData);
      try {
        final tl = await _classesApi.getClassTimeline(event.classData.id);
        _timelines[event.classData.id] = tl;
      } catch (e) {
        print('⚠️ [CLASSES_BLOC] Erro ao carregar timeline: $e');
      }
    }

    _emitLoaded(emit);
  }

  Future<void> _onUpdateClass(
    ClassesUpdateClass event,
    Emitter<ClassesState> emit,
  ) async {
    final classesCopy = List<ClassResponseDto>.from(_classes);
    final idx = classesCopy.indexWhere((c) => c.id == event.classData.id);

    if (idx == -1) {
      // Se a atualização é para uma aula que não está na lista, pode ser uma aula nova.
      // O evento `class_created` deve ser o principal, mas isso adiciona robustez.
      add(ClassesAddClass(classData: event.classData));
      return;
    }

    if (event.action == 'class_cancelled') {
      _timers.remove(event.classData.id);
      _pendingStartCodes.remove(event.classData.id);
    }

    final current = classesCopy[idx];
    final merged = event.classData;
    final mergedProposalPrice =
        (merged.proposalPrice != null && merged.proposalPrice! > 0)
        ? merged.proposalPrice
        : ((current.proposalPrice != null && current.proposalPrice! > 0)
              ? current.proposalPrice
              : null);
    _classes[idx] = ClassResponseDto(
      id: merged.id,
      proposalId: merged.proposalId,
      studentId: merged.studentId,
      personalId: merged.personalId,
      location: merged.location.isNotEmpty ? merged.location : current.location,
      date: merged.date,
      time: merged.time.isNotEmpty ? merged.time : current.time,
      duration: merged.duration,
      status: merged.status,
      disputeStatus: merged.disputeStatus ?? current.disputeStatus,
      startTime: merged.startTime ?? current.startTime,
      endTime: merged.endTime ?? current.endTime,
      studentFirstName: merged.studentFirstName ?? current.studentFirstName,
      studentLastName: merged.studentLastName ?? current.studentLastName,
      studentEmail: merged.studentEmail ?? current.studentEmail,
      personalFirstName:
          (merged.personalFirstName ?? current.personalFirstName),
      personalLastName: (merged.personalLastName ?? current.personalLastName),
      personalEmail: merged.personalEmail ?? current.personalEmail,
      personalProfileImageUrl:
          merged.personalProfileImageUrl ?? current.personalProfileImageUrl,
      studentProfileImageUrl:
          merged.studentProfileImageUrl ?? current.studentProfileImageUrl,
      personalRating: merged.personalRating ?? current.personalRating,
      personalTimeOnPlatform:
          merged.personalTimeOnPlatform ?? current.personalTimeOnPlatform,
      studentRating: merged.studentRating ?? current.studentRating,
      proposalModality: merged.proposalModality ?? current.proposalModality,
      proposalPrice: mergedProposalPrice,
      paymentStatus: merged.paymentStatus ?? current.paymentStatus,
      noShowReportedBy: merged.noShowReportedBy ?? current.noShowReportedBy,
      noShowReportedAt: merged.noShowReportedAt ?? current.noShowReportedAt,
      evidenceDeadline: merged.evidenceDeadline ?? current.evidenceDeadline,
      custodyExpiresAt: merged.custodyExpiresAt ?? current.custodyExpiresAt,
      studentDefenseText:
          merged.studentDefenseText ?? current.studentDefenseText,
      personalDefenseText:
          merged.personalDefenseText ?? current.personalDefenseText,
      studentDefenseSubmittedAt:
          merged.studentDefenseSubmittedAt ?? current.studentDefenseSubmittedAt,
      personalDefenseSubmittedAt:
          merged.personalDefenseSubmittedAt ??
          current.personalDefenseSubmittedAt,
      studentEvidence: merged.studentEvidence ?? current.studentEvidence,
      personalEvidence: merged.personalEvidence ?? current.personalEvidence,
      createdAt: merged.createdAt,
      updatedAt: merged.updatedAt,
    );

    if (event.action == 'class_confirmed' &&
        merged.status == ClassStatus.ACTIVE) {
      _pendingStartCodes.remove(merged.id);

      if (merged.startTime != null &&
          !_timers.containsKey(event.classData.id)) {
        final startTime = merged.startTime!;
        final durationMs = merged.duration * 60 * 1000;
        final now = DateTime.now();
        final elapsed = now.difference(startTime).inMilliseconds;
        final remainingMs = (durationMs - elapsed).clamp(0, durationMs);
        final remainingSeconds = (remainingMs / 1000).round();

        _timers[event.classData.id] = ClassTimerState(
          classId: event.classData.id,
          startTime: startTime,
          durationMinutes: merged.duration,
          isActive: remainingSeconds > 0,
          remainingSeconds: remainingSeconds,
        );
      }
    }

    if ((event.action == 'class_completed' ||
            event.action == 'class_completed_by_timer') &&
        merged.status == ClassStatus.COMPLETED) {
      add(ClassesStopTimer(classId: event.classData.id));

      emit(
        ClassesCompleteSuccess(
          classes: List<ClassResponseDto>.from(_classes),
          timelines: Map<String, ClassTimelineDto>.from(_timelines),
          timers: Map<String, ClassTimerState>.from(_timers),
          completedClass: _classes[idx],
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedStatus: _selectedStatus,
          isWebSocketConnected: _ws.isConnected,
        ),
      );

      _processClassCompletionForGamification(event.classData);
    }

    await _ensureTimelineFresh(event.classData.id);
    _emitLoaded(emit);
  }

  Future<void> _onUpdateTimeline(
    ClassesUpdateTimeline event,
    Emitter<ClassesState> emit,
  ) async {
    try {
      final tl = await _classesApi.getClassTimeline(event.classId);
      _timelines[event.classId] = tl;
      _emitLoaded(emit);
    } catch (e) {
      if (!isClosed) {
        final current = state;
        if (current is ClassesLoaded) {
          emit(current.copyWith(error: e.toString()));
        }
      }
    }
  }

  Future<void> _onStartClass(
    ClassesStartClass event,
    Emitter<ClassesState> emit,
  ) async {
    emit(
      ClassesOperationInProgress(
        classes: _classes,
        timelines: _timelines,
        timers: _timers,
        operation: 'start_class',
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        selectedStatus: _selectedStatus,
        isWebSocketConnected: _ws.isConnected,
      ),
    );
    try {
      final startResponse = await _classesApi.startClass(
        event.classId,
        event.dto,
      );

      final code = startResponse.startConfirmationCode;
      if (code != null) {
        _pendingStartCodes[event.classId] = code;
      }

      final idx = _classes.indexWhere((c) => c.id == event.classId);
      if (idx != -1) {
        _classes[idx] = startResponse;
      } else {
        _classes.insert(0, startResponse);
      }

      await _ensureTimelineFresh(event.classId);

      emit(
        ClassesStartSuccess(
          classes: List<ClassResponseDto>.from(_classes),
          timelines: Map<String, ClassTimelineDto>.from(_timelines),
          timers: Map<String, ClassTimerState>.from(_timers),
          startedClass: startResponse,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedStatus: _selectedStatus,
          isWebSocketConnected: _ws.isConnected,
          startConfirmationCode: code,
        ),
      );
    } catch (e) {
      emit(
        ClassesOperationFailure(
          classes: _classes,
          timelines: _timelines,
          timers: _timers,
          error: e.toString(),
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedStatus: _selectedStatus,
          isWebSocketConnected: _ws.isConnected,
        ),
      );
    }
  }

  Future<void> _onConfirmStart(
    ClassesConfirmClassStart event,
    Emitter<ClassesState> emit,
  ) async {
    emit(
      ClassesOperationInProgress(
        classes: _classes,
        timelines: _timelines,
        timers: _timers,
        operation: 'confirm_start',
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        selectedStatus: _selectedStatus,
        isWebSocketConnected: _ws.isConnected,
      ),
    );
    try {
      final ok = await _validateAction(
        classId: event.classId,
        action: 'confirm_start',
        emit: emit,
      );
      if (!ok) return;

      await _classesApi.confirmClassStart(event.classId, event.dto);

      add(const ClassesRefresh());
    } catch (e) {
      emit(
        ClassesOperationFailure(
          classes: _classes,
          timelines: _timelines,
          timers: _timers,
          error: e.toString(),
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedStatus: _selectedStatus,
          isWebSocketConnected: _ws.isConnected,
        ),
      );
      // Restaurar estado carregado para evitar loading infinito na tela
      add(const ClassesRefresh());
    }
  }

  Future<void> _onCompleteClass(
    ClassesCompleteClass event,
    Emitter<ClassesState> emit,
  ) async {
    emit(
      ClassesOperationInProgress(
        classes: _classes,
        timelines: _timelines,
        timers: _timers,
        operation: 'complete_class',
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        selectedStatus: _selectedStatus,
        isWebSocketConnected: _ws.isConnected,
      ),
    );
    try {
      final ok = await _validateAction(
        classId: event.classId,
        action: 'complete_class',
        emit: emit,
      );
      if (!ok) return;
      await _classesApi.completeClass(event.classId, event.dto);
      add(const ClassesRefresh());
    } catch (e) {
      emit(
        ClassesOperationFailure(
          classes: _classes,
          timelines: _timelines,
          timers: _timers,
          error: e.toString(),
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedStatus: _selectedStatus,
          isWebSocketConnected: _ws.isConnected,
        ),
      );
    }
  }

  Future<void> _onCancelClass(
    ClassesCancelClass event,
    Emitter<ClassesState> emit,
  ) async {
    emit(
      ClassesOperationInProgress(
        classes: _classes,
        timelines: _timelines,
        timers: _timers,
        operation: 'cancel_class',
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        selectedStatus: _selectedStatus,
        isWebSocketConnected: _ws.isConnected,
      ),
    );
    try {
      final ok = await _validateAction(
        classId: event.classId,
        action: 'cancel_class',
        emit: emit,
      );
      if (!ok) return;
      await _classesApi.cancelClass(event.classId);
      add(const ClassesRefresh());
    } catch (e) {
      emit(
        ClassesOperationFailure(
          classes: _classes,
          timelines: _timelines,
          timers: _timers,
          error: e.toString(),
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedStatus: _selectedStatus,
          isWebSocketConnected: _ws.isConnected,
        ),
      );
    }
  }

  Future<void> _onReportNoShow(
    ClassesReportNoShow event,
    Emitter<ClassesState> emit,
  ) async {
    emit(
      ClassesOperationInProgress(
        classes: _classes,
        timelines: _timelines,
        timers: _timers,
        operation: 'report_no_show',
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        selectedStatus: _selectedStatus,
        isWebSocketConnected: _ws.isConnected,
      ),
    );
    try {
      await _classesApi.reportNoShow(event.classId, event.dto);
      add(const ClassesRefresh());
    } catch (e) {
      emit(
        ClassesOperationFailure(
          classes: _classes,
          timelines: _timelines,
          timers: _timers,
          error: e.toString(),
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedStatus: _selectedStatus,
          isWebSocketConnected: _ws.isConnected,
        ),
      );
    }
  }

  Future<void> _onReportPersonalNoShow(
    ClassesReportPersonalNoShow event,
    Emitter<ClassesState> emit,
  ) async {
    emit(
      ClassesOperationInProgress(
        classes: _classes,
        timelines: _timelines,
        timers: _timers,
        operation: 'report_personal_no_show',
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        selectedStatus: _selectedStatus,
        isWebSocketConnected: _ws.isConnected,
      ),
    );
    try {
      final ok = await _validateAction(
        classId: event.classId,
        action: 'report_personal_no_show',
        emit: emit,
      );
      if (!ok) return;
      await _classesApi.reportPersonalNoShow(event.classId, event.dto);
      add(const ClassesRefresh());
    } catch (e) {
      emit(
        ClassesOperationFailure(
          classes: _classes,
          timelines: _timelines,
          timers: _timers,
          error: e.toString(),
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedStatus: _selectedStatus,
          isWebSocketConnected: _ws.isConnected,
        ),
      );
    }
  }

  void _emitLoaded(Emitter<ClassesState> emit) {
    if (!isClosed) {
      final filteredClasses = _applyLocalStatusFilter(_classes);
      emit(
        ClassesLoaded(
          classes: List<ClassResponseDto>.from(filteredClasses),
          timelines: Map<String, ClassTimelineDto>.from(_timelines),
          timers: Map<String, ClassTimerState>.from(_timers),
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedStatus: _selectedStatus,
          isWebSocketConnected: _ws.isConnected,
        ),
      );
    }
  }

  /// Inicia o loop de atualização dos timers
  void _startTimerUpdateLoop() {
    _timerUpdateTimer?.cancel();
    _timerUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isClosed) {
        add(const ClassesUpdateTimer());
      } else {
        timer.cancel();
      }
    });
  }

  /// Para o loop de atualização dos timers
  void _stopTimerUpdateLoop() {
    _timerUpdateTimer?.cancel();
    _timerUpdateTimer = null;
  }

  /// Processa conclusão de aula para gamificação
  void _processClassCompletionForGamification(ClassResponseDto classData) {
    try {
      print(
        '🎯 [CLASSES_BLOC] Processando conclusão de aula para gamificação - ClassId: ${classData.id}',
      );

      // Obter GamificationBloc do service locator
      final gamificationBloc = sl<GamificationBloc>();

      // Processar para o aluno
      if (classData.studentId.isNotEmpty) {
        print(
          '👨‍🎓 [CLASSES_BLOC] Processando missões para aluno ${classData.studentId}',
        );
        gamificationBloc.add(
          ProcessClassCompletion(
            userId: classData.studentId,
            classId: classData.id,
          ),
        );
      }

      // Processar para o personal
      if (classData.personalId.isNotEmpty) {
        print(
          '👨‍🏫 [CLASSES_BLOC] Processando missões para personal ${classData.personalId}',
        );
        gamificationBloc.add(
          ProcessClassCompletion(
            userId: classData.personalId,
            classId: classData.id,
          ),
        );
      }

      print('✅ [CLASSES_BLOC] Conclusão de aula processada com sucesso');
    } catch (e) {
      print('❌ [CLASSES_BLOC] Erro ao processar conclusão: $e');
    }
  }

  // Gamificação na confirmação removida: missões/XP só na conclusão da aula

  /// Handler para iniciar timer de uma aula
  Future<void> _onStartTimer(
    ClassesStartTimer event,
    Emitter<ClassesState> emit,
  ) async {
    _timers[event.classId] = ClassTimerState(
      classId: event.classId,
      startTime: DateTime.now(),
      durationMinutes: event.durationMinutes,
      isActive: true,
    );

    _emitLoaded(emit);
  }

  /// Handler para parar timer de uma aula
  Future<void> _onStopTimer(
    ClassesStopTimer event,
    Emitter<ClassesState> emit,
  ) async {
    final currentTimer = _timers[event.classId];
    if (currentTimer != null) {
      _timers[event.classId] = currentTimer.copyWith(
        isActive: false,
        isCompleted: true,
      );

      // Limpar timer persistente
      await _persistentTimer.clearTimer();
      print('🛑 [TIMER] Timer finalizado e removido');
    }

    _emitLoaded(emit);
  }

  /// Handler para atualizar timers (chamado periodicamente)
  Future<void> _onUpdateTimer(
    ClassesUpdateTimer event,
    Emitter<ClassesState> emit,
  ) async {
    bool hasChanges = false;
    final now = DateTime.now();

    // Atualizar timers das aulas ativas
    for (final entry in _timers.entries) {
      final timer = entry.value;
      if (timer.isActive && timer.startTime != null) {
        // Calcular tempo restante de forma mais eficiente
        final elapsed = now.difference(timer.startTime!).inSeconds;
        final totalSeconds = timer.durationMinutes * 60;
        final remainingSeconds = (totalSeconds - elapsed).clamp(
          0,
          totalSeconds,
        );

        if (remainingSeconds <= 0) {
          // Timer expirou - chamar API para finalizar aula automaticamente
          _timers[entry.key] = timer.copyWith(
            isActive: false,
            isCompleted: true,
            remainingSeconds: 0,
          );
          hasChanges = true;

          // Chamar API para finalizar aula por expiração do timer
          _completeClassByTimerExpiration(entry.key);
        } else {
          // Atualizar remainingSeconds apenas se mudou
          if (timer.remainingSeconds != remainingSeconds) {
            _timers[entry.key] = timer.copyWith(
              remainingSeconds: remainingSeconds,
            );
            hasChanges = true;
          }
        }
      }
    }

    // 🚀 Recalcular timelines LOCALMENTE (sem API) para atualizar permissões em tempo real
    // Isso permite que botões apareçam/desapareçam automaticamente conforme o tempo passa

    // ✅ CORREÇÃO: Criar cópia da lista antes de iterar para evitar concurrent modification
    // Isso previne o erro quando _classes é modificada (ex: remoção de aula cancelada) durante a iteração
    final classesCopy = List<ClassResponseDto>.from(_classes);
    for (final classData in classesCopy) {
      // Recalcular apenas para aulas que podem ter mudanças de permissão
      if (classData.status == ClassStatus.SCHEDULED ||
          classData.status == ClassStatus.PENDING_CONFIRMATION) {
        // Calcular timeline localmente (sem chamada à API!)
        final newTimeline = ClassTimelineCalculator.calculate(classData);
        final oldTimeline = _timelines[classData.id];

        // Verificar se houve mudança nas permissões
        if (oldTimeline == null ||
            oldTimeline.canReportPersonalNoShow !=
                newTimeline.canReportPersonalNoShow ||
            oldTimeline.canStart != newTimeline.canStart ||
            oldTimeline.canCancel != newTimeline.canCancel ||
            oldTimeline.canConfirmStart != newTimeline.canConfirmStart ||
            oldTimeline.canReportNoShow != newTimeline.canReportNoShow) {
          _timelines[classData.id] = newTimeline;
          hasChanges = true;

          // Log apenas quando há mudanças reais (para debug)
          if (oldTimeline?.canCancel != newTimeline.canCancel) {
            print(
              '🔄 [TIMELINE] canCancel mudou para aula ${classData.id}: ${oldTimeline?.canCancel} → ${newTimeline.canCancel}',
            );
          }
          if (oldTimeline?.canStart != newTimeline.canStart) {
            print(
              '🔄 [TIMELINE] canStart mudou para aula ${classData.id}: ${oldTimeline?.canStart} → ${newTimeline.canStart}',
            );
          }
          if (oldTimeline?.canReportPersonalNoShow !=
              newTimeline.canReportPersonalNoShow) {
            print(
              '🔄 [TIMELINE] canReportPersonalNoShow mudou para aula ${classData.id}: ${oldTimeline?.canReportPersonalNoShow} → ${newTimeline.canReportPersonalNoShow}',
            );
          }
        }
      }
    }

    // Sempre emitir para garantir atualização fluida da UI
    if (hasChanges || _timers.isNotEmpty) {
      _emitLoaded(emit);
    }
  }

  /// Handler para iniciar timer global sincronizado
  Future<void> _onStartGlobalTimer(
    ClassesStartGlobalTimer event,
    Emitter<ClassesState> emit,
  ) async {
    try {
      final data = event.data;
      final classId = data['classId'] as String;
      final startTimeStr = data['startTime'] as String;
      final durationMs = int.tryParse(data['durationMs'].toString()) ?? 0;

      print('🕐 [GLOBAL_TIMER] ===== INICIANDO TIMER GLOBAL =====');
      print('🕐 [GLOBAL_TIMER] ClassId: $classId');
      print('🕐 [GLOBAL_TIMER] StartTime: $startTimeStr');
      print('🕐 [GLOBAL_TIMER] DurationMs: $durationMs');
      print('🕐 [GLOBAL_TIMER] Data completa: $data');

      // Converter timestamp para DateTime
      final startTime = DateTime.parse(startTimeStr);
      final now = DateTime.now();

      // Calcular tempo restante baseado no timestamp
      final elapsed = now.difference(startTime).inMilliseconds;
      final remainingMs = (durationMs - elapsed).clamp(0, durationMs);
      final remainingSeconds = (remainingMs / 1000).round();

      print('🕐 [GLOBAL_TIMER] Tempo restante: ${remainingSeconds}s');

      // Salvar timer persistentemente
      await _persistentTimer.saveTimer(
        classId: classId,
        startTime: startTime,
        durationMs: durationMs,
      );

      // Criar timer global sincronizado
      _timers[classId] = ClassTimerState(
        classId: classId,
        startTime: startTime,
        durationMinutes: durationMs ~/ (60 * 1000),
        isActive: remainingSeconds > 0,
        remainingSeconds: remainingSeconds,
      );

      print('✅ [GLOBAL_TIMER] Timer global criado e salvo');
      _emitLoaded(emit);
    } catch (e) {
      print('❌ [GLOBAL_TIMER] Erro ao iniciar timer global: $e');
    }
  }

  /// Finalizar aula automaticamente quando timer expira
  Future<void> _completeClassByTimerExpiration(String classId) async {
    try {
      print('⏰ [TIMER_EXPIRATION] Timer expirou para aula: $classId');
      print(
        '⏰ [TIMER_EXPIRATION] Chamando API para finalizar aula automaticamente...',
      );

      await _classesApi.completeClassByTimerExpiration(classId);

      // Limpar timer persistente
      await _persistentTimer.clearTimer();

      print(
        '✅ [TIMER_EXPIRATION] Aula finalizada automaticamente por expiração do timer',
      );

      // Recarregar dados para atualizar status da aula
      if (!isClosed) {
        add(const ClassesRefresh());
      }
    } catch (e) {
      print(
        '❌ [TIMER_EXPIRATION] Erro ao finalizar aula por expiração do timer: $e',
      );
    }
  }

  /// Carregar timer persistente ao abrir app
  Future<void> _loadPersistentTimer() async {
    try {
      final timerData = await _persistentTimer.loadTimer();
      if (timerData != null && _persistentTimer.isTimerValid(timerData)) {
        final classId = timerData['classId'] as String;
        final startTime = DateTime.parse(timerData['startTime']);
        final durationMs =
            int.tryParse(timerData['durationMs'].toString()) ?? 0;
        final remainingSeconds = _persistentTimer.calculateRemainingSeconds(
          timerData,
        );

        // Restaurar timer
        _timers[classId] = ClassTimerState(
          classId: classId,
          startTime: startTime,
          durationMinutes: durationMs ~/ (60 * 1000),
          isActive: true,
          remainingSeconds: remainingSeconds,
        );

        print(
          '🔄 [PERSISTENT_TIMER] Timer restaurado: ${remainingSeconds}s restantes',
        );
        // Não emitir aqui pois não temos acesso ao emit fora de um handler
      } else if (timerData != null) {
        // Timer expirou, limpar
        await _persistentTimer.clearTimer();
        print('⏰ [PERSISTENT_TIMER] Timer expirado, removido');
      }
    } catch (e) {
      print('❌ [PERSISTENT_TIMER] Erro ao carregar timer: $e');
    }
  }

  /// Handler para atualizar apenas as fotos dos alunos
  Future<void> _onUpdateStudentPhotos(
    ClassesUpdateStudentPhotos event,
    Emitter<ClassesState> emit,
  ) async {
    await _loadStudentPhotos(emit);
  }

  /// Carrega fotos dos alunos em paralelo
  Future<void> _loadStudentPhotos([Emitter<ClassesState>? emit]) async {
    try {
      print('📸 [CLASSES_BLOC] Iniciando busca de fotos dos alunos...');

      // ✅ CORREÇÃO: Criar cópia da lista antes de iterar para evitar concurrent modification
      final classesCopy = List<ClassResponseDto>.from(_classes);

      // Coletar IDs únicos dos alunos
      final studentIds = classesCopy
          .map((c) => c.studentId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      print(
        '📸 [CLASSES_BLOC] Buscando fotos para ${studentIds.length} alunos únicos',
      );

      // Buscar fotos em paralelo
      final futures = studentIds.map(
        (studentId) => _photoCache.getStudentPhoto(studentId),
      );
      await Future.wait(futures);

      print(
        '📸 [CLASSES_BLOC] Fotos carregadas! Cache size: ${_photoCache.cacheSize}',
      );

      // Emitir estado atualizado com as fotos carregadas apenas se emit foi fornecido
      if (emit != null && state is ClassesLoaded) {
        final filteredClasses = _applyLocalStatusFilter(_classes);
        emit(
          ClassesLoaded(
            classes: List<ClassResponseDto>.from(
              filteredClasses,
            ), // ✅ Usar cópia para evitar referência mutável
            timelines: Map<String, ClassTimelineDto>.from(_timelines),
            timers: Map<String, ClassTimerState>.from(_timers),
            selectedDate: _selectedDate,
            selectedTime: _selectedTime,
            selectedStatus: _selectedStatus,
            isWebSocketConnected: _ws.isConnected,
          ),
        );
      }
    } catch (e) {
      print('❌ [CLASSES_BLOC] Erro ao carregar fotos dos alunos: $e');
      // Não falha o carregamento das aulas se as fotos falharem
    }
  }

  /// Sincroniza aulas ativas após reconexão do WebSocket para recuperar eventos perdidos
  Future<void> _syncActiveClassesAfterReconnect() async {
    if (isClosed) return;

    try {
      print(
        '🔄 [SYNC] Iniciando sincronização de aulas ativas após reconexão...',
      );

      // Identificar aulas com timer ativo
      final activeClassIds = _timers.entries
          .where((entry) => entry.value.isActive)
          .map((entry) => entry.key)
          .toList();

      if (activeClassIds.isEmpty) {
        print('🔄 [SYNC] Nenhuma aula ativa com timer para sincronizar');
        return;
      }

      print(
        '🔄 [SYNC] Sincronizando ${activeClassIds.length} aula(s) ativa(s)...',
      );

      bool hasChanges = false;

      // Buscar status atualizado de cada aula ativa
      for (final classId in activeClassIds) {
        try {
          print('🔄 [SYNC] Verificando status da aula: $classId');
          final updatedClass = await _classesApi.getClassById(classId);

          // Encontrar índice da aula na lista local
          // ✅ CORREÇÃO: Criar cópia antes de usar indexWhere para evitar concurrent modification
          final classesCopy = List<ClassResponseDto>.from(_classes);
          final localIndex = classesCopy.indexWhere((c) => c.id == classId);

          if (localIndex == -1) {
            print('⚠️ [SYNC] Aula $classId não encontrada na lista local');
            continue;
          }

          final localClass = _classes[localIndex];

          // Se o status mudou para COMPLETED no servidor, atualizar localmente
          if (updatedClass.status == ClassStatus.COMPLETED &&
              localClass.status != ClassStatus.COMPLETED) {
            print(
              '🔄 [SYNC] Aula $classId foi finalizada no servidor - atualizando estado local',
            );

            // Atualizar classe local
            _classes[localIndex] = updatedClass;

            // Parar timer
            final timer = _timers[classId];
            if (timer != null) {
              _timers[classId] = timer.copyWith(
                isActive: false,
                isCompleted: true,
                remainingSeconds: 0,
              );
            }

            // Limpar timer persistente
            await _persistentTimer.clearTimer();

            // Atualizar timeline
            try {
              final tl = await _classesApi.getClassTimeline(classId);
              _timelines[classId] = tl;
            } catch (_) {}

            // Processar conclusão para gamificação
            _processClassCompletionForGamification(updatedClass);

            hasChanges = true;
            print(
              '✅ [SYNC] Aula $classId sincronizada e finalizada localmente',
            );

            // Emitir estado de conclusão via evento (não pode emitir diretamente aqui)
            if (!isClosed) {
              add(
                ClassesUpdateClass(
                  classData: updatedClass,
                  action: 'class_completed',
                ),
              );
            }
          } else if (updatedClass.status == ClassStatus.ACTIVE &&
              localClass.status == ClassStatus.ACTIVE) {
            // Aula ainda está ativa - sincronizar dados se necessário
            if (updatedClass.startTime != localClass.startTime) {
              print(
                '🔄 [SYNC] Aula $classId tem startTime diferente - atualizando timer',
              );

              // Atualizar classe local
              _classes[localIndex] = updatedClass;

              // Atualizar timer se startTime mudou
              final timer = _timers[classId];
              if (timer != null && updatedClass.startTime != null) {
                final startTime = updatedClass.startTime!;
                final durationMs = updatedClass.duration * 60 * 1000;
                final now = DateTime.now();
                final elapsed = now.difference(startTime).inMilliseconds;
                final remainingMs = (durationMs - elapsed).clamp(0, durationMs);
                final remainingSeconds = (remainingMs / 1000).round();

                _timers[classId] = ClassTimerState(
                  classId: classId,
                  startTime: startTime,
                  durationMinutes: updatedClass.duration,
                  isActive: remainingSeconds > 0,
                  remainingSeconds: remainingSeconds,
                );

                // Salvar timer persistente atualizado
                await _persistentTimer.saveTimer(
                  classId: classId,
                  startTime: startTime,
                  durationMs: durationMs,
                );
              }

              hasChanges = true;
              print('✅ [SYNC] Timer da aula $classId sincronizado');
            }
          }
        } catch (e) {
          print('❌ [SYNC] Erro ao sincronizar aula $classId: $e');
          // Continuar com outras aulas mesmo se uma falhar
        }
      }

      // Se houve mudanças, fazer refresh para atualizar estado
      if (hasChanges && !isClosed) {
        print('🔄 [SYNC] Mudanças detectadas - fazendo refresh do estado');
        add(const ClassesRefresh());
      }

      print('✅ [SYNC] Sincronização concluída');
    } catch (e) {
      print('❌ [SYNC] Erro geral na sincronização: $e');
    }
  }

  /// Handler para envio de defesa em disputa de no-show
  Future<void> _onSubmitDisputeDefense(
    ClassesSubmitDisputeDefense event,
    Emitter<ClassesState> emit,
  ) async {
    emit(
      ClassesOperationInProgress(
        classes: _classes,
        timelines: _timelines,
        timers: _timers,
        operation: 'submit_dispute_defense',
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        selectedStatus: _selectedStatus,
        isWebSocketConnected: _ws.isConnected,
      ),
    );

    try {
      final updatedClass = await _classesApi.submitDisputeDefense(
        event.classId,
        event.text,
        evidenceUrls: event.evidenceUrls,
      );

      // Atualizar aula local com a resposta do backend
      final idx = _classes.indexWhere((c) => c.id == event.classId);
      if (idx != -1) {
        _classes[idx] = updatedClass;
      }

      emit(
        ClassesOperationSuccess(
          classes: List<ClassResponseDto>.from(_classes),
          timelines: Map<String, ClassTimelineDto>.from(_timelines),
          timers: Map<String, ClassTimerState>.from(_timers),
          message: 'Defesa enviada com sucesso!',
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedStatus: _selectedStatus,
          isWebSocketConnected: _ws.isConnected,
        ),
      );

      // Voltar ao estado loaded normal
      _emitLoaded(emit);
    } catch (e) {
      print('❌ [CLASSES_BLOC] Erro ao enviar defesa: $e');
      emit(
        ClassesOperationFailure(
          classes: _classes,
          timelines: _timelines,
          timers: _timers,
          error: 'Erro ao enviar defesa: $e',
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedStatus: _selectedStatus,
          isWebSocketConnected: _ws.isConnected,
        ),
      );
    }
  }

  /// Reseta o estado do ClassesBloc (usado no logout)
  Future<void> _onReset(ClassesReset event, Emitter<ClassesState> emit) async {
    print('🔄 [CLASSES_BLOC] Resetando estado...');

    // Limpar dados locais
    _classes.clear();
    _timelines.clear();
    _timers.clear();
    _currentUserId = null;
    _selectedDate = null;
    _selectedTime = null;
    _selectedStatus = null;

    // Parar timers
    _stopTimerUpdateLoop();

    // Desconectar WebSocket
    await _wsSub?.cancel();
    await _connSub?.cancel();
    _wsSub = null;
    _connSub = null;

    // Voltar ao estado inicial
    emit(const ClassesInitial());

    print('✅ [CLASSES_BLOC] Estado resetado com sucesso');
  }

  @override
  Future<void> close() async {
    _stopTimerUpdateLoop();
    await _wsSub?.cancel();
    await _connSub?.cancel();
    return super.close();
  }
}
