import 'dart:async';
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

  // Controle de 45 minutos mínimos
  Timer? _minimumTimer;
  int _remainingToCompleteSeconds = 0; // 0 = já pode finalizar
  bool _canCompleteByTime = false;
  
  // Controle de 10 minutos para no-show
  Timer? _noShowCheckTimer;
  bool _canReportNoShow = false;

  @override
  void initState() {
    super.initState();
    // Capturar código de confirmação se foi recém iniciado
    _startConfirmationCode = widget.aula['startConfirmationCode']?.toString();

    // Calcular tempo restante para poder finalizar (50min mínimo)
    _initMinimumCompletionTimer();
    
    // Iniciar timer para verificar no-show (10min após início)
    _initNoShowTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final classesBloc = context.read<ClassesBloc>();
      if (classesBloc.state is ClassesInitial) {
        classesBloc.add(const ClassesInitialize());
      }
    });
  }

  void _initMinimumCompletionTimer() {
    // Tenta usar minimumCompletionAt do aula map, fallback para startedAt + 45min
    DateTime? minimumAt;
    final rawMinimum = widget.aula['minimumCompletionAt'];
    if (rawMinimum != null) {
      minimumAt = DateTime.tryParse(rawMinimum.toString());
    }
    if (minimumAt == null) {
      final rawStarted = widget.aula['startedAt'] ?? widget.aula['confirmedAt'];
      if (rawStarted != null) {
        final startedAt = DateTime.tryParse(rawStarted.toString());
        if (startedAt != null) {
          minimumAt = startedAt.add(const Duration(minutes: 50));
        }
      }
    }

    if (minimumAt != null) {
      final now = DateTime.now();
      final remaining = minimumAt.difference(now);
      if (remaining.isNegative || remaining.inSeconds <= 0) {
        _canCompleteByTime = true;
        _remainingToCompleteSeconds = 0;
      } else {
        _canCompleteByTime = false;
        _remainingToCompleteSeconds = remaining.inSeconds;
        _minimumTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) {
            t.cancel();
            return;
          }
          setState(() {
            _remainingToCompleteSeconds = (_remainingToCompleteSeconds - 1)
                .clamp(0, 99999);
            if (_remainingToCompleteSeconds <= 0) {
              _canCompleteByTime = true;
              t.cancel();
            }
          });
        });
      }
    } else {
      // Sem startedAt: liberar (fallback permissivo)
      _canCompleteByTime = true;
    }
  }

  void _initNoShowTimer() {
    _checkNoShowDeadline();
    _noShowCheckTimer = Timer.periodic(const Duration(seconds: 30), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      _checkNoShowDeadline();
    });
  }

  void _checkNoShowDeadline() {
    try {
      final dateStr = widget.aula['date'].toString();
      final timeStr = widget.aula['time'].toString();
      
      // Formato esperado: "dd/MM/yyyy" e "HH:MM"
      final parts = dateStr.split('/');
      if (parts.length != 3) return;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      final timeParts = timeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      final classStart = DateTime(year, month, day, hour, minute);
      final deadline = classStart.add(const Duration(minutes: 10));
      
      final now = DateTime.now();
      final passed = now.isAfter(deadline);
      
      if (passed != _canReportNoShow) {
        setState(() => _canReportNoShow = passed);
      }
    } catch (e) {
      debugPrint('Error checking no-show deadline: $e');
    }
  }

  String _formatRemainingTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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

  @override
  void dispose() {
    _minimumTimer?.cancel();
    _noShowCheckTimer?.cancel();
    super.dispose();
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

        // Navegar direto para a avaliação do aluno apenas se ainda não navegou
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

        // ✅ CORREÇÃO: Detectar erro 502 (Bad Gateway) especificamente
        if (e.toString().contains('502') ||
            e.toString().contains('Bad Gateway')) {
          errorMessage =
              'Aula finalizada! O sistema de pontos está temporariamente indisponível, mas você pode continuar.';
          shouldNavigateToEvaluation = true;
          snackBarColor = Colors.green; // Verde pois a aula foi finalizada
        }
        // Verificar se é erro de regra de tempo mínimo
        else if (e.toString().contains('MIN_50_RULE') ||
            e.toString().contains('pelo menos 50 minutos')) {
          // Extrair tempo restante da mensagem do backend
          final match = RegExp(r'Faltam (\d+) minuto').firstMatch(e.toString());
          final remaining = match?.group(1) ?? '?';
          errorMessage =
              'A aula precisa durar pelo menos 50 minutos. Faltam $remaining minuto(s).';
          snackBarColor = Colors.red;
        }
        // Verificar se é erro de aula já finalizada
        else if (e.toString().contains(
              'Esta aula já foi finalizada anteriormente',
            ) ||
            e.toString().contains(
              'Apenas aulas ativas podem ser finalizadas',
            )) {
          errorMessage = 'Esta aula já foi finalizada anteriormente.';
          shouldNavigateToEvaluation = true;
        }
        // Outros erros
        else {
          errorMessage = 'Erro ao finalizar aula: $e';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: snackBarColor,
            duration: const Duration(seconds: 4),
          ),
        );

        // ✅ CORREÇÃO: Se for erro 502 ou aula já finalizada, continuar o fluxo normalmente
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

  @override
  Widget build(BuildContext context) {
    final aula = widget.aula;
    final studentName = aula['studentName'] ?? 'Aluno';
    final location = aula['location'] ?? 'Local não informado';
    final classId =
        aula['id']?.toString() ??
        aula['classId']?.toString() ??
        'unknown_class';

    return BlocBuilder<ClassesBloc, ClassesState>(
      builder: (context, state) {
        ClassTimerState? timerState;
        ClassResponseDto? currentClass;
        String? studentPhotoUrl;

        if (state is ClassesLoaded) {
          timerState = state.timers[classId];
          try {
            currentClass = state.classes.firstWhere((c) => c.id == classId);
            studentPhotoUrl = currentClass.studentProfileImageUrl;
            // Guardar preço conhecido para uso posterior na navegação
            if (currentClass.proposalPrice != null &&
                currentClass.proposalPrice! > 0) {
              _lastKnownProposalPrice = currentClass.proposalPrice;
            }
          } catch (_) {
            currentClass = null;
            studentPhotoUrl = null;
          }
        } else if (state is ClassesStartSuccess &&
            state.startedClass.id == classId) {
          currentClass = state.startedClass;
          studentPhotoUrl = currentClass.studentProfileImageUrl;
          if (currentClass.proposalPrice != null &&
              currentClass.proposalPrice! > 0) {
            _lastKnownProposalPrice = currentClass.proposalPrice;
          }
        }

        // Timer efetivo para exibição imediata (evita flash de 0s ao entrar)
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

        // Tratar rollback de confirmação para status SCHEDULED
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
          // Verificar se a aula já foi finalizada
          ClassResponseDto? classData;
          if (state is ClassesLoaded) {
            try {
              classData = state.classes.firstWhere((c) => c.id == classId);
            } catch (e) {
              classData = null;
            }
          } else if (state is ClassesStartSuccess &&
              state.startedClass.id == classId) {
            classData = state.startedClass;
          }

          if (classData != null && classData.status == ClassStatus.COMPLETED) {
            // Aula já finalizada, redirecionar para avaliação do aluno
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

          // Se não há timer ativo mas a aula não foi finalizada, mostrar interface normal
          // mas sem timer (aula ainda não iniciada)
        }

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
                  // ✅ Voltar para a página anterior (ClassesPage)
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
                    // Circular timer with label
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

                    // Student info card
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
                        // Código de 4 dígitos para o aluno confirmar
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

                        // Aviso de captura de geolocalização
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

                        // Aviso de 45 minutos mínimos
                        if (!_canCompleteByTime) ...[
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
                                        'Mínimo de 45 minutos',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                      Text(
                                        'Disponível para finalizar em ${_formatRemainingTime(_remainingToCompleteSeconds)}',
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
                              !_canCompleteByTime ||
                              currentClass?.status != ClassStatus.ACTIVE)
                          ? null
                          : _completeClass,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _canCompleteByTime &&
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
                  if (_canReportNoShow && 
                      (currentClass?.status == ClassStatus.SCHEDULED || 
                       currentClass?.status == ClassStatus.PENDING_CONFIRMATION)) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (currentClass == null) return;
                          
                          // Buscar timeline do estado se disponível
                          ClassTimelineDto? tl;
                          final state = context.read<ClassesBloc>().state;
                          if (state is ClassesLoaded) {
                            tl = state.timelines[currentClass.id];
                          }
                          
                          // Fallback para timeline básico
                          tl ??= ClassTimelineDto(
                            matchTime: DateTime.now(),
                            currentTime: DateTime.now(),
                            classTime: DateTime.now(),
                            canCancel: false,
                            canStart: false,
                            canReportNoShow: true,
                            canConfirmStart: false,
                            canReportPersonalNoShow: false,
                            canComplete: false,
                            noShowReportDeadline: DateTime.now().toIso8601String(),
                          );

                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => ReportNoShowModal(
                              classData: currentClass!,
                              timeline: tl!,
                              isPersonalNoShow: false, // Personal reportando Aluno
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
  }
}
