import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/class_response_dto.dart';
import '../../data/models/class_timeline_dto.dart';
import 'timeline_completion_countdown.dart';

class ClassActionButtons extends StatefulWidget {
  final ClassResponseDto classData;
  final ClassTimelineDto timeline;
  final VoidCallback? onStartClass;
  final VoidCallback? onConfirmStart;
  final VoidCallback? onCompleteClass;
  final VoidCallback? onCancelClass;
  final VoidCallback? onReportNoShow;
  final VoidCallback? onReportPersonalNoShow;
  final VoidCallback? onChat;

  const ClassActionButtons({
    super.key,
    required this.classData,
    required this.timeline,
    this.onStartClass,
    this.onConfirmStart,
    this.onCompleteClass,
    this.onCancelClass,
    this.onReportNoShow,
    this.onReportPersonalNoShow,
    this.onChat,
  });

  @override
  State<ClassActionButtons> createState() => _ClassActionButtonsState();
}

class _ClassActionButtonsState extends State<ClassActionButtons> {
  late final TimelineCompletionCountdownController _countdown;

  @override
  void initState() {
    super.initState();
    _countdown = TimelineCompletionCountdownController()
      ..syncFromTimeline(widget.timeline);
  }

  @override
  void didUpdateWidget(ClassActionButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    _countdown.syncFromTimeline(widget.timeline);
  }

  @override
  void dispose() {
    _countdown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _countdown,
      builder: (context, _) {
        return Column(
          children: [
            _buildMainButtons(),
            if (_shouldShowDeadlineInfo()) ...[
              const SizedBox(height: 12),
              _buildDeadlineInfo(),
            ],
            if (widget.classData.status == ClassStatus.ACTIVE &&
                _countdown.showCountdown) ...[
              const SizedBox(height: 12),
              _buildCompletionCountdownInfo(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMainButtons() {
    switch (widget.classData.status) {
      case ClassStatus.SCHEDULED:
        return _buildScheduledButtons();
      case ClassStatus.PENDING_CONFIRMATION:
        return _buildPendingConfirmationButtons();
      case ClassStatus.ACTIVE:
        return _buildActiveButtons();
      case ClassStatus.NO_SHOW_DISPUTE:
        return _buildDisputeButtons();
      case ClassStatus.CUSTODY:
        return _buildCustodyButtons();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildScheduledButtons() {
    return Row(
      children: [
        if (widget.onChat != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onChat,
              icon: const Icon(Icons.chat, size: 16),
              label: const Text('Chat'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryOrange,
                side: const BorderSide(color: AppColors.primaryOrange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (widget.timeline.canCancel && widget.onCancelClass != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onCancelClass,
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.timeline.canStart ? widget.onStartClass : null,
            icon: Icon(
              Icons.play_circle,
              size: 16,
              color: widget.timeline.canStart ? Colors.white : Colors.grey,
            ),
            label: Text(
              'Iniciar aula',
              style: TextStyle(
                color: widget.timeline.canStart ? Colors.white : Colors.grey,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.timeline.canStart
                  ? AppColors.primaryOrange
                  : Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingConfirmationButtons() {
    return Column(
      children: [
        if (widget.timeline.canConfirmStart && widget.onConfirmStart != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onConfirmStart,
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('Confirmar início'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: Colors.orange.shade700, size: 16),
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
      ],
    );
  }

  Widget _buildActiveButtons() {
    final canComplete = _countdown.effectiveCanComplete;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canComplete ? widget.onCompleteClass : null,
        icon: Icon(
          Icons.stop_circle,
          size: 16,
          color: canComplete ? Colors.white : Colors.grey,
        ),
        label: Text(
          'Finalizar aula',
          style: TextStyle(
            color: canComplete ? Colors.white : Colors.grey,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canComplete ? AppColors.primaryOrange : Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCountdownInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 6),
          Text(
            'Finalizar em ${formatTimelineCountdown(_countdown.displayRemainingSeconds)} '
            '(mín. ${_countdown.minCompletionMinutes} min)',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeButtons() {
    return Column(
      children: [
        if (widget.timeline.canReportNoShow && widget.onReportNoShow != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onReportNoShow,
              icon: const Icon(Icons.report_problem, size: 16),
              label: const Text('Reportar ausência'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        if (widget.timeline.canReportPersonalNoShow &&
            widget.onReportPersonalNoShow != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onReportPersonalNoShow,
              icon: const Icon(Icons.person_off, size: 16),
              label: const Text('Personal não compareceu'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aula em disputa. Aguardando resolução administrativa.',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustodyButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.blue.shade700, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Aula em custódia para análise administrativa.',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineInfo() {
    if (widget.timeline.cancellationDeadline != null &&
        widget.timeline.canCancel) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              'Cancelamento permitido até ${widget.timeline.formattedTimeUntilCancellation}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  bool _shouldShowDeadlineInfo() {
    return widget.timeline.cancellationDeadline != null &&
        widget.timeline.canCancel;
  }
}
