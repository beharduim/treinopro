import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/fluid_timer_widget.dart';
import '../widgets/report_problem_modal.dart';
import '../../data/services/classes_api_service.dart';
import '../../data/models/complete_class_dto.dart';
import '../../../evaluation/presentation/pages/class_evaluation_page.dart';
import '../bloc/classes_bloc.dart';
import '../bloc/classes_state.dart';
import '../bloc/classes_event.dart';
import '../../data/models/class_timer_state.dart';
import '../../data/models/class_response_dto.dart';
import '../widgets/report_no_show_modal.dart';
import '../../data/models/report_no_show_dto.dart';
import '../../data/models/class_timeline_dto.dart';
import '../widgets/timeline_completion_countdown.dart';
import '../../utils/class_operation_error_messages.dart';

class PersonalClassTrackingPage extends StatefulWidget {
  final Map<String, dynamic> aula;
  const PersonalClassTrackingPage({super.key, required this.aula});

  @override
  State<PersonalClassTrackingPage> createState() =>
      _PersonalClassTrackingPageState();
}

class _PersonalClassTrackingPageState extends State<PersonalClassTrackingPage> {
  final ClassesApiService _classesApiService = sl<ClassesApiService>();
  bool _isCompleting = false;
  bool _hasNavigatedToEvaluation = false;
  bool _hasHandledRollback = false;
  double? _lastKnownProposalPrice;

  // Código de confirmação 4 dígitos para o aluno confirmar
  String? _startConfirmationCode;
  late final TimelineCompletionCountdownController _completionCountdown;

  @override
  void initState() {
    super.initState();
    _completionCountdown = TimelineCompletionCountdownController();
    _startConfirmationCode = widget.aula['startConfirmationCode']?.toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final classesBloc = context.read<ClassesBloc>();
      if (classesBloc.state is ClassesInitial) {
        classesBloc.add(const ClassesInitialize());
      }
      // SSOT: timeline vem do backend (GET /classes/:id/timeline)
      final classId = _resolveClassId();
      if (classId != null) {
        classesBloc.add(ClassesUpdateTimeline(classId: classId));
      }
    });
  }

  String? _resolveClassId() {
    return widget.aula['id']?.toString() ??
        widget.aula['classId']?.toString();
  }

  @override
  void dispose() {
    _completionCountdown.dispose();
    super.dispose();
  }

  double? _toPositiveDouble(dynamic value) {
    if (value == null) return null;
    final parsed = double.tryParse(value.toString());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  double? _resolveAmountEarned() {
    double? priceCandidate = _toPositiveDouble(_lastKnownProposalPrice);

    priceCandidate ??= _toPositiveDouble(widget.aula['proposalPrice']);

    if (priceCandidate == null) {
      try {
        final classesState = context.read<ClassesBloc>().state;
        if (classesState is ClassesLoaded) {
          final classId = widget.aula['id'].toString();
          final current = classesState.classes.firstWhere(
            (c) => c.id == classId,
          );
          priceCandidate = _toPositiveDouble(current.proposalPrice);
        }
      } catch (_) {}
    }

    if (priceCandidate == null) return null;
    return priceCandidate * 0.9;
  }

  double _amountEarnedOrFallback(double? amountEarned) {
    if (amountEarned != null && amountEarned > 0) return amountEarned;
    return 40.0;
  }

  Future<void> _completeClass() async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      final dto = CompleteClassDto(
        notes: 'Aula finalizada pelo personal trainer',
      );

      await _classesApiService.completeClass(widget.aula['id'], dto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aula finalizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        if (!_hasNavigatedToEvaluation) {
          _hasNavigatedToEvaluation = true;
          final String studentName = widget.aula['studentName'] ?? 'Aluno';
          final amountEarned = _resolveAmountEarned();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ClassEvaluationPage(
                studentName: studentName,
                classId: widget.aula['id'].toString(),
                amountEarned: _amountEarnedOrFallback(amountEarned),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        bool shouldNavigateToEvaluation = false;
        Color snackBarColor = Colors.orange;

        if (e.toString().contains('502') ||
            e.toString().contains('Bad Gateway')) {
          errorMessage =
              'Aula finalizada! O sistema de pontos está temporariamente indisponível, mas você pode continuar.';
          shouldNavigateToEvaluation = true;
          snackBarColor = Colors.green;
        } else if (e.toString().contains('já foi finalizada anteriormente') ||
            e.toString().contains('Apenas aulas ativas podem ser finalizadas')) {
          errorMessage = 'Esta aula já foi finalizada anteriormente.';
          shouldNavigateToEvaluation = true;
        } else {
          errorMessage = ClassOperationErrorMessages.friendlyMessage(
            e,
            action: 'complete_class',
          );
          snackBarColor = Colors.red;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: snackBarColor,
            duration: const Duration(seconds: 4),
          ),
        );

        if (shouldNavigateToEvaluation && !_hasNavigatedToEvaluation) {
          _hasNavigatedToEvaluation = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              final String studentName = widget.aula['studentName'] ?? 'Aluno';
              final amountEarned = _resolveAmountEarned();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ClassEvaluationPage(
                    studentName: studentName,
                    classId: widget.aula['id'].toString(),
                    amountEarned: _amountEarnedOrFallback(amountEarned),
                  ),
                ),
              );
            }
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  String _resolveStudentName(
    ClassResponseDto? currentClass,
    Map<String, dynamic> aula,
  ) {
    if (currentClass != null && currentClass.studentName.trim().isNotEmpty) {
      return currentClass.studentName;
    }
    final fromAula = aula['studentName']?.toString().trim() ?? '';
    if (fromAula.isNotEmpty && fromAula != 'Usuário removido') {
      return fromAula;
    }
    return 'Aluno';
  }

  String? _resolveStudentPhoto(
    ClassResponseDto? currentClass,
    Map<String, dynamic> aula,
  ) {
    final fromClass = currentClass?.studentProfileImageUrl;
    if (fromClass != null && fromClass.isNotEmpty) return fromClass;
    final fromAula = aula['studentPhotoUrl']?.toString();
    if (fromAula != null && fromAula.isNotEmpty) return fromAula;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final aula = widget.aula;
    final location = aula['location'] ?? 'Local não informado';
    final classId =
        aula['id']?.toString() ??
        aula['classId']?.toString() ??
        'unknown_class';

    return BlocBuilder<ClassesBloc, ClassesState>(
      builder: (context, state) {
        ClassTimerState? timerState;
        ClassResponseDto? currentClass;
        ClassTimelineDto? timeline;
        String? studentPhotoUrl;

        if (state is ClassesLoaded) {
          timerState = state.timers[classId];
          timeline = state.timelines[classId];
          try {
            currentClass = state.classes.firstWhere((c) => c.id == classId);
            if (currentClass.proposalPrice != null &&
                currentClass.proposalPrice! > 0) {
              _lastKnownProposalPrice = currentClass.proposalPrice;
            }
          } catch (_) {
            currentClass = null;
          }
        } else if (state is ClassesStartSuccess &&
            state.startedClass.id == classId) {
          currentClass = state.startedClass;
          if (currentClass.proposalPrice != null &&
              currentClass.proposalPrice! > 0) {
            _lastKnownProposalPrice = currentClass.proposalPrice;
          }
        }

        final studentName = _resolveStudentName(currentClass, aula);
        studentPhotoUrl = _resolveStudentPhoto(currentClass, aula);

        final ClassTimerState effectiveTimerState = (() {
          if (timerState != null) return timerState;
          final cc = currentClass;
          final st = cc?.startTime;
          if (cc != null && st != null) {
            final DateTime start = st;
            final int durationMin = cc.duration;
            final totalSeconds = durationMin * 60;
            final elapsed = DateTime.now().difference(start).inSeconds;
            final remaining = (totalSeconds - elapsed).clamp(0, totalSeconds);
            return ClassTimerState(
              classId: classId,
              startTime: start,
              durationMinutes: durationMin,
              isActive: remaining > 0,
              remainingSeconds: remaining,
            );
          }
          return ClassTimerState(
            classId: classId,
            startTime: DateTime.now(),
            durationMinutes: 60,
            isActive: false,
          );
        })();

        if (currentClass != null &&
            currentClass.status == ClassStatus.SCHEDULED &&
            !_hasHandledRollback) {
          _hasHandledRollback = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'A aula foi revertida para agendada. Por favor, reinicie a aula.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            }
          });
          return const Scaffold(
            backgroundColor: Color(0xFFFCFDFE),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (timerState == null || !timerState.isActive) {
          ClassResponseDto? classData = currentClass;
          if (classData != null && classData.status == ClassStatus.COMPLETED) {
            if (!_hasNavigatedToEvaluation) {
              _hasNavigatedToEvaluation = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  final String studentName =
                      widget.aula['studentName'] ?? 'Aluno';
                  final amountEarned = _resolveAmountEarned();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassEvaluationPage(
                        studentName: studentName,
                        classId: widget.aula['id'].toString(),
                        amountEarned: _amountEarnedOrFallback(amountEarned),
                      ),
                    ),
                  );
                }
              });
            }
            return const Scaffold(
              backgroundColor: Color(0xFFFCFDFE),
              body: Center(child: CircularProgressIndicator()),
            );
          }
        }

        // SSOT: countdown visual local sincronizado com remainingToCompleteSeconds da API
        _completionCountdown.syncFromTimeline(timeline);

        return ListenableBuilder(
          listenable: _completionCountdown,
          builder: (context, _) {
            final canComplete = _completionCountdown.effectiveCanComplete;
            final canReportNoShow = timeline?.canReportNoShow ?? false;
            final remainingToCompleteSeconds =
                _completionCountdown.displayRemainingSeconds;
            final minCompletionMinutes =
                _completionCountdown.minCompletionMinutes;

            return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            backgroundColor: const Color(0xFFFCFDFE),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.home_rounded,
                    color: Color(0xFF2D3748),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/personal-home',
                      (route) => false,
                    );
                  },
                ),
              ],
              title: const Text(
                'Aula em andamento',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Color(0xFF2D3748),
                ),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Column(
                            children: [
                              FluidTimerWidget(
                                timerState: effectiveTimerState,
                                size: 250.0,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE6E9EE)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFFE6E9EE),
                            child:
                                (studentPhotoUrl != null &&
                                    studentPhotoUrl.isNotEmpty)
                                ? ClipOval(
                                    child: Image.network(
                                      studentPhotoUrl,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Text(
                                        studentName
                                            .split(' ')
                                            .map(
                                              (s) => s.isNotEmpty ? s[0] : '',
                                            )
                                            .take(2)
                                            .join(),
                                        style: const TextStyle(
                                          fontFamily: 'Fira Sans',
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    studentName
                                        .split(' ')
                                        .map((s) => s.isNotEmpty ? s[0] : '')
                                        .take(2)
                                        .join(),
                                    style: const TextStyle(
                                      fontFamily: 'Fira Sans',
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentName,
                                  style: const TextStyle(
                                    fontFamily: 'Fira Sans',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: AppColors.primaryOrange,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: const TextStyle(
                                          fontFamily: 'Fira Sans',
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
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        if (_startConfirmationCode != null &&
                            currentClass?.status ==
                                ClassStatus.PENDING_CONFIRMATION) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      color: Colors.orange.shade700,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Código de confirmação',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _startConfirmationCode!,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 40,
                                    letterSpacing: 14,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Passe este código ao aluno para ele confirmar o início',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Fira Sans',
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Localização registrada automaticamente no horário da aula (1x por participante). Se houver falha temporária, o app continuará tentando até concluir o registro.',
                                  style: TextStyle(
                                    fontFamily: 'Fira Sans',
                                    fontSize: 12,
                                    height: 1.3,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!canComplete && remainingToCompleteSeconds > 0) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color: Colors.blue.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mínimo de $minCompletionMinutes minutos',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                      Text(
                                        'Disponível para finalizar em ${formatTimelineCountdown(remainingToCompleteSeconds)}',
                                        style: TextStyle(
                                          fontFamily: 'Fira Sans',
                                          fontSize: 12,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Acompanhe o progresso da aula e finalize quando concluída. Lembre-se de orientar o aluno durante todo o treino.',
                                style: const TextStyle(
                                  fontFamily: 'Fira Sans',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (_isCompleting ||
                              !canComplete ||
                              currentClass?.status != ClassStatus.ACTIVE)
                          ? null
                          : _completeClass,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            canComplete &&
                                currentClass?.status == ClassStatus.ACTIVE
                            ? AppColors.primaryOrange
                            : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isCompleting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Finalizando...',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.stop, size: 20, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Finalizar aula',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (canReportNoShow &&
                      (currentClass?.status == ClassStatus.SCHEDULED ||
                       currentClass?.status == ClassStatus.PENDING_CONFIRMATION)) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (currentClass == null || timeline == null) return;

                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => ReportNoShowModal(
                              classData: currentClass!,
                              timeline: timeline!,
                              isPersonalNoShow: false,
                              onReport: (reportData) {
                                context.read<ClassesBloc>().add(
                                      ClassesReportNoShow(
                                        classId: currentClass!.id,
                                        dto: ReportNoShowDto(
                                          reason: reportData['reason'],
                                          notes: reportData['notes'],
                                          evidenceUrls: reportData['evidenceImages'],
                                        ),
                                      ),
                                    );
                              },
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Aluno não compareceu / Abrir Disputa',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const ReportProblemModal(),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.primaryOrange,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Reportar problema',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }
}
