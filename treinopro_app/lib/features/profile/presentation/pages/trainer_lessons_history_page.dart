import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../classes/presentation/bloc/classes_history_bloc.dart';
import '../../../classes/data/services/classes_api_service.dart';
import '../../../classes/data/models/class_response_dto.dart';
import '../../../../core/di/dependency_injection.dart' show sl;

const _kIconColor = AppColors.primaryOrange;

class TrainerLessonsHistoryPage extends StatefulWidget {
  const TrainerLessonsHistoryPage({super.key});

  @override
  State<TrainerLessonsHistoryPage> createState() => _TrainerLessonsHistoryPageState();
}

class _TrainerLessonsHistoryPageState extends State<TrainerLessonsHistoryPage> {
  // Variáveis dos filtros de aulas
  String? _selectedDate;
  String? _selectedTime;
  String? _selectedCategory;

  // Valores para os filtros de aulas
  final List<String> _dates = [
    'Hoje',
    'Amanhã',
    'Esta semana',
    'Próxima semana',
    'Este Mês',
  ];

  final List<String> _times = [
    'Manhã (06:00-12:00)',
    'Tarde (12:00-18:00)',
    'Noite (18:00-23:00)',
  ];

  final List<String> _categories = [
    'Musculação',
    'Funcional',
    'Cardio',
    'Crossfit',
    'Pilates',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ClassesHistoryBloc(
        classesApiService: sl<ClassesApiService>(),
      )..add(const ClassesHistoryLoad()),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFFCFDFE),
          elevation: 0,
          leading: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.chevron_left, color: _kIconColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Histórico de aulas',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          centerTitle: true,
        ),
        backgroundColor: const Color(0xFFFCFDFE),
        body: Column(
          children: [
            // Seção de filtros
            _buildFilterSection(),
            // Conteúdo principal
            Expanded(
              child: BlocBuilder<ClassesHistoryBloc, ClassesHistoryState>(
                builder: (context, state) {
            if (state is ClassesHistoryLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is ClassesHistoryError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.error_outline,
                          size: 40,
                          color: Colors.red.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Erro ao carregar histórico',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => context.read<ClassesHistoryBloc>().add(
                              const ClassesHistoryRefresh(),
                            ),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Tentar novamente'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: const Text('Voltar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is ClassesHistoryLoaded) {
              final filteredClasses = _getFilteredClasses(state.classes);
              
              if (filteredClasses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _hasActiveFilters() ? Icons.search_off : Icons.history,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _hasActiveFilters() ? 'Nenhuma aula encontrada' : 'Nenhuma aula no histórico',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _hasActiveFilters() 
                          ? 'Tente ajustar os filtros para encontrar aulas'
                          : 'Suas aulas concluídas aparecerão aqui',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.separated(
                  itemCount: filteredClasses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final classData = filteredClasses[index];
                    return _buildLessonCardFromClass(classData);
                  },
                ),
              );
            }

            return const Center(
              child: CircularProgressIndicator(),
            );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cria texto das iniciais
  Widget _buildInitialsText(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF2D3748),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Extrai iniciais de um nome completo
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Avatar do aluno (usa URL quando disponível, senão iniciais)
  Widget _buildStudentAvatar(String studentName, {String? photoUrl}) {
    final initials = _getInitials(studentName);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 47,
        height: 47,
        color: const Color(0xFFE2E8F0),
        child: (photoUrl != null && photoUrl.isNotEmpty)
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _buildInitialsText(initials),
              )
            : _buildInitialsText(initials),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
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
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'Categoria',
                  _selectedCategory,
                  _categories,
                  Icons.category_rounded,
                  (value) {
                    setState(() => _selectedCategory = value);
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

  bool _hasActiveFilters() {
    return _selectedDate != null ||
        _selectedTime != null ||
        _selectedCategory != null;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      _selectedCategory = null;
    });
  }

  String _getTimeDisplayName(String? timeValue) {
    if (timeValue == null) return '';
    return timeValue.split(' (')[0];
  }

  List<ClassResponseDto> _getFilteredClasses(List<ClassResponseDto> classes) {
    List<ClassResponseDto> filtered = List.from(classes);

    // Aplicar filtro de data
    if (_selectedDate != null) {
      filtered = filtered.where((classData) {
        final classDate = classData.date;
        final now = DateTime.now();
        
        switch (_selectedDate) {
          case 'Hoje':
            return _isSameDay(classDate, now);
          case 'Amanhã':
            final tomorrow = now.add(const Duration(days: 1));
            return _isSameDay(classDate, tomorrow);
          case 'Esta semana':
            return _isThisWeek(classDate, now);
          case 'Próxima semana':
            return _isNextWeek(classDate, now);
          case 'Este Mês':
            return _isThisMonth(classDate, now);
          default:
            return true;
        }
      }).toList();
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

    // Aplicar filtro de categoria
    if (_selectedCategory != null) {
      filtered = filtered.where((classData) {
        return classData.proposalModality == _selectedCategory;
      }).toList();
    }

    // Ordenar por data (mais recentes primeiro)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  bool _isThisWeek(DateTime classDate, DateTime now) {
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return classDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           classDate.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  bool _isNextWeek(DateTime classDate, DateTime now) {
    final nextWeekStart = now.add(Duration(days: 8 - now.weekday));
    final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
    
    return classDate.isAfter(nextWeekStart.subtract(const Duration(days: 1))) &&
           classDate.isBefore(nextWeekEnd.add(const Duration(days: 1)));
  }

  bool _isThisMonth(DateTime classDate, DateTime now) {
    return classDate.year == now.year && classDate.month == now.month;
  }

  Widget _buildLessonCardFromClass(ClassResponseDto classData) {
    final statusColor = _getStatusColorFromClass(classData.status);
    final statusText = _getStatusTextFromClass(classData.status);
    final studentName = '${classData.studentFirstName ?? ''} ${classData.studentLastName ?? ''}'.trim();
    final location = classData.location;
    final price = classData.proposalPrice ?? 0.0;
    
    // Log para verificar valores da API
    print('🔍 [TRAINER_HISTORY] Aula ${classData.id}:');
    print('  - Preço da proposta: ${classData.proposalPrice}');
    print('  - Preço final: $price');
    print('  - Personal Rating: ${classData.personalRating}');
    print('  - Student Rating: ${classData.studentRating}');
    print('  - Modalidade: ${classData.proposalModality}');
    
    final rating = classData.studentRating?.round() ?? 5; // Usar avaliação real do aluno

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status e Modalidade chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  // Modalidade chip
                  if (classData.proposalModality != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kIconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        classData.proposalModality!,
                        style: const TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kIconColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
          
          // Informações do aluno
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _kIconColor,
                    width: 1.5,
                  ),
                ),
                child: _buildStudentAvatar(
                  studentName,
                  photoUrl: classData.studentProfileImageUrl,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Avaliação: mostra estrelas laranja conforme rating
                    Row(
                      children: List.generate(5, (s) {
                        final filled = s < rating;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Icon(
                            Icons.star,
                            size: 20,
                            color: filled
                                ? _kIconColor
                                : const Color(0xFFBDBDBD),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              // Valor da aula
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Valor',
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 12,
                      color: Color(0xFF42464D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(
            color: Color(0xFFA6A6A6),
            height: 1,
            thickness: 0.6,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn(
                Icons.calendar_today,
                'Data',
                _formatDate(classData.date),
              ),
              _buildInfoColumn(
                Icons.access_time,
                'Horário',
                classData.time,
              ),
              _buildInfoColumn(
                Icons.place,
                'Local',
                location,
                flex: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }


  Color _getStatusColorFromClass(ClassStatus status) {
    switch (status) {
      case ClassStatus.COMPLETED:
        return Colors.green;
      case ClassStatus.CANCELLED:
        return Colors.orange;
      case ClassStatus.NO_SHOW_DISPUTE:
        return Colors.red;
      case ClassStatus.SCHEDULED:
        return Colors.blue;
      case ClassStatus.ACTIVE:
        return Colors.blue;
      case ClassStatus.PENDING_CONFIRMATION:
        return Colors.blue;
      case ClassStatus.CUSTODY:
        return Colors.blue;
    }
  }

  String _getStatusTextFromClass(ClassStatus status) {
    switch (status) {
      case ClassStatus.COMPLETED:
        return 'Concluída';
      case ClassStatus.CANCELLED:
        return 'Cancelada';
      case ClassStatus.NO_SHOW_DISPUTE:
        return 'Em Disputa';
      case ClassStatus.SCHEDULED:
        return 'Agendada';
      case ClassStatus.ACTIVE:
        return 'Ativa';
      case ClassStatus.PENDING_CONFIRMATION:
        return 'Aguardando Confirmação';
      case ClassStatus.CUSTODY:
        return 'Em Custódia';
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Widget _buildInfoColumn(
    IconData icon,
    String label,
    String value, {
    int flex = 1,
  }) {
    return Flexible(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                child: Icon(icon, size: 16, color: _kIconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
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
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }
}

enum LessonStatus { completed, scheduled, cancelled, dispute }

class TrainerLesson {
  final String title;
  final String student;
  final DateTime date;
  final LessonStatus status;
  final int rating;
  final double price;
  final String location;

  TrainerLesson({
    required this.title,
    required this.student,
    required this.date,
    required this.status,
    required this.rating,
    required this.price,
    required this.location,
  });
}
