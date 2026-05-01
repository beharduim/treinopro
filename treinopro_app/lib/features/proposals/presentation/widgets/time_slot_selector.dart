import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/services/proposals_api_service.dart';

/// Seletor de horários com picker de hora e minuto
class TimeSlotSelector extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onTimeChanged;
  final bool isLoading;
  final DateTime?
  selectedDate; // Data selecionada para validar horários passados
  final ProposalsApiService?
  apiService; // Serviço da API para buscar conflitos reais

  const TimeSlotSelector({
    super.key,
    this.initialValue,
    required this.onTimeChanged,
    this.isLoading = false,
    this.selectedDate,
    this.apiService,
  });

  @override
  State<TimeSlotSelector> createState() => _TimeSlotSelectorState();
}

class _TimeSlotSelectorState extends State<TimeSlotSelector> {
  late TextEditingController _controller;
  TimeOfDay? _selectedTime;
  TimeConflictsResponse? _timeConflicts;
  bool _isLoadingConflicts = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _parseInitialTime();
    _loadTimeConflicts();
  }

  @override
  void didUpdateWidget(TimeSlotSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarregar conflitos se a data mudou
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadTimeConflicts();
    }
  }

  Future<void> _loadTimeConflicts() async {
    if (widget.apiService == null || widget.selectedDate == null) {
      print(
        '⚠️ [CONFLICTS] Não carregando conflitos - apiService: ${widget.apiService != null}, selectedDate: ${widget.selectedDate != null}',
      );
      return;
    }

    print(
      '🔍 [CONFLICTS] Carregando conflitos para data: ${widget.selectedDate}',
    );

    setState(() {
      _isLoadingConflicts = true;
    });

    try {
      final dateString = widget.selectedDate!.toIso8601String().split('T')[0];
      print('🔍 [CONFLICTS] Data string: $dateString');

      final conflicts = await widget.apiService!.getTimeConflicts(dateString);

      print('✅ [CONFLICTS] Conflitos carregados:');
      print('  - Propostas existentes: ${conflicts.existingProposals.length}');
      print('  - Aulas em match: ${conflicts.matchedClasses.length}');
      print('  - Horários bloqueados: ${conflicts.blockedTimeSlots}');

      setState(() {
        _timeConflicts = conflicts;
        _isLoadingConflicts = false;
      });
    } catch (e) {
      print('❌ [CONFLICTS] Erro ao carregar conflitos de horários: $e');
      setState(() {
        _isLoadingConflicts = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parseInitialTime() {
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      // Tentar parsear horário no formato HH:mm
      final timeRegex = RegExp(r'(\d{1,2}):(\d{2})');
      final match = timeRegex.firstMatch(widget.initialValue!);
      if (match != null) {
        final hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
          _selectedTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }
  }

  /// Verifica se o horário está no passado
  bool _isTimeInPast(TimeOfDay time) {
    if (widget.selectedDate == null) return false;

    final now = DateTime.now();
    final selectedDateTime = DateTime(
      widget.selectedDate!.year,
      widget.selectedDate!.month,
      widget.selectedDate!.day,
      time.hour,
      time.minute,
    );

    return selectedDateTime.isBefore(now);
  }

  /// Verifica se um horário está indisponível (conflito de agendamento)
  bool _isTimeUnavailable(TimeOfDay time) {
    if (widget.selectedDate == null) {
      return false;
    }

    // Converter TimeOfDay para minutos desde 00:00
    int candidateStart = time.hour * 60 + time.minute;
    // Duração padrão de 60 minutos (o passo do seletor)
    int candidateEnd = candidateStart + 60;

    // Checagem de sobreposição contra propostas e aulas retornadas pela API
    if (_timeConflicts != null) {
      // Verificar propostas existentes (pending/matched)
      for (final p in _timeConflicts!.existingProposals) {
        try {
          final parts = p.trainingTime.split(':');
          final start = int.parse(parts[0]) * 60 + int.parse(parts[1]);
          final end =
              start + (p.durationMinutes != null ? p.durationMinutes! : 60);
          final overlaps = candidateStart < end && candidateEnd > start;
          if (overlaps && (p.status == 'pending' || p.status == 'matched')) {
            print('❌ [TIME VALIDATION] Sobreposição com proposta ${p.id}');
            return true;
          }
        } catch (_) {}
      }

      // Verificar aulas em match (scheduled/active)
      for (final c in _timeConflicts!.matchedClasses) {
        try {
          final parts = c.time.split(':');
          final start = int.parse(parts[0]) * 60 + int.parse(parts[1]);
          final end = start + (c.duration != null ? c.duration! : 60);
          final overlaps = candidateStart < end && candidateEnd > start;
          if (overlaps && (c.status == 'scheduled' || c.status == 'active')) {
            print('❌ [TIME VALIDATION] Sobreposição com aula ${c.id}');
            return true;
          }
        } catch (_) {}
      }
    }

    // Se não há conflitos detectados, considerar disponível (backend ainda valida)
    print('✅ [TIME VALIDATION] Horário disponível (sem sobreposição)');
    return false;
  }

  /// Verifica se um horário é válido (não é passado nem conflitante)
  bool _isTimeValid(TimeOfDay time) {
    return !_isTimeInPast(time) && !_isTimeUnavailable(time);
  }

  /// Retorna mensagem de erro para horário inválido
  String? _getTimeValidationError(TimeOfDay time) {
    if (_isTimeInPast(time)) {
      return 'Não é possível agendar no passado';
    }

    if (widget.selectedDate == null) return null;

    // Reutiliza a mesma regra de sobreposição da função acima para montar mensagem
    if (_timeConflicts != null) {
      final candidateStart = time.hour * 60 + time.minute;
      final candidateEnd = candidateStart + 60;

      for (final p in _timeConflicts!.existingProposals) {
        try {
          final parts = p.trainingTime.split(':');
          final start = int.parse(parts[0]) * 60 + int.parse(parts[1]);
          final end =
              start + (p.durationMinutes != null ? p.durationMinutes! : 60);
          final overlaps = candidateStart < end && candidateEnd > start;
          if (overlaps && (p.status == 'pending' || p.status == 'matched')) {
            final status = p.status == 'pending' ? 'pendente' : 'em andamento';
            return 'Horário indisponível. Você já tem uma proposta $status nesse intervalo.';
          }
        } catch (_) {}
      }

      for (final c in _timeConflicts!.matchedClasses) {
        try {
          final parts = c.time.split(':');
          final start = int.parse(parts[0]) * 60 + int.parse(parts[1]);
          final end = start + (c.duration != null ? c.duration! : 60);
          final overlaps = candidateStart < end && candidateEnd > start;
          if (overlaps && (c.status == 'scheduled' || c.status == 'active')) {
            final status = c.status == 'scheduled' ? 'agendada' : 'ativa';
            return 'Horário indisponível. Já existe uma aula $status nesse intervalo.';
          }
        } catch (_) {}
      }
    }

    return null;
  }

  Future<void> _selectTime(BuildContext context) async {
    int hour = _selectedTime?.hour ?? TimeOfDay.now().hour;
    int minute = _selectedTime?.minute ?? TimeOfDay.now().minute;

    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) =>
          _TimePickerDialog(initialHour: hour, initialMinute: minute),
    );

    if (result != null && result != _selectedTime) {
      // Validar horário selecionado
      final validationError = _getTimeValidationError(result);

      if (validationError != null) {
        // Mostrar erro se horário for inválido
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationError),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return; // Não atualizar o horário
      }

      // Horário válido, atualizar
      setState(() {
        _selectedTime = result;
        final timeString =
            '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}';
        _controller.text = timeString;
        widget.onTimeChanged(timeString);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading || _isLoadingConflicts) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo curto e elegante para seleção de horário
        GestureDetector(
          onTap: () => _selectTime(context),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedTime != null && !_isTimeValid(_selectedTime!)
                    ? Colors.red
                    : AppColors.secondaryDark.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  // Texto do horário
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _selectedTime != null
                                  ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                  : 'Selecionar horário',
                              style: AppTextStyles.paragraph.copyWith(
                                color: _selectedTime != null
                                    ? AppColors.secondary
                                    : AppColors.secondaryDark.withValues(
                                        alpha: 0.6,
                                      ),
                                fontWeight: _selectedTime != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            // Indicador de validação
                            if (_selectedTime != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                _isTimeValid(_selectedTime!)
                                    ? Icons.check_circle
                                    : Icons.error,
                                size: 16,
                                color: _isTimeValid(_selectedTime!)
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedTime != null && !_isTimeValid(_selectedTime!)
                              ? _getTimeValidationError(_selectedTime!)!
                              : 'Toque para escolher o horário',
                          style: AppTextStyles.small.copyWith(
                            color:
                                _selectedTime != null &&
                                    !_isTimeValid(_selectedTime!)
                                ? Colors.red
                                : AppColors.secondaryDark.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ícone de seta
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.secondaryDark.withValues(alpha: 0.6),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dialog customizado para seleção de horário com inputs
class _TimePickerDialog extends StatefulWidget {
  final int initialHour;
  final int initialMinute;

  const _TimePickerDialog({
    required this.initialHour,
    required this.initialMinute,
  });

  @override
  State<_TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialHour;
    _minute = widget.initialMinute;
  }

  void _incrementHour() {
    setState(() {
      _hour = (_hour + 1) % 24;
    });
  }

  void _incrementMinute() {
    setState(() {
      _minute = (_minute + 1) % 60;
    });
  }

  void _decrementMinute() {
    setState(() {
      _minute = (_minute - 1 + 60) % 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Text(
              'Selecionar Horário',
              style: AppTextStyles.h6Semibold.copyWith(
                color: AppColors.secondary,
              ),
            ),

            const SizedBox(height: 24),

            // Inputs de hora e minuto
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Input de Hora
                _TimeInput(
                  value: _hour,
                  label: 'Hora',
                  onIncrement: _incrementHour,
                  onDecrement: () {
                    setState(() {
                      _hour = (_hour - 1 + 24) % 24;
                    });
                  },
                  onValueChanged: (value) {
                    setState(() {
                      _hour = value;
                    });
                  },
                  maxValue: 23,
                ),

                // Separador
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    ':',
                    style: AppTextStyles.h6Semibold.copyWith(
                      color: AppColors.secondary,
                      fontSize: 32,
                    ),
                  ),
                ),

                // Input de Minuto
                _TimeInput(
                  value: _minute,
                  label: 'Minuto',
                  onIncrement: _incrementMinute,
                  onDecrement: _decrementMinute,
                  onValueChanged: (value) {
                    setState(() {
                      _minute = value;
                    });
                  },
                  maxValue: 59,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Botões
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: AppColors.secondaryDark.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: AppTextStyles.paragraph.copyWith(
                        color: AppColors.secondaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(TimeOfDay(hour: _hour, minute: _minute)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirmar',
                      style: AppTextStyles.paragraph.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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
}

/// Input individual para hora ou minuto
class _TimeInput extends StatefulWidget {
  final int value;
  final String label;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<int> onValueChanged;
  final int maxValue;

  const _TimeInput({
    required this.value,
    required this.label,
    required this.onIncrement,
    required this.onDecrement,
    required this.onValueChanged,
    required this.maxValue,
  });

  @override
  State<_TimeInput> createState() => _TimeInputState();
}

class _TimeInputState extends State<_TimeInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value.toString().padLeft(2, '0'),
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_TimeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Só atualiza o controller se o valor mudou E o campo não está em foco
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value.toString().padLeft(2, '0');
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _validateAndUpdateValue();
    }
  }

  void _onTextChanged() {
    // Remove o listener temporariamente para evitar loops
    _controller.removeListener(_onTextChanged);

    final text = _controller.text;
    final value = int.tryParse(text);

    // Se o valor for válido e diferente do atual, atualiza imediatamente
    if (value != null &&
        value >= 0 &&
        value <= widget.maxValue &&
        value != widget.value) {
      widget.onValueChanged(value);
    }

    // Re-adiciona o listener
    _controller.addListener(_onTextChanged);
  }

  void _validateAndUpdateValue() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _controller.text = widget.value.toString().padLeft(2, '0');
      return;
    }

    final value = int.tryParse(text);
    if (value != null && value >= 0 && value <= widget.maxValue) {
      // Atualiza o valor no widget pai
      widget.onValueChanged(value);
      // Atualiza o controller com o valor formatado
      _controller.text = value.toString().padLeft(2, '0');
    } else {
      // Se o valor for inválido, reverte para o valor anterior
      _controller.text = widget.value.toString().padLeft(2, '0');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Label
        Text(
          widget.label,
          style: AppTextStyles.small.copyWith(
            color: AppColors.secondaryDark.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 8),

        // Container do input
        Container(
          width: 80,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.secondaryDark.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Botão de incremento
              Expanded(
                child: GestureDetector(
                  onTap: widget.onIncrement,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_up,
                      color: AppColors.primaryOrange,
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Campo de texto editável
              Expanded(
                child: Center(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    style: AppTextStyles.h6Semibold.copyWith(
                      color: AppColors.secondary,
                      fontSize: 24,
                      height: 1.0,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onSubmitted: (value) {
                      _validateAndUpdateValue();
                      _focusNode.unfocus();
                    },
                  ),
                ),
              ),

              // Botão de decremento
              Expanded(
                child: GestureDetector(
                  onTap: widget.onDecrement,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.primaryOrange,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
