import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
// dependency_injection não é usado diretamente aqui
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_state.dart' as home_states;
import '../widgets/fluid_timer_widget.dart';
import '../../data/models/class_response_dto.dart';
import '../widgets/report_no_show_modal.dart';
import '../../data/models/report_no_show_dto.dart';
import '../../data/models/class_timeline_dto.dart';
import '../widgets/report_problem_modal.dart';
import '../bloc/classes_bloc.dart';
import '../bloc/classes_state.dart';
import '../bloc/classes_event.dart';
import '../../data/models/class_timer_state.dart';
import '../../../evaluation/presentation/pages/personal_evaluation_page.dart';

class ClassTrackingPage extends StatefulWidget {
  final Map<String, dynamic> aula;
  const ClassTrackingPage({super.key, required this.aula});

  @override
  State<ClassTrackingPage> createState() => _ClassTrackingPageState();
}

class _ClassTrackingPageState extends State<ClassTrackingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final classesBloc = context.read<ClassesBloc>();
      if (classesBloc.state is ClassesInitial) {
        classesBloc.add(const ClassesInitialize());
      }
      final classId = widget.aula['id']?.toString() ??
          widget.aula['classId']?.toString();
      if (classId != null) {
        // SSOT: prazos de no-show vêm do backend via timeline
        classesBloc.add(ClassesUpdateTimeline(classId: classId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final aula = widget.aula;
    final personalName = aula['personalName'] ?? 'Personal Trainer';
    final years = aula['years'] ?? '0 dias';
    final avatarUrl = aula['avatarUrl'] as String?;
    final classId = aula['id']?.toString() ?? 
                   aula['classId']?.toString() ??
                   aula['studentName']?.toString() ?? 
                   aula['time']?.toString() ?? 
                   'unknown_class';

    return BlocListener<ClassesBloc, ClassesState>(
      listener: (context, state) {
        if (state is ClassesCompleteSuccess) {
          // Verificar se é a aula correta
          if (state.completedClass.id == classId) {
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
          } else {
            print('🔔 [STUDENT_TRACKING] Aula não corresponde - ignorando');
          }
        }
      },
      child: BlocBuilder<ClassesBloc, ClassesState>(
      builder: (context, state) {
        ClassTimerState? timerState;
        String displayedRating = '0.0';
        ClassTimelineDto? timeline;
        
        ClassResponseDto? _currentClass;
        if (state is ClassesLoaded) {
          timerState = state.timers[classId];
          timeline = state.timelines[classId];
          // Buscar aula atual para obter rating real do personal
          try {
            final classData = state.classes.firstWhere((c) => c.id == classId);
            _currentClass = classData;
            
            // 🔍 DEBUG: Log para investigar o problema do rating
            print('⭐ [STUDENT_TRACKING] === BUSCANDO RATING DO PERSONAL ===');
            print('⭐ [STUDENT_TRACKING] classData.id: ${classData.id}');
            print('⭐ [STUDENT_TRACKING] classData.personalRating: ${classData.personalRating}');
            
            // Fonte única: priorizar rating do HomeBloc (mesmo do DynamicWorkoutCard),
            // depois o rating da classe, e por último o rating do objeto "aula".
            double? ratingFromHome;
            try {
              final homeState = context.read<HomeBloc>().state;
              if (homeState is home_states.HomeLoaded) {
                final data = homeState.homeState.workoutCardData;
                print('⭐ [STUDENT_TRACKING] workoutCardData: $data');
                if (data != null) {
                  final raw = data['personalRating'];
                  print('⭐ [STUDENT_TRACKING] raw personalRating from HomeBloc: $raw (tipo: ${raw.runtimeType})');
                  if (raw is num) {
                    ratingFromHome = raw.toDouble();
                    print('⭐ [STUDENT_TRACKING] ratingFromHome (num->double): $ratingFromHome');
                  } else if (raw is String) {
                    // ✅ Converter vírgula para ponto antes de parsear
                    final fixedRaw = raw.replaceAll(',', '.');
                    ratingFromHome = double.tryParse(fixedRaw);
                    print('⭐ [STUDENT_TRACKING] ratingFromHome (String->double): $ratingFromHome (original: $raw)');
                  }
                } else {
                  print('⭐ [STUDENT_TRACKING] workoutCardData é null');
                }
              } else {
                print('⭐ [STUDENT_TRACKING] HomeBloc state não é HomeLoaded: ${homeState.runtimeType}');
              }
            } catch (e) {
              print('⚠️ [STUDENT_TRACKING] Erro ao buscar rating do HomeBloc: $e');
            }

            final classRating = classData.personalRating; // já em double?
            print('⭐ [STUDENT_TRACKING] classRating (ClassesBloc): $classRating');
            
            // ✅ CORREÇÃO: Converter vírgula para ponto antes de parsear
            final aulaRatingStr = (aula['personalRating'] ?? aula['rating'] ?? '').toString();
            final aulaRatingStrFixed = aulaRatingStr.replaceAll(',', '.');
            final upstreamRating = double.tryParse(aulaRatingStrFixed);
            print('⭐ [STUDENT_TRACKING] upstreamRating (aula): $upstreamRating (original: $aulaRatingStr)');

            // ✅ Priorizar rating do HomeBloc (mesma fonte do DynamicWorkoutCard)
            // Se nenhum rating válido (> 0) for encontrado, usar 5.0 como padrão (rating inicial como Uber)
            final resolved = (ratingFromHome != null && ratingFromHome > 0) 
                ? ratingFromHome 
                : (classRating != null && classRating > 0)
                    ? classRating
                    : (upstreamRating != null && upstreamRating > 0)
                        ? upstreamRating
                        : 5.0; // Default para 5.0 (rating inicial) ao invés de 0.0
            displayedRating = resolved.toStringAsFixed(1);
            print('⭐ [STUDENT_TRACKING] Rating resolvido final: $displayedRating (fontes: HomeBloc=$ratingFromHome, ClassesBloc=$classRating, aula=$upstreamRating)');
          } catch (e) {
            print('🔎 [STUDENT_TRACKING] Não foi possível localizar a aula por ID: $e');
            // Heurística: tentar localizar pela identidade do personal
            try {
              final fallback = state.classes.firstWhere(
                (c) => (c.personalName.trim().toLowerCase() == personalName.toString().trim().toLowerCase()),
              );
              final pr = fallback.personalRating;
              print('🔎 [STUDENT_TRACKING] Fallback por personalName encontrou rating=${pr?.toStringAsFixed(1)}');
              if (pr != null && pr > 0) {
                displayedRating = pr.toStringAsFixed(1);
              } else {
                // Tentar buscar do HomeBloc ou objeto aula
                double? ratingFromHome;
                try {
                  final homeState = context.read<HomeBloc>().state;
                  if (homeState is home_states.HomeLoaded) {
                    final data = homeState.homeState.workoutCardData;
                    final raw = data != null ? data['personalRating'] : null;
                    if (raw is num) ratingFromHome = raw.toDouble();
                    if (raw is String) {
                      ratingFromHome = double.tryParse(raw.replaceAll(',', '.'));
                    }
                  }
                } catch (_) {}
                
                if (ratingFromHome != null && ratingFromHome > 0) {
                  displayedRating = ratingFromHome.toStringAsFixed(1);
                } else {
                  // Se não encontrar, tentar buscar do objeto aula original
                  final aulaRatingStr = (aula['personalRating'] ?? aula['rating'] ?? '').toString();
                  final aulaRatingStrFixed = aulaRatingStr.replaceAll(',', '.');
                  final parsed = double.tryParse(aulaRatingStrFixed);
                  displayedRating = (parsed != null && parsed > 0) ? parsed.toStringAsFixed(1) : '5.0';
                }
              }
            } catch (_) {
              // Se não encontrar, tentar buscar do objeto aula original
              final aulaRatingStr = (aula['personalRating'] ?? aula['rating'] ?? '').toString();
              final aulaRatingStrFixed = aulaRatingStr.replaceAll(',', '.');
              final parsed = double.tryParse(aulaRatingStrFixed);
              displayedRating = (parsed != null && parsed > 0) ? parsed.toStringAsFixed(1) : '5.0';
            }
          }
        } else {
          // Se não está em ClassesLoaded, usar rating do objeto aula ou HomeBloc
          double? ratingFromHome;
          try {
            final homeState = context.read<HomeBloc>().state;
            if (homeState is home_states.HomeLoaded) {
              final data = homeState.homeState.workoutCardData;
              final raw = data != null ? data['personalRating'] : null;
              if (raw is num) ratingFromHome = raw.toDouble();
              if (raw is String) {
                ratingFromHome = double.tryParse(raw.replaceAll(',', '.'));
              }
            }
          } catch (_) {}
          
          if (ratingFromHome != null && ratingFromHome > 0) {
            displayedRating = ratingFromHome.toStringAsFixed(1);
          } else {
            final aulaRatingStr = (aula['personalRating'] ?? aula['rating'] ?? '').toString();
            final aulaRatingStrFixed = aulaRatingStr.replaceAll(',', '.');
            final parsed = double.tryParse(aulaRatingStrFixed);
            displayedRating = (parsed != null && parsed > 0) ? parsed.toStringAsFixed(1) : '5.0';
          }
        }
        
        // Timer efetivo para exibição imediata (evita flash de 0s ao entrar)
        final ClassTimerState effectiveTimerState = (() {
          if (timerState != null) return timerState;
          final cls0 = _currentClass;
          final start0 = cls0?.startTime;
          if (cls0 != null && start0 != null) {
            final ClassResponseDto cls = cls0;
            final DateTime start = start0;
            final int durationMin = cls.duration;
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
        
        // SSOT: canReportPersonalNoShow vem da timeline da API
        final canReportPersonalNoShow =
            timeline?.canReportPersonalNoShow ?? false;

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
            // ✅ Voltar para a página anterior (StudentClassesPage)
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

              // Info card
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
                    avatarUrl != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(avatarUrl),
                            radius: 28,
                          )
                        : CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFFE6E9EE),
                            child: Text(
                              personalName
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
                            personalName,
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
                                Icons.star,
                                color: AppColors.primaryOrange,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              // Rating consistente com ProposalStatusModal/DynamicWorkoutCard
                              Text(
                                displayedRating,
                                style: const TextStyle(fontFamily: 'Fira Sans'),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '|',
                                style: TextStyle(color: Color(0xFF2D3748)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                years,
                                style: const TextStyle(fontFamily: 'Fira Sans'),
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                              'Aproveite sua aula! Lembre-se de seguir as orientações do seu personal trainer e não hesite em tirar dúvidas durante o treino.',
                              style: const TextStyle(
                                fontFamily: 'Fira Sans',
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // indicadores removidos temporariamente
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
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
            if (canReportPersonalNoShow && 
                (_currentClass?.status == ClassStatus.SCHEDULED || 
                 _currentClass?.status == ClassStatus.PENDING_CONFIRMATION)) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentClass == null || timeline == null) return;

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => ReportNoShowModal(
                        classData: _currentClass!,
                        timeline: timeline!,
                        isPersonalNoShow: true,
                        onReport: (reportData) {
                          context.read<ClassesBloc>().add(
                                ClassesReportPersonalNoShow(
                                  classId: _currentClass!.id,
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
                        'Personal não compareceu / Abrir Disputa',
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
                  side: const BorderSide(color: AppColors.primaryOrange, width: 2),
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
    ));
      },
      ),
    );
  }

}