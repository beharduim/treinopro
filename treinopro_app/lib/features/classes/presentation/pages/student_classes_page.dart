import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/image_utils.dart';
import '../widgets/class_timer_widget.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../auth/domain/usecases/upload_usecase.dart';
import '../../../evaluation/presentation/pages/personal_evaluation_page.dart';
import '../../../proposals/presentation/pages/recontract_page.dart';
import '../../../proposals/presentation/bloc/proposals_bloc.dart';
import '../../../proposals/presentation/bloc/proposals_event.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_state.dart' as home_states;

import 'class_tracking_page.dart';
import '../../data/models/class_response_dto.dart';
import '../../data/models/class_timeline_dto.dart';
import '../../data/models/confirm_class_start_dto.dart';
import '../../data/models/report_no_show_dto.dart';
import '../widgets/confirm_class_start_modal.dart';
import '../widgets/report_no_show_modal.dart';
import '../widgets/dispute_defense_modal.dart';
import '../bloc/classes_bloc.dart';
import '../../../../core/services/class_presence_snapshot_service.dart';
import '../utils/class_dispute_status_helper.dart';

class StudentClassesPage extends StatelessWidget {
  const StudentClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StudentClassesPageView();
  }
}

class _StudentClassesPageView extends StatefulWidget {
  const _StudentClassesPageView();

  @override
  State<_StudentClassesPageView> createState() =>
      _StudentClassesPageViewState();
}

class _StudentClassesPageViewState extends State<_StudentClassesPageView> {
  final UploadUseCase _uploadUseCase = sl<UploadUseCase>();

  // Variáveis dos filtros de aulas
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
    'Aula concluída',
    'Aula cancelada',
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
        print('🚀 [STUDENT_CLASSES] Inicializando ClassesBloc...');
        classesBloc.add(const ClassesInitialize());
      }

      print('📚 [STUDENT_CLASSES] Aplicando filtros padrão da aba treino...');
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

  /// Cancelar aula
  void _cancelClass(String classId) {
    context.read<ClassesBloc>().add(ClassesCancelClass(classId: classId));
  }

  /// Converte filtro de data do chip para formato da API
  String? _getDateFilter() {
    if (_selectedDate == null) return null;

    final now = DateTime.now();
    String? result;

    switch (_selectedDate) {
      case 'Todos':
        result = null;
        break;
      case 'Hoje':
        result =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        break;
      case 'Amanhã':
        final tomorrow = now.add(const Duration(days: 1));
        result =
            '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
        break;
      case 'Essa semana':
        result = null;
        break;
      case 'Esse mês':
        result = null;
        break;
      default:
        result = null;
    }

    print(
      '🔍 [STUDENT_FILTERS] Filtro de data selecionado: $_selectedDate -> $result',
    );
    return result;
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
      '🔍 [STUDENT_FILTERS] Filtro de horário selecionado: $_selectedTime -> $result',
    );
    return result;
  }

  String? _getStatusFilter() {
    if (_selectedStatus == null) return null;

    print(
      '🔍 [STUDENT_FILTERS] Filtro de status selecionado: $_selectedStatus',
    );
    return _selectedStatus;
  }

  void _confirmClassStart(String classId, String confirmationCode) {
    final dto = ConfirmClassStartDto(
      confirmed: true,
      confirmationCode: confirmationCode,
      notes: 'Aluno confirmou presença',
    );

    context.read<ClassesBloc>().add(
      ClassesConfirmClassStart(classId: classId, dto: dto),
    );
  }

  /// Agenda snapshots de geolocalização para aulas agendadas do aluno
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
      if (classData.studentId != userId) continue;

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
      // Ignorar aulas passadas há mais de 24h (sem valor em agendar)
      if (DateTime.now().difference(t0).inHours > 24) continue;

      ClassPresenceSnapshotService.instance.scheduleSnapshot(
        classId: classData.id,
        userId: userId,
        role: 'student',
        scheduledAt: t0,
      );
    }
  }

  Future<void> _reportPersonalNoShow(
    ClassResponseDto classData,
    ClassTimelineDto timeline,
    Map<String, dynamic> reportData,
  ) async {
    try {
      print('🔍 [REPORT] Iniciando reporte de ausência do personal');
      print('🔍 [REPORT] classId: ${classData.id}');
      print('🔍 [REPORT] reportData: $reportData');

      // Tentar capturar presença síncrona se ainda não houver
      if (!timeline.hasPresenceSnapshot) {
        print(
          '⏳ [REPORT] Snapshot de presença ausente. Tentando capturar forçadamente agora...',
        );
        final captured = await ClassPresenceSnapshotService.instance.captureNow(
          classId: classData.id,
          userId: classData.studentId, // Quem está reportando é o aluno
          role: 'student',
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
        print('🔍 [REPORT] Fazendo upload de ${evidenceImages.length} imagens');

        for (int i = 0; i < evidenceImages.length; i++) {
          String imagePath = evidenceImages[i];
          print('🔍 [REPORT] Upload imagem ${i + 1}: $imagePath');

          try {
            final file = File(imagePath);
            if (await file.exists()) {
              print('🔍 [REPORT] Arquivo existe, fazendo upload...');

              final uploadResponse = await _uploadUseCase.uploadDisputeEvidence(
                file: file,
                classId: classData.id,
                description: 'Evidência de ausência do personal',
              );

              print('🔍 [REPORT] Upload concluído: ${uploadResponse.url}');
              evidenceUrls.add(uploadResponse.url);
            } else {
              print('❌ [REPORT] Arquivo não existe: $imagePath');
            }
          } catch (e) {
            print('❌ [REPORT] Erro ao fazer upload da imagem $imagePath: $e');
            // Continue com as outras imagens mesmo se uma falhar
          }
        }
      } else {
        print('🔍 [REPORT] Nenhuma imagem para upload');
      }

      print('🔍 [REPORT] URLs finais: $evidenceUrls');

      // Criar DTO com URLs das imagens enviadas
      final dto = ReportNoShowDto(
        reason: reportData['reason'] as String,
        notes: reportData['notes'] as String?,
        evidenceUrls: evidenceUrls.isNotEmpty ? evidenceUrls : null,
      );

      print('🔍 [REPORT] Enviando reporte para API...');
      context.read<ClassesBloc>().add(
        ClassesReportPersonalNoShow(classId: classData.id, dto: dto),
      );
      print('🔍 [REPORT] Reporte enviado com sucesso!');
    } catch (e) {
      print('❌ [REPORT] Erro no reporte: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reportar ausência do personal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Resolve nome do personal com múltiplos fallbacks
  String _resolvePersonalName(
    ClassResponseDto classData,
    List<ClassResponseDto> classes,
  ) {
    // 1) Nome vindo direto do DTO
    if (classData.personalName.isNotEmpty) return classData.personalName;
    // 2) Procurar mesma aula no estado atual
    try {
      final cached = classes.firstWhere((c) => c.id == classData.id);
      if (cached.personalName.isNotEmpty) return cached.personalName;
    } catch (_) {}
    // 3) Procurar por mesmo personalId em outra aula
    try {
      final byPersonal = classes.firstWhere(
        (c) =>
            c.personalId == classData.personalId && c.personalName.isNotEmpty,
      );
      return byPersonal.personalName;
    } catch (_) {}
    // 4) Fallback
    return 'Personal';
  }

  Widget _buildPersonalAvatar(ClassResponseDto classData) {
    final imageUrl = ImageUtils.buildImageUrl(
      classData.personalProfileImageUrl,
    );

    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(21.5),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person, size: 24, color: Color(0xFF42464D)),
        ),
      );
    }

    return const Icon(Icons.person, size: 24, color: Color(0xFF42464D));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClassesBloc, ClassesState>(
      listener: (context, state) {
        if (state is ClassesStartSuccess) {
          // ✅ Prevenir navegação múltipla
          if (_hasNavigatedToTracking) {
            print(
              '⚠️ [STUDENT_CLASSES] Navegação para tracking já realizada, ignorando...',
            );
            return;
          }

          _hasNavigatedToTracking = true;
          final classData = state.startedClass;
          // ✅ CORREÇÃO: Passar a mesma instância do ClassesBloc conectada ao WebSocket
          final classesBloc = context.read<ClassesBloc>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) {
                // Obter rating geral do personal a partir do HomeBloc (mesma fonte do DynamicWorkoutCard)
                double? ratingFromHome;
                try {
                  final homeState = context.read<HomeBloc>().state;
                  if (homeState is home_states.HomeLoaded) {
                    final data = homeState.homeState.workoutCardData;
                    final raw = data != null ? data['personalRating'] : null;
                    if (raw is num) ratingFromHome = raw.toDouble();
                    if (raw is String)
                      ratingFromHome = double.tryParse(
                        raw.replaceAll(',', '.'),
                      );
                  }
                } catch (_) {}

                final resolvedRating =
                    (ratingFromHome ?? classData.personalRating ?? 5.0)
                        .toString();

                return BlocProvider.value(
                  value: classesBloc,
                  child: ClassTrackingPage(
                    aula: {
                      'id': classData.id,
                      'studentName': classData.studentName,
                      'personalName': classData.personalName,
                      'location': classData.location,
                      'date': _formatDate(classData.date),
                      'time': classData.time,
                      'duration': '${classData.duration}min',
                      'avatarUrl': classData.personalProfileImageUrl,
                      'rating': resolvedRating,
                      'years': classData.personalTimeOnPlatform ?? '0 dias',
                    },
                  ),
                );
              },
            ),
          );
        } else if (state is ClassesCompleteSuccess) {
          // Redirecionar para avaliação do personal quando aula for finalizada
          final classData = state.completedClass;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PersonalEvaluationPage(
                trainerName: classData.personalName,
                classId: classData.id,
              ),
            ),
          );
        } else if (state is ClassesLoaded) {
          // ✅ Resetar flag quando estado voltar para ClassesLoaded (após navegação)
          _hasNavigatedToTracking = false;
          // ✅ Agendar snapshots de geolocalização para aulas agendadas
          _schedulePresenceSnapshots(context, state.classes);
        } else if (state is ClassesOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
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
                color: AppColors.primaryOrange,
                onRefresh: () async {
                  context.read<ClassesBloc>().add(const ClassesRefresh());
                  await Future.delayed(const Duration(milliseconds: 600));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 20,
                    bottom: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Minhas aulas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildFilterSection(),
                      const SizedBox(height: 16),
                      _buildFilterStatus(),
                      const SizedBox(height: 24),
                      _buildFilteredClassesList(state),
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
                  (value) {
                    setState(() => _selectedDate = value);
                    _updateFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'Horário',
                  _selectedTime,
                  _times,
                  Icons.access_time_rounded,
                  (value) {
                    setState(() => _selectedTime = value);
                    _updateFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'Status',
                  _selectedStatus,
                  _statuses,
                  Icons.info_outline_rounded,
                  (value) {
                    setState(() => _selectedStatus = value);
                    _updateFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  Widget _buildFilterStatus() {
    List<String> activeFilters = [];

    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros aplicados:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = 'Hoje';
                    _selectedTime = null;
                    _selectedStatus = null;
                  });
                  _updateFilters();
                },
                child: const Text(
                  'Limpar filtros',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF6B35),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildFilteredClassesList(ClassesState state) {
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

    // Verificar se não há aulas antes de aplicar filtros
    if (state.classes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma aula encontrada',
                style: TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Você ainda não possui aulas agendadas',
                style: TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final filteredClasses = _getFilteredClasses(state.classes);

    if (filteredClasses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Nenhuma aula encontrada',
                style: TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ajuste os filtros ou aguarde novas aulas',
                style: TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ClassesBloc>().add(const ClassesRefresh());
      },
      child: Column(
        children: filteredClasses
            .map(
              (classData) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildClassCard(
                  classData,
                  state.timelines,
                  state.classes,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildClassCard(
    ClassResponseDto classData,
    Map<String, ClassTimelineDto> timelines,
    List<ClassResponseDto> classes,
  ) {
    final timeline = timelines[classData.id];

    if (classData.noShowReportedAt != null) {
      return _buildDisputeClassCard(classData, timeline);
    }

    switch (classData.status) {
      case ClassStatus.ACTIVE:
        return _buildActiveClassCard(classData, timeline);
      case ClassStatus.PENDING_CONFIRMATION:
        return _buildPendingConfirmationClassCard(classData, timeline, classes);
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
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23.5),
                  border: Border.all(color: AppColors.primaryOrange, width: 2),
                  color: const Color(0xFFF3F3F3),
                ),
                child: _buildPersonalAvatar(classData),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classData.personalName,
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // ✅ CORREÇÃO: Passar a mesma instância do ClassesBloc conectada ao WebSocket
                final classesBloc = context.read<ClassesBloc>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      print(
                        '🔍 [STUDENT_CLASSES] Personal Time On Platform: ${classData.personalTimeOnPlatform}',
                      );
                      print(
                        '🔍 [STUDENT_CLASSES] Personal Rating: ${classData.personalRating}',
                      );
                      return BlocProvider.value(
                        value: classesBloc,
                        child: ClassTrackingPage(
                          aula: {
                            'id': classData.id,
                            'studentName': classData.studentName,
                            'personalName': classData.personalName,
                            'location': classData.location,
                            'date': _formatDate(classData.date),
                            'time': classData.time,
                            'duration': '${classData.duration}min',
                            'avatarUrl': classData.personalProfileImageUrl,
                            // Prioriza rating do HomeBloc (se disponível), senão do DTO, senão 5.0
                            'rating': () {
                              double? ratingFromHome;
                              try {
                                final homeState = context
                                    .read<HomeBloc>()
                                    .state;
                                if (homeState is home_states.HomeLoaded) {
                                  final data =
                                      homeState.homeState.workoutCardData;
                                  final raw = data != null
                                      ? data['personalRating']
                                      : null;
                                  if (raw is num)
                                    ratingFromHome = raw.toDouble();
                                  if (raw is String)
                                    ratingFromHome = double.tryParse(
                                      raw.replaceAll(',', '.'),
                                    );
                                }
                              } catch (_) {}
                              return (ratingFromHome ??
                                      classData.personalRating ??
                                      5.0)
                                  .toString();
                            }(),
                            'years':
                                classData.personalTimeOnPlatform ?? '0 dias',
                          },
                        ),
                      );
                    },
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Acompanhar aula',
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingConfirmationClassCard(
    ClassResponseDto classData,
    ClassTimelineDto? timeline,
    List<ClassResponseDto> classes,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300, width: 2),
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
              // Avatar do personal (igual aos outros cards)
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23.5),
                  border: Border.all(color: AppColors.primaryOrange, width: 2),
                  color: const Color(0xFFF3F3F3),
                ),
                child: _buildPersonalAvatar(classData),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _resolvePersonalName(classData, classes),
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildModalityAndPrice(
                          classData,
                          accentColor: AppColors.primaryOrange,
                        ),
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
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade700,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Personal trainer iniciou a aula. Confirme se você está presente.',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showReportPersonalNoShowModal(classData, timeline);
                  },
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
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _showConfirmClassStartModal(classData, timeline);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Confirmar'),
                ),
              ),
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
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23.5),
                  border: Border.all(color: Colors.blue.shade400, width: 2),
                  color: Colors.blue.shade100,
                ),
                child: _buildPersonalAvatar(classData),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classData.personalName,
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildModalityAndPrice(
                          classData,
                          accentColor: Colors.blue.shade700,
                        ),
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
          // Botões de ação: Cancelar, Personal não compareceu e Chat
          Row(
            children: [
              // Botão de Cancelar (se permitido) - esquerda
              if (timeline?.canCancel == true) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _cancelClass(classData.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Botão Personal não compareceu (se permitido) - esquerda
              if (timeline?.canReportPersonalNoShow == true) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _showReportPersonalNoShowModal(classData, timeline),
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
              // Botão de Chat - direita (desabilitado se em disputa)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: classData.isInDispute
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                classId: classData.id,
                                receiverId: classData.personalId,
                                receiverName: classData.personalName,
                                location: classData.location,
                                date: _formatDate(classData.date),
                                time: classData.time,
                                duration: '${classData.duration}min',
                                currentUserIsStudent: true, // Student
                              ),
                            ),
                          );
                        },
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

  Widget _buildCompletedClassCard(
    ClassResponseDto classData,
    ClassTimelineDto? timeline,
  ) {
    final canEvaluate =
        classData.studentRating == null && _canEvaluateClass(classData.endTime);
    final canRecontract =
        classData.personalId.isNotEmpty && _canRecontractClass(classData);

    return GestureDetector(
      onTap: canEvaluate ? () => _openPersonalEvaluation(classData) : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
                  child: const Icon(
                    Icons.check_circle,
                    size: 24,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classData.personalName,
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildModalityAndPrice(
                            classData,
                            accentColor: Colors.green.shade700,
                          ),
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
                      classData.studentRating == null
                          ? (canEvaluate
                                ? 'Aula concluída com sucesso! Avalie seu personal trainer.'
                                : 'Aula concluída com sucesso! Prazo para avaliação encerrado.')
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
            if (canEvaluate)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _openPersonalEvaluation(classData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Avaliar personal',
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (canRecontract) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openRecontract(classData),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recontratar personal trainer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryOrange,
                    side: const BorderSide(color: AppColors.primaryOrange),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ] else if (classData.personalId.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Recontratação indisponível após 24h da aula.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Fira Sans',
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDisputeClassCard(
    ClassResponseDto classData,
    ClassTimelineDto? timeline,
  ) {
    final canSubmitDefense =
        classData.noShowReportedBy == 'personal' &&
        classData.studentDefenseSubmittedAt == null &&
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
                child: const Icon(Icons.warning, size: 24, color: Colors.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classData.personalName,
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
                // CTA de defesa: apenas se o aluno é o reportado, ainda não enviou,
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

  String _formatClassPrice(double? price) {
    final classPrice = price ?? 0.0;
    return 'R\$ ${classPrice.toStringAsFixed(0)}';
  }

  Widget _buildModalityAndPrice(
    ClassResponseDto classData, {
    required Color accentColor,
  }) {
    final modality = classData.proposalModality?.trim();
    if (modality == null || modality.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            modality,
            style: TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: accentColor,
            ),
          ),
        ),
        Text(
          _formatClassPrice(classData.proposalPrice),
          style: TextStyle(
            fontFamily: 'Fira Sans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accentColor,
          ),
        ),
      ],
    );
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

  void _showConfirmClassStartModal(
    ClassResponseDto classData,
    ClassTimelineDto? timeline,
  ) {
    if (timeline == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmClassStartModal(
        classData: classData,
        timeline: timeline,
        onConfirm: (String code) {
          Navigator.of(context, rootNavigator: true).pop();
          _confirmClassStart(classData.id, code);
        },
        onDeny: () {
          Navigator.of(context, rootNavigator: true).pop();
          _showReportPersonalNoShowModal(classData, timeline);
        },
      ),
    );
  }

  void _openPersonalEvaluation(ClassResponseDto classData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalEvaluationPage(
          trainerName: classData.personalName,
          classId: classData.id,
          personalId: classData.personalId,
        ),
      ),
    );
  }

  void _openRecontract(ClassResponseDto classData) {
    final personalRating = classData.personalRating;
    final personalRatingText = personalRating == null
        ? null
        : personalRating.toStringAsFixed(1);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => sl<ProposalsBloc>()
            ..add(const ProposalsInitialize())
            ..add(const ProposalsLoadPaymentMethods()),
          child: RecontractPage(
            personalId: classData.personalId,
            personalName: classData.personalName,
            personalEmail: classData.personalEmail,
            personalProfileImageUrl: classData.personalProfileImageUrl,
            personalRating: personalRatingText,
            personalTimeOnPlatform: classData.personalTimeOnPlatform,
          ),
        ),
      ),
    );
  }

  String _getDisputeStatusMessage(ClassResponseDto classData) {
    return ClassDisputeStatusHelper.getStudentViewMessage(classData);
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

  void _showReportPersonalNoShowModal(
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
        isPersonalNoShow: true,
        onReport: (reportData) {
          _reportPersonalNoShow(classData, timeline, reportData);
        },
      ),
    );
  }

  // Métodos auxiliares
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

  // Gamificação na confirmação removida: missões/XP só na conclusão da aula

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

  bool _canRecontractClass(ClassResponseDto classData) {
    DateTime? referenceTime = classData.endTime;

    if (referenceTime == null) {
      final parts = classData.time.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      referenceTime = DateTime(
        classData.date.year,
        classData.date.month,
        classData.date.day,
        hour,
        minute,
      );
    }

    return DateTime.now().difference(referenceTime).inHours < 24;
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

    // Ordenação por prioridade de status
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
          return 6; // reportadas por último
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
