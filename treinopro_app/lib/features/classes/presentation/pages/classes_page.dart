import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/usecases/upload_usecase.dart';
import '../../data/models/report_no_show_dto.dart';
import '../widgets/class_timer_widget.dart';
import '../../data/models/class_response_dto.dart';
import '../../data/models/class_timeline_dto.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../chat/presentation/pages/conversations_list_page.dart';
import '../../../evaluation/presentation/pages/class_evaluation_page.dart';
import 'personal_class_tracking_page.dart';
import '../bloc/classes_bloc.dart';
import '../widgets/report_no_show_modal.dart';
import '../widgets/dispute_defense_modal.dart';
import '../../data/models/start_class_dto.dart';
import '../../../health_questionnaire/health_questionnaire.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_state.dart' as home_states;
import '../../../../core/services/class_presence_snapshot_service.dart';
import '../utils/class_dispute_status_helper.dart';

class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Usar o ClassesBloc já existente do contexto pai
    return BlocBuilder<ClassesBloc, ClassesState>(
      builder: (context, state) {
        return _ClassesPageView(state: state);
      },
    );
  }
}

class _ClassesPageView extends StatefulWidget {
  final ClassesState state;

  const _ClassesPageView({required this.state});

  @override
  State<_ClassesPageView> createState() => _ClassesPageViewState();
}

class _ClassesPageViewState extends State<_ClassesPageView> {
  // Filtros
  String? _selectedDate = 'Hoje';
  String? _selectedTime;
  String? _selectedStatus;
  // ✅ Proteção contra navegação múltipla para tracking
  bool _hasNavigatedToTracking = false;

  // Valores para os filtros de aulas
  final List<String> _dates = [
    'Todos',
    'Hoje',
    'Amanhã',
    'Essa semana',
    'Esse mês',
  ];

  final List<String> _times = [
    'Manhã (06:00-12:00)',
    'Tarde (12:00-18:00)',
    'Noite (18:00-23:00)',
  ];

  final List<String> _statuses = [
    'Aula futura',
    'Aula concluída',
    'Aula em disputa',
  ];

  @override
  void initState() {
    super.initState();
    // Timer removido - ClassesBloc já gerencia isso

    // Inicializar o ClassesBloc quando a página for carregada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final classesBloc = context.read<ClassesBloc>();
      if (classesBloc.state is ClassesInitial) {
        print('🚀 [CLASSES] Inicializando ClassesBloc...');
        classesBloc.add(const ClassesInitialize());
      }

      print('📚 [CLASSES] Aplicando filtros padrão da aba treino...');
      classesBloc.add(
        ClassesUpdateFilters(
          selectedDate: _getDateFilter(),
          selectedTime: _getTimeRangeFilter(),
          selectedStatus: _selectedStatus,
        ),
      );
    });
  }

  @override
  void dispose() {
    // Timer removido - ClassesBloc já gerencia isso
    super.dispose();
  }

  /// Retorna mensagem amigável para operações em andamento
  String _getOperationMessage(String operation) {
    switch (operation) {
      case 'start_class':
        return 'Iniciando aula...';
      case 'confirm_start':
        return 'Confirmando início da aula...';
      case 'complete_class':
        return 'Finalizando aula...';
      case 'cancel_class':
        return 'Cancelando aula...';
      case 'report_no_show':
        return 'Reportando ausência...';
      case 'report_personal_no_show':
        return 'Reportando ausência do personal...';
      default:
        return 'Processando...';
    }
  }

  /// Verifica se a aula pode ser avaliada (dentro de 24 horas)
  bool _canEvaluateClass(DateTime? completedAt) {
    if (completedAt == null) return false;

    final now = DateTime.now();
    final difference = now.difference(completedAt);
    final hoursElapsed = difference.inHours;

    return hoursElapsed < 24;
  }

  /// Aplica filtros e ordenação nas classes
  List<ClassResponseDto> _getFilteredClasses(List<ClassResponseDto> classes) {
    List<ClassResponseDto> filtered = List.from(classes);

    filtered = filtered.where((classData) {
      if (_matchesSelectedStatusFilter(classData)) {
        return true;
      }
      return _selectedStatus == null && _isVisibleByDefault(classData);
    }).toList();

    if (_selectedDate != null && _selectedDate != 'Todos') {
      filtered = filtered.where(_matchesSelectedDateFilter).toList();
    }

    // Aplicar filtro de horário
    if (_selectedTime != null) {
      filtered = filtered.where((classData) {
        final time = classData.time;

        // Extrair hora do formato "HH:MM"
        final hour = int.tryParse(time.split(':')[0]) ?? 0;

        switch (_selectedTime) {
          case 'Manhã (06:00-12:00)':
            return hour >= 6 && hour < 12;
          case 'Tarde (12:00-18:00)':
            return hour >= 12 && hour < 18;
          case 'Noite (18:00-23:00)':
            return hour >= 18 && hour <= 23;
          default:
            return true;
        }
      }).toList();
    }

    // Ordenar por prioridade de status
    // 1) ACTIVE
    // 2) PENDING_CONFIRMATION
    // 3) SCHEDULED
    // 4) COMPLETED
    // 5) CUSTODY
    // 6) CANCELLED
    // 7) NO_SHOW_DISPUTE (reportadas) -> sempre por último
    int sortWeight(ClassResponseDto c) {
      switch (c.status) {
        case ClassStatus.ACTIVE:
          return 0;
        case ClassStatus.PENDING_CONFIRMATION:
          return 1;
        case ClassStatus.SCHEDULED:
          return 2;
        case ClassStatus.COMPLETED:
          return 3;
        case ClassStatus.CUSTODY:
          return 4;
        case ClassStatus.CANCELLED:
          return 5;
        case ClassStatus.NO_SHOW_DISPUTE:
          return 6; // reportadas no final
      }
    }

    filtered.sort((a, b) {
      final wa = sortWeight(a);
      final wb = sortWeight(b);
      if (wa != wb) return wa.compareTo(wb);

      // Desempate por data de treino (mais próxima primeiro - hoje para futuro)
      final dateCmp = a.date.compareTo(b.date);
      if (dateCmp != 0) return dateCmp;

      // Desempate por horário (mais próximo primeiro)
      final timeCmp = a.time.compareTo(b.time);
      if (timeCmp != 0) return timeCmp;

      // Último desempate por data de atualização
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return filtered;
  }

  void _startClass(String classId) {
    final dto = StartClassDto(notes: 'Aula iniciada pelo personal trainer');
    context.read<ClassesBloc>().add(
      ClassesStartClass(classId: classId, dto: dto),
    );
  }

  void _cancelClass(String classId) {
    context.read<ClassesBloc>().add(ClassesCancelClass(classId: classId));
  }

  Future<void> _reportStudentNoShow(
    ClassResponseDto classData,
    ClassTimelineDto timeline,
    Map<String, dynamic> reportData,
  ) async {
    try {
      print('🔍 [REPORT] Iniciando reporte de ausência do aluno');
      print('🔍 [REPORT] classId: ${classData.id}');
      print('🔍 [REPORT] reportData: $reportData');

      // Tentar capturar presença síncrona se ainda não houver
      if (!timeline.hasPresenceSnapshot) {
        print(
          '⏳ [REPORT] Snapshot de presença ausente. Tentando capturar forçadamente agora...',
        );
        final captured = await ClassPresenceSnapshotService.instance.captureNow(
          classId: classData.id,
          userId: classData.personalId, // Quem está reportando é o personal
          role: 'personal',
        );
        if (!captured && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Aviso: Não foi possível obter sua localização exata para o registro.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Fazer upload das imagens primeiro
      List<String> evidenceUrls = [];
      final evidenceImages = reportData['evidenceImages'] as List<String>?;

      print('🔍 [REPORT] evidenceImages: $evidenceImages');

      if (evidenceImages != null && evidenceImages.isNotEmpty) {
        for (final imagePath in evidenceImages) {
          try {
            print('🔍 [REPORT] Fazendo upload da imagem: $imagePath');
            final file = File(imagePath);
            if (await file.exists()) {
              print('🔍 [REPORT] Arquivo existe, fazendo upload...');

              final uploadResponse = await sl<UploadUseCase>()
                  .uploadDisputeEvidence(
                    file: file,
                    classId: classData.id,
                    description: 'Evidência de ausência do aluno',
                  );

              print('🔍 [REPORT] Upload concluído: ${uploadResponse.url}');
              evidenceUrls.add(uploadResponse.url);
            } else {
              print('❌ [REPORT] Arquivo não existe: $imagePath');
            }
          } catch (e) {
            print('❌ [REPORT] Erro no upload da imagem $imagePath: $e');
          }
        }
      }

      // Criar DTO de reporte
      final dto = ReportNoShowDto(
        reason: reportData['reason'] as String? ?? 'Aluno não compareceu',
        evidenceUrls: evidenceUrls,
        notes: reportData['additionalNotes'] as String?,
      );

      print('🔍 [REPORT] DTO criado: ${dto.toJson()}');

      // Enviar reporte via Bloc
      context.read<ClassesBloc>().add(
        ClassesReportNoShow(classId: classData.id, dto: dto),
      );

      // Mostrar feedback de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte enviado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ [REPORT] Erro ao reportar ausência do aluno: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reportar ausência do aluno: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReportStudentNoShowModal(
    ClassResponseDto classData,
    ClassTimelineDto? timeline,
  ) {
    if (timeline == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportNoShowModal(
        classData: classData,
        timeline: timeline,
        isPersonalNoShow: false, // Personal reporta ausência do aluno
        onReport: (reportData) {
          _reportStudentNoShow(classData, timeline, reportData);
        },
      ),
    );
  }

  void _updateFilters() {
    context.read<ClassesBloc>().add(
      ClassesUpdateFilters(
        selectedDate: _getDateFilter(),
        selectedTime: _getTimeRangeFilter(),
        selectedStatus: _getStatusFilter(),
      ),
    );
  }

  /// Converte filtro de data do chip para formato da API
  String? _getDateFilter() {
    if (_selectedDate == null) return null;

    // O backend tem apresentado inconsistência ao receber datas relativas
    // (ex.: "Hoje"), então o filtro de calendário fica 100% local na UI.
    print(
      '🔍 [PERSONAL_FILTERS] Filtro de data selecionado: $_selectedDate -> filtro aplicado apenas localmente',
    );
    return null;
  }

  /// Converte filtro de horário do chip para formato da API
  String? _getTimeRangeFilter() {
    if (_selectedTime == null) return null;

    String? result;

    switch (_selectedTime) {
      case 'Manhã (06:00-12:00)':
        result = 'morning';
        break;
      case 'Tarde (12:00-18:00)':
        result = 'afternoon';
        break;
      case 'Noite (18:00-23:00)':
        result = 'evening';
        break;
      default:
        result = null;
    }

    print(
      '🔍 [PERSONAL_FILTERS] Filtro de horário selecionado: $_selectedTime',
    );
    print('🔍 [PERSONAL_FILTERS] Filtro de horário convertido: $result');
    return result;
  }

  String? _getStatusFilter() {
    if (_selectedStatus == null) return null;

    print(
      '🔍 [PERSONAL_FILTERS] Filtro de status selecionado: $_selectedStatus',
    );
    return _selectedStatus;
  }

  void _navigateToChat(ClassResponseDto classData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          classId: classData.id,
          receiverId: classData.studentId,
          receiverName: _formatName(classData.studentName),
          location: classData.location,
          date: _formatDate(classData.date),
          time: classData.time,
          duration: '${classData.duration}min',
          currentUserIsStudent: false, // Personal trainer
        ),
      ),
    );
  }

  /// Agenda snapshots de geolocalização para aulas agendadas do personal
  void _schedulePresenceSnapshots(
    BuildContext ctx,
    List<ClassResponseDto> classes,
  ) {
    String? userId;
    try {
      final homeState = ctx.read<HomeBloc>().state;
      if (homeState is home_states.HomeLoaded) {
        userId = homeState.homeState.userId;
      }
    } catch (_) {}

    if (userId == null || userId.isEmpty) return;

    for (final classData in classes) {
      if (classData.status != ClassStatus.SCHEDULED &&
          classData.status != ClassStatus.PENDING_CONFIRMATION)
        continue;
      if (classData.personalId != userId) continue;

      // Calcular T0 a partir de date + time ("HH:MM")
      DateTime? t0;
      try {
        final parts = classData.time.split(':');
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        t0 = DateTime(
          classData.date.year,
          classData.date.month,
          classData.date.day,
          h,
          m,
        );
      } catch (_) {}

      if (t0 == null) continue;
      // Ignorar aulas passadas há mais de 24h
      if (DateTime.now().difference(t0).inHours > 24) continue;

      ClassPresenceSnapshotService.instance.scheduleSnapshot(
        classId: classData.id,
        userId: userId,
        role: 'personal',
        scheduledAt: t0,
      );
    }
  }

  void _navigateToTracking(
    ClassResponseDto classData, {
    String? startConfirmationCode,
    Map<String, ClassTimelineDto>? timelines,
  }) {
    // ✅ Prevenir navegação múltipla
    if (_hasNavigatedToTracking) {
      print('⚠️ [CLASSES] Navegação para tracking já realizada, ignorando...');
      return;
    }

    _hasNavigatedToTracking = true;

    // Obter minimumCompletionAt do timeline (se disponível)
    final tl = timelines?[classData.id];
    final minimumCompletionAt = tl?.minimumCompletionAt?.toIso8601String();

    // ✅ CORREÇÃO: Passar a mesma instância do ClassesBloc conectada ao WebSocket
    final classesBloc = context.read<ClassesBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: classesBloc,
          child: PersonalClassTrackingPage(
            aula: {
              'id': classData.id,
              'studentName': _formatName(classData.studentName),
              'personalName': classData.personalName,
              'location': classData.location,
              'date': _formatDate(classData.date),
              'time': classData.time,
              'duration': '${classData.duration}min',
              'durationMinutes': classData.duration,
              if (classData.proposalPrice != null)
                'proposalPrice': classData.proposalPrice,
              // Campos críticos para lógica de confirmação e 45min
              if (startConfirmationCode != null)
                'startConfirmationCode': startConfirmationCode,
              if (classData.startTime != null)
                'startedAt': classData.startTime!.toIso8601String(),
              if (minimumCompletionAt != null)
                'minimumCompletionAt': minimumCompletionAt,
            },
          ),
        ),
      ),
    );
  }

  void _showStudentHealthModal(ClassResponseDto classData) {
    // ✅ Debug: Log do studentRating antes de exibir
    print(
      '⭐ [CLASSES_PAGE] studentRating antes de exibir modal: ${classData.studentRating}',
    );
    print(
      '⭐ [CLASSES_PAGE] studentScore calculado: ${(classData.studentRating ?? 0.0).round()}',
    );

    showDialog(
      context: context,
      builder: (context) => StudentHealthModal(
        studentId: classData.studentId,
        studentName: _formatName(classData.studentName),
        studentProfileImage: '', // TODO: Adicionar campo no backend
        studentScore: (classData.studentRating ?? 0.0).round(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final classDate = DateTime(date.year, date.month, date.day);

    if (classDate == today) {
      return 'Hoje';
    } else if (classDate == today.add(const Duration(days: 1))) {
      return 'Amanhã';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    }
  }

  bool _matchesSelectedDateFilter(ClassResponseDto classData) {
    final selectedDate = _selectedDate;
    if (selectedDate == null || selectedDate == 'Todos') {
      return true;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final classDay = DateTime(
      classData.date.year,
      classData.date.month,
      classData.date.day,
    );

    switch (selectedDate) {
      case 'Hoje':
        return classDay == today;
      case 'Amanhã':
        return classDay == today.add(const Duration(days: 1));
      case 'Essa semana':
        final startOfWeek = today.subtract(
          Duration(days: today.weekday - DateTime.monday),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return !classDay.isBefore(startOfWeek) && !classDay.isAfter(endOfWeek);
      case 'Esse mês':
        return classDay.year == today.year && classDay.month == today.month;
      default:
        return true;
    }
  }

  bool _matchesSelectedStatusFilter(ClassResponseDto classData) {
    switch (_selectedStatus) {
      case 'Aula futura':
        return classData.status == ClassStatus.SCHEDULED ||
            classData.status == ClassStatus.ACTIVE ||
            classData.status == ClassStatus.PENDING_CONFIRMATION ||
            classData.status == ClassStatus.CUSTODY;
      case 'Aula concluída':
        return classData.status == ClassStatus.COMPLETED;
      case 'Aula cancelada':
        return classData.status == ClassStatus.CANCELLED &&
            !_isFutureScheduledClass(classData);
      case 'Aula em disputa':
        return classData.status == ClassStatus.NO_SHOW_DISPUTE ||
            classData.status == ClassStatus.CUSTODY;
      default:
        return false;
    }
  }

  bool _isVisibleByDefault(ClassResponseDto classData) {
    if (classData.noShowReportedAt != null) {
      return true;
    }

    if (classData.status == ClassStatus.CANCELLED) {
      return false;
    }

    return true;
  }

  bool _isFutureScheduledClass(ClassResponseDto classData) {
    final parts = classData.time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final scheduledDateTime = DateTime(
      classData.date.year,
      classData.date.month,
      classData.date.day,
      hour,
      minute,
    );

    return scheduledDateTime.isAfter(DateTime.now());
  }

  String _formatClassPrice(double? price) {
    final classPrice = price ?? 0.0;
    return 'R\$ ${classPrice.toStringAsFixed(0)}';
  }

  Widget _buildModalityAndPrice(
    ClassResponseDto classData, {
    required Color accentColor,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    final modality = classData.proposalModality?.trim();
    final price = classData.proposalPrice;
    final hasModality = modality != null && modality.isNotEmpty;
    final hasPrice = price != null && price > 0;

    if (!hasModality && !hasPrice) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (hasModality)
          Container(
            constraints: const BoxConstraints(maxWidth: double.infinity),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              modality!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: accentColor,
              ),
            ),
          ),
        if (hasPrice) ...[
          if (hasModality) const SizedBox(height: 6),
          Align(
            alignment: crossAxisAlignment == CrossAxisAlignment.end
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor.withValues(alpha: 0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payments_outlined, size: 14, color: accentColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Valor ${_formatClassPrice(price)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatName(String name) {
    // Usuário sem nome = conta excluída (hard delete). Mantém um rótulo claro
    // em vez de um card "quebrado".
    if (name.trim().isEmpty) return 'Usuário removido';

    return name
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  /// Cria avatar com iniciais do nome do aluno ou foto se disponível
  Widget _buildStudentInitialsAvatar(String studentName, {String? photoUrl}) {
    // Conta excluída (sem nome): mostra um ícone neutro em vez de "?".
    final isRemoved = studentName.trim().isEmpty;
    final initials = _getStudentInitials(studentName);

    final fallback = isRemoved
        ? const Icon(
            Icons.person_off_outlined,
            color: AppColors.primaryOrange,
            size: 24,
          )
        : _buildInitialsText(initials);

    return Container(
      width: 47,
      height: 47,
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(23.5),
      ),
      child: photoUrl != null && photoUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(23.5),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
            )
          : fallback,
    );
  }

  /// Cria o texto das iniciais
  Widget _buildInitialsText(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontFamily: 'Fira Sans',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryOrange,
        ),
      ),
    );
  }

  /// Extrai iniciais do nome do aluno
  String _getStudentInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';

    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else {
      return '${words[0][0].toUpperCase()}${words[1][0].toUpperCase()}';
    }
  }

  /// Widget assíncrono que busca e exibe a foto do aluno
  Widget _buildStudentAvatar(ClassResponseDto classData) {
    return FutureBuilder<String?>(
      future: classData.studentPhotoUrl,
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(21.5),
            child: Image.network(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildStudentInitialsAvatar(classData.studentName),
            ),
          );
        }

        return _buildStudentInitialsAvatar(classData.studentName);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClassesBloc, ClassesState>(
      listener: (context, state) {
        if (state is ClassesOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ClassesStartSuccess) {
          // Navegar automaticamente para a tela de tracking após iniciar a aula
          _navigateToTracking(
            state.startedClass,
            startConfirmationCode: state.startConfirmationCode,
            timelines: state.timelines,
          );
        } else if (state is ClassesLoaded) {
          // ✅ Resetar flag quando estado voltar para ClassesLoaded (após navegação)
          _hasNavigatedToTracking = false;
          // ✅ Agendar snapshots de geolocalização para aulas agendadas
          _schedulePresenceSnapshots(context, state.classes);
        } else if (state is ClassesOperationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },
      child: BlocBuilder<ClassesBloc, ClassesState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFFCFDFE),
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<ClassesBloc>().add(const ClassesRefresh());
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 20,
                    bottom: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const Text(
                            'Minhas aulas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              tooltip: 'Mensagens',
                              onPressed: () => openConversationsList(context),
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildFilterSection(),
                      const SizedBox(height: 16),
                      _buildContent(state),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtros',
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              if (_hasActiveFilters())
                GestureDetector(
                  onTap: _clearAllFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.clear_rounded,
                          size: 14,
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Limpar',
                          style: TextStyle(
                            fontFamily: 'Fira Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  'Data',
                  _selectedDate,
                  _dates,
                  Icons.calendar_today_rounded,
                  (value) => setState(() => _selectedDate = value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'Horário',
                  _selectedTime,
                  _times,
                  Icons.access_time_rounded,
                  (value) => setState(() => _selectedTime = value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'Status',
                  _selectedStatus,
                  _statuses,
                  Icons.info_outline_rounded,
                  (value) => setState(() => _selectedStatus = value),
                ),
              ),
            ],
          ),
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedDate != null && _selectedDate != 'Hoje')
                  _buildActiveFilterTag('Data', _selectedDate!, () {
                    setState(() => _selectedDate = 'Hoje');
                    _updateFilters();
                  }),
                if (_selectedTime != null)
                  _buildActiveFilterTag(
                    'Horário',
                    _getTimeDisplayName(_selectedTime),
                    () {
                      setState(() => _selectedTime = null);
                      _updateFilters();
                    },
                  ),
                if (_selectedStatus != null)
                  _buildActiveFilterTag('Status', _selectedStatus!, () {
                    setState(() => _selectedStatus = null);
                    _updateFilters();
                  }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(ClassesState state) {
    if (state is ClassesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ClassesOperationInProgress) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _getOperationMessage(state.operation),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    // Em caso de falha de operação (ex.: 400 ao iniciar aula), renderizar a lista atual
    // para evitar spinner infinito e manter a UX consistente
    if (state is ClassesOperationFailure) {
      final filteredClasses = _getFilteredClasses(state.classes);

      if (filteredClasses.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_note, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Nenhuma aula encontrada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ajuste os filtros ou aguarde novas aulas',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      }

      return Column(
        children: filteredClasses
            .map(
              (classData) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildClassCard(classData, state.timelines),
              ),
            )
            .toList(),
      );
    }

    if (state is ClassesError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar aulas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.red.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<ClassesBloc>().add(const ClassesRefresh()),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (state is! ClassesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredClasses = _getFilteredClasses(state.classes);

    if (filteredClasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nenhuma aula encontrada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajuste os filtros ou aguarde novas aulas',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: filteredClasses
          .map(
            (classData) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildClassCard(classData, state.timelines),
            ),
          )
          .toList(),
    );
  }

  Widget _buildClassCard(
    ClassResponseDto classData,
    Map<String, ClassTimelineDto> timelines,
  ) {
    final timeline = timelines[classData.id];

    if (classData.noShowReportedAt != null) {
      return _buildDisputeClassCard(classData, timeline);
    }

    switch (classData.status) {
      case ClassStatus.ACTIVE:
        return _buildActiveClassCard(classData, timeline);
      case ClassStatus.PENDING_CONFIRMATION:
        return _buildPendingConfirmationClassCard(classData, timeline);
      case ClassStatus.SCHEDULED:
        return _buildScheduledClassCard(classData, timeline);
      case ClassStatus.COMPLETED:
        return _buildCompletedClassCard(classData, timeline);
      default:
        return _buildScheduledClassCard(classData, timeline);
    }
  }

  Widget _buildActiveClassCard(
    ClassResponseDto classData,
    ClassTimelineDto? timeline,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryOrange, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showStudentHealthModal(classData),
                child: Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(23.5),
                    border: Border.all(
                      color: AppColors.primaryOrange,
                      width: 2,
                    ),
                    color: const Color(0xFFF3F3F3),
                  ),
                  child: _buildStudentAvatar(classData),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatName(classData.studentName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 22,
                          color: Color(0xFF42464D),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            classData.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Fira Sans',
                              fontSize: 12,
                              color: Color(0xFF42464D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((classData.proposalModality ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildModalityAndPrice(
                        classData,
                        accentColor: AppColors.primaryOrange,
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: ClassTimerWidget(
                    classId: classData.id,
                    showSeconds: false,
                    suffix: 'm',
                    textStyle: const TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFA6A6A6)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                Icons.calendar_today,
                'Data',
                _formatDate(classData.date),
              ),
              _buildInfoItem(Icons.access_time, 'Horário', classData.time),
              _buildInfoItem(
                Icons.timer,
                'Duração',
                '${classData.duration}min',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _navigateToTracking(classData),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(
                      color: AppColors.primaryOrange,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Acompanhar aula',
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 16,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ),
              // Botão "Finalizar aula" removido para o card do personal
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledClassCard(
    ClassResponseDto classData,
    ClassTimelineDto? timeline,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showStudentHealthModal(classData),
                child: Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(23.5),
                    border: Border.all(color: Colors.blue.shade400, width: 2),
                    color: Colors.blue.shade100,
                  ),
                  child: _buildStudentAvatar(classData),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatName(classData.studentName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 22,
                          color: Color(0xFF42464D),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            classData.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Fira Sans',
                              fontSize: 12,
                              color: Color(0xFF42464D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((classData.proposalModality ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildModalityAndPrice(
                        classData,
                        accentColor: Colors.blue.shade700,
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFA6A6A6)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                Icons.calendar_today,
                'Data',
                _formatDate(classData.date),
              ),
              _buildInfoItem(Icons.access_time, 'Horário', classData.time),
              _buildInfoItem(
                Icons.timer,
                'Duração',
                '${classData.duration}min',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aula futura agendada.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Botão Personal não compareceu (se permitido) - esquerda
              if (timeline?.canReportPersonalNoShow == true) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _showReportStudentNoShowModal(classData, timeline),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Reportar'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Botão Cancelar aula (se permitido)
              if (timeline?.canCancel == true) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _cancelClass(classData.id),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primaryOrange,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Botão Iniciar aula (somente se permitido)
              if (timeline?.canStart == true) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _startClass(classData.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Iniciar aula',
                      style: TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Botão de Chat - direita (desabilitado se em disputa)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: classData.isInDispute
                      ? null
                      : () => _navigateToChat(classData),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: classData.isInDispute
                        ? Colors.grey.shade300
                        : AppColors.primaryOrange,
                    foregroundColor: classData.isInDispute
                        ? Colors.grey.shade600
                        : Colors.white,
                    elevation: classData.isInDispute ? 0 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingConfirmationClassCard(
    ClassResponseDto classData,
    ClassTimelineDto? timeline,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showStudentHealthModal(classData),
                child: Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(23.5),
                    border: Border.all(
                      color: AppColors.primaryOrange,
                      width: 2,
                    ),
                    color: const Color(0xFFF3F3F3),
                  ),
                  child: _buildStudentAvatar(classData),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatName(classData.studentName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 22,
                          color: Color(0xFF42464D),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            classData.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Fira Sans',
                              fontSize: 12,
                              color: Color(0xFF42464D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((classData.proposalModality ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildModalityAndPrice(
                        classData,
                        accentColor: Colors.orange.shade700,
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFA6A6A6)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                Icons.calendar_today,
                'Data',
                _formatDate(classData.date),
              ),
              _buildInfoItem(Icons.access_time, 'Horário', classData.time),
              _buildInfoItem(
                Icons.timer,
                'Duração',
                '${classData.duration}min',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hourglass_empty,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aguardando confirmação do aluno',
                        style: TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'O aluno tem alguns minutos para confirmar sua presença na aula.',
                        style: TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 12,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Botões de ação
          Row(
            children: [
              // Botão Personal não compareceu (se permitido) - esquerda
              if (timeline?.canReportPersonalNoShow == true) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _showReportStudentNoShowModal(classData, timeline),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Reportar'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedClassCard(
    ClassResponseDto classData,
    ClassTimelineDto? timeline,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23.5),
                  border: Border.all(color: Colors.green, width: 2),
                  color: Colors.green.shade100,
                ),
                child: _buildStudentAvatar(classData),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatName(classData.studentName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 22,
                          color: Color(0xFF42464D),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            classData.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Fira Sans',
                              fontSize: 12,
                              color: Color(0xFF42464D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((classData.proposalModality ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildModalityAndPrice(
                        classData,
                        accentColor: Colors.green.shade700,
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFA6A6A6)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                Icons.calendar_today,
                'Data',
                _formatDate(classData.date),
              ),
              _buildInfoItem(Icons.access_time, 'Horário', classData.time),
              _buildInfoItem(
                Icons.timer,
                'Duração',
                '${classData.duration}min',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    classData.personalRating == null
                        ? 'Aula concluída com sucesso! Avalie seu aluno.'
                        : 'Aula concluída com sucesso!',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Mostrar botão "Avaliar aluno" apenas se ainda não foi avaliado e dentro de 24h
          if (classData.personalRating == null &&
              _canEvaluateClass(classData.endTime))
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClassEvaluationPage(
                        studentName: classData.studentName,
                        classId: classData.id,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Avaliar aluno',
                  style: TextStyle(
                    fontFamily: 'Fira Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDisputeClassCard(
    ClassResponseDto classData,
    ClassTimelineDto? timeline,
  ) {
    final canSubmitDefense =
        classData.noShowReportedBy == 'student' &&
        classData.personalDefenseSubmittedAt == null &&
        classData.status == ClassStatus.NO_SHOW_DISPUTE &&
        _isDefenseDeadlineOpen(classData.evidenceDeadline);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23.5),
                  border: Border.all(color: Colors.red, width: 2),
                  color: Colors.red.shade100,
                ),
                child: _buildStudentAvatar(classData),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatName(classData.studentName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 22,
                          color: Color(0xFF42464D),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            classData.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Fira Sans',
                              fontSize: 12,
                              color: Color(0xFF42464D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFA6A6A6)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                Icons.calendar_today,
                'Data',
                _formatDate(classData.date),
              ),
              _buildInfoItem(Icons.access_time, 'Horário', classData.time),
              _buildInfoItem(
                Icons.timer,
                'Duração',
                '${classData.duration}min',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.warning,
                        color: Colors.red.shade700,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getDisputeStatusMessage(classData),
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                if (classData.evidenceDeadline != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Icon(
                          Icons.schedule_rounded,
                          color: canSubmitDefense
                              ? Colors.red.shade700
                              : Colors.red.shade500,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _buildDefenseDeadlineMessage(
                            classData.evidenceDeadline!,
                          ),
                          style: TextStyle(
                            color: canSubmitDefense
                                ? Colors.red.shade700
                                : Colors.red.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                // CTA de defesa: apenas se o personal é o reportado, ainda não enviou,
                // a disputa está ativa e o prazo ainda está aberto.
                if (canSubmitDefense) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.gavel,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                      label: Text(
                        'Enviar minha defesa',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _showDisputeDefenseModal(classData.id),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDisputeStatusMessage(ClassResponseDto classData) {
    return ClassDisputeStatusHelper.getPersonalViewMessage(classData);
  }

  bool _isDefenseDeadlineOpen(DateTime? deadline) {
    return deadline == null || deadline.isAfter(DateTime.now());
  }

  String _formatDeadlineDateTime(DateTime deadline) {
    final day = deadline.day.toString().padLeft(2, '0');
    final month = deadline.month.toString().padLeft(2, '0');
    final year = deadline.year.toString().padLeft(4, '0');
    final hour = deadline.hour.toString().padLeft(2, '0');
    final minute = deadline.minute.toString().padLeft(2, '0');
    return '$day/$month/$year às $hour:$minute';
  }

  String _buildDefenseDeadlineMessage(DateTime deadline) {
    final formatted = _formatDeadlineDateTime(deadline);
    if (_isDefenseDeadlineOpen(deadline)) {
      return 'Prazo máximo para enviar a defesa: $formatted.';
    }
    return 'Prazo para enviar a defesa encerrado em $formatted.';
  }

  void _showDisputeDefenseModal(String classId) {
    // Buscar a classData para passar ao modal
    final state = context.read<ClassesBloc>().state;
    ClassResponseDto? classData;
    if (state is ClassesLoaded) {
      try {
        classData = state.classes.firstWhere((c) => c.id == classId);
      } catch (_) {}
    }
    if (classData == null) return;

    if (!_isDefenseDeadlineOpen(classData.evidenceDeadline)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            classData.evidenceDeadline != null
                ? _buildDefenseDeadlineMessage(classData.evidenceDeadline!)
                : 'Prazo para enviar a defesa expirado.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    DisputeDefenseModal.show(context, classId, classData);
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF42464D)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Fira Sans',
                    fontSize: 12,
                    color: Color(0xFF42464D),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Fira Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF42464D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Métodos auxiliares para filtros
  bool _hasActiveFilters() {
    return (_selectedDate != null && _selectedDate != 'Hoje') ||
        _selectedTime != null ||
        _selectedStatus != null;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedDate = 'Hoje';
      _selectedTime = null;
      _selectedStatus = null;
    });
    _updateFilters();
  }

  String _getTimeDisplayName(String? timeValue) {
    if (timeValue == null) return '';
    return timeValue.split(' (')[0];
  }

  Widget _buildFilterChip(
    String label,
    String? selectedValue,
    List<String> options,
    IconData icon,
    Function(String?) onChanged,
  ) {
    final isSelected = selectedValue != null;

    return GestureDetector(
      onTap: () => _showFilterDialog(label, selectedValue, options, onChanged),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryOrange
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primaryOrange.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryOrange.withOpacity(0.2)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(
                icon,
                size: 12,
                color: isSelected
                    ? AppColors.primaryOrange
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label == 'Horário'
                    ? (selectedValue != null
                          ? _getTimeDisplayName(selectedValue)
                          : label)
                    : (selectedValue ?? label),
                style: TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 12,
                  color: isSelected
                      ? AppColors.primaryOrange
                      : const Color(0xFF2D3748),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isSelected
                  ? AppColors.primaryOrange
                  : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterTag(
    String label,
    String value,
    VoidCallback onRemove,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: $value',
            style: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 12,
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close,
                size: 12,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(
    String title,
    String? selectedValue,
    List<String> options,
    Function(String?) onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getFilterIcon(title),
                        color: AppColors.primaryOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filtrar por $title',
                            style: const TextStyle(
                              fontFamily: 'Fira Sans',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          if (selectedValue != null)
                            Text(
                              'Selecionado: $selectedValue',
                              style: const TextStyle(
                                fontFamily: 'Fira Sans',
                                fontSize: 12,
                                color: Color(0xFF42464D),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (selectedValue != null)
                      TextButton(
                        onPressed: () {
                          onChanged(null);
                          Navigator.of(context).pop();
                          _updateFilters();
                        },
                        child: const Text(
                          'Limpar',
                          style: TextStyle(
                            fontFamily: 'Fira Sans',
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView(
                  shrinkWrap: true,
                  children: options.map((option) {
                    final isSelected = option == selectedValue;
                    return InkWell(
                      onTap: () {
                        onChanged(option);
                        Navigator.of(context).pop();
                        _updateFilters();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryOrange.withOpacity(0.05)
                              : Colors.white,
                          border: isSelected
                              ? Border(
                                  left: BorderSide(
                                    color: AppColors.primaryOrange,
                                    width: 3,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontFamily: 'Fira Sans',
                                  fontSize: 16,
                                  color: isSelected
                                      ? AppColors.primaryOrange
                                      : const Color(0xFF2D3748),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primaryOrange,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  IconData _getFilterIcon(String filterType) {
    switch (filterType.toLowerCase()) {
      case 'status':
        return Icons.info;
      case 'data':
        return Icons.calendar_today;
      case 'horário':
        return Icons.access_time;
      case 'categoria':
        return Icons.category;
      default:
        return Icons.filter_list;
    }
  }
}
