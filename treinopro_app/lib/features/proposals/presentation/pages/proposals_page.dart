import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../bloc/proposals_bloc.dart';
import '../bloc/proposals_event.dart';
import '../bloc/proposals_state.dart';
import '../../data/models/proposal_response_dto.dart';
import '../../../health_questionnaire/health_questionnaire.dart';
import '../../../../core/services/realtime_data_service.dart';

class ProposalsPage extends StatelessWidget {
  const ProposalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Reutiliza um ProposalsBloc já existente no contexto, se houver.
    // Caso contrário, cria um novo via DI.
    try {
      final existing = context.read<ProposalsBloc>();
      if (!existing.isClosed) {
        return const _ProposalsPageView();
      }
    } catch (_) {
      // Nenhum ProposalsBloc no contexto — cria um local
    }

    return BlocProvider(
      create: (_) => sl<ProposalsBloc>(),
      child: const _ProposalsPageView(),
    );
  }
}

class _ProposalsPageView extends StatefulWidget {
  const _ProposalsPageView();

  @override
  State<_ProposalsPageView> createState() => _ProposalsPageViewState();
}

class _ProposalsPageViewState extends State<_ProposalsPageView> with WidgetsBindingObserver {
  // filtros
  String? _selectedDate;
  String? _selectedTime;
  String? _selectedCategory;

  final List<String> _dates = [
    'Hoje',
    'Amanhã',
    'Esta Semana',
    'Próxima Semana',
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
  void initState() {
    super.initState();
    // ✅ CORREÇÃO: Adicionar observer para detectar ciclo de vida do app
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final bloc = context.read<ProposalsBloc>();
          // Garantir que o RealtimeDataService aponte para o ProposalsBloc ativo desta tela
          try {
            sl<RealtimeDataService>().attachProposalsBloc(bloc);
          } catch (_) {}
          if (!bloc.isClosed) {
            bloc.add(const ProposalsConnectWebSocket());
            bloc.add(const ProposalsLoadAvailable());
          }
        } catch (e) {
          debugPrint('❌ [PROPOSALS] Erro ao inicializar bloc: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    // ✅ CORREÇÃO: Remover observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ CORREÇÃO: Detectar quando app volta do repouso
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 [PROPOSALS_PAGE] App voltou ao foreground - reconectando...');
      
      if (mounted) {
        try {
          final bloc = context.read<ProposalsBloc>();
          
          // Reanexar o bloc ao RealtimeDataService (pode ter sido perdido)
          try {
            sl<RealtimeDataService>().attachProposalsBloc(bloc);
            debugPrint('✅ [PROPOSALS_PAGE] ProposalsBloc reanexado ao RealtimeDataService');
          } catch (e) {
            debugPrint('⚠️ [PROPOSALS_PAGE] Erro ao reanexar bloc: $e');
          }
          
          if (!bloc.isClosed) {
            // Verificar se WebSocket está conectado
            final currentState = bloc.state;
            if (currentState is ProposalsAvailableLoaded) {
              if (!currentState.isWebSocketConnected) {
                debugPrint('🔄 [PROPOSALS_PAGE] WebSocket desconectado - reconectando...');
                bloc.add(const ProposalsConnectWebSocket());
              }
            }
            
            // Recarregar propostas para sincronizar após sleep
            debugPrint('🔄 [PROPOSALS_PAGE] Recarregando propostas após resume...');
            bloc.add(const ProposalsLoadAvailable());
          }
        } catch (e) {
          debugPrint('❌ [PROPOSALS_PAGE] Erro ao reconectar após resume: $e');
        }
      }
    }
  }

  bool _hasActiveFilters() =>
      _selectedDate != null ||
      _selectedTime != null ||
      _selectedCategory != null;

  void _clearAllFilters() {
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      _selectedCategory = null;
    });
    context.read<ProposalsBloc>().add(const ProposalsUpdateFilters());
  }

  void _showMatchModal(ProposalResponseDto proposal) {
    final proposalsBloc = context.read<ProposalsBloc>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Confirmar aceitação',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        content: Text(
          'Deseja aceitar a proposta de ${proposal.student.name} por R\$ ${proposal.price.toStringAsFixed(2)}?',
          style: const TextStyle(
            fontFamily: 'Fira Sans',
            fontSize: 14,
            color: Color(0xFF42464D),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'Fira Sans',
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              proposalsBloc.add(ProposalsAcceptProposal(proposal.id));
            },
            child: const Text(
              'Aceitar',
              style: TextStyle(
                fontFamily: 'Fira Sans',
            color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentHealthModal(ProposalResponseDto proposal) {
    showDialog(
      context: context,
      builder: (context) => StudentHealthModal(
        studentId: proposal.student.id,
        studentName: proposal.student.name,
        studentProfileImage: '', // TODO: Adicionar campo no backend
        studentScore: 0, // TODO: Adicionar campo no backend
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

  String _getTimeDisplayName(String? timeValue) {
    if (timeValue == null) return '';
    return timeValue.split(' (')[0];
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
                              : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              option,
                              style: const TextStyle(
                                fontFamily: 'Fira Sans',
                                fontSize: 16,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check, color: AppColors.primaryOrange),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProposalCard(ProposalResponseDto proposal) {
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
                onTap: () => _showStudentHealthModal(proposal),
                child: Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(23.5),
                    border: Border.all(color: AppColors.primaryOrange, width: 2),
                    color: const Color(0xFFF3F3F3),
                  ),
                  child: _buildStudentInitialsAvatar(
                    proposal.student.name,
                    photoUrl: proposal.student.profilePicture,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            proposal.student.name,
                            style: const TextStyle(
                              fontFamily: 'Fira Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ),
                        Text(
                          'R\$ ${proposal.price.round()}',
                          style: const TextStyle(
                            fontFamily: 'Fira Sans',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
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
                            proposal.locationName,
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
              _buildInfoItem(Icons.calendar_today, 'Data', _formatDate(proposal.trainingDate)),
              _buildInfoItem(
                Icons.access_time,
                'Horário',
                proposal.trainingTime,
              ),
              _buildInfoItem(Icons.timer, 'Duração', '${proposal.durationMinutes}min'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showMatchModal(proposal),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Aceitar',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Fira Sans',
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
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

  /// Cria avatar com iniciais do nome do aluno ou foto se disponível
  Widget _buildStudentInitialsAvatar(String studentName, {String? photoUrl}) {
    final initials = _getStudentInitials(studentName);
    
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
                errorBuilder: (context, error, stackTrace) => _buildInitialsText(initials),
              ),
            )
          : _buildInitialsText(initials),
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
    
    final words = name.trim().split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else {
      return '${words[0][0].toUpperCase()}${words[1][0].toUpperCase()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProposalsBloc, ProposalsState>(
      listener: (context, state) {
        if (state is ProposalsOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ProposalsOperationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<ProposalsBloc, ProposalsState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFFCFDFE),
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  final bloc = context.read<ProposalsBloc>();
                  if (!bloc.isClosed) {
                    bloc.add(const ProposalsRefresh());
                  }
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
                      const Center(
                        child: Text(
                          'Propostas',
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
                children: const [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Filtros',
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
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
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.clear_rounded,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Limpar',
                          style: TextStyle(
                            fontFamily: 'Fira Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
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
                  (v) => setState(() => _selectedDate = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'Horário',
                  _selectedTime,
                  _times,
                  Icons.access_time_rounded,
                  (v) => setState(() => _selectedTime = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'Categoria',
                  _selectedCategory,
                  _categories,
                  Icons.category_rounded,
                  (v) => setState(() => _selectedCategory = v),
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
                if (_selectedDate != null)
                  _buildActiveFilterTag('Data', _selectedDate!, () {
                    setState(() => _selectedDate = null);
                  }),
                if (_selectedTime != null)
                  _buildActiveFilterTag(
                    'Horário',
                    _getTimeDisplayName(_selectedTime),
                    () {
                      setState(() => _selectedTime = null);
                    },
                  ),
                if (_selectedCategory != null)
                  _buildActiveFilterTag(
                    'Categoria',
                    _selectedCategory!,
                    () {
                      setState(() => _selectedCategory = null);
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(ProposalsState state) {
    if (state is ProposalsAvailableLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is ProposalsAvailableError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar propostas',
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<ProposalsBloc>().add(const ProposalsRefresh()),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    // Mostrar loading apenas para estados de carregamento inicial
    // ProposalsOperationInProgress e ProposalsOperationFailure mantêm a lista visível
    if (state is ProposalsOperationInProgress || state is ProposalsOperationFailure) {
      // Manter a lista visível durante operações
      final proposals = state is ProposalsOperationInProgress 
          ? state.proposals
          : (state as ProposalsOperationFailure).proposals;
      
      if (proposals.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_note,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma proposta encontrada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }
      
      return Column(
        children: proposals
            .map(
              (proposal) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildProposalCard(proposal),
              ),
            )
            .toList(),
      );
    }
    
    if (state is! ProposalsAvailableLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.proposals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma proposta encontrada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajuste os filtros ou aguarde novas propostas',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: state.proposals
          .map(
            (proposal) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildProposalCard(proposal),
            ),
          )
          .toList(),
    );
  }
}
