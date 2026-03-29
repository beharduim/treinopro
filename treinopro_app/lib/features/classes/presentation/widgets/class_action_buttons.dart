import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/class_response_dto.dart';
import '../../data/models/class_timeline_dto.dart';

class ClassActionButtons extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botões principais baseados no status
        _buildMainButtons(),
        
        // Informações de prazo se aplicável
        if (_shouldShowDeadlineInfo()) ...[
          const SizedBox(height: 12),
          _buildDeadlineInfo(),
        ],
      ],
    );
  }

  Widget _buildMainButtons() {
    switch (classData.status) {
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
        // Botão Chat (sempre disponível)
        if (onChat != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onChat,
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
        
        // Botão Cancelar (se permitido)
        if (timeline.canCancel && onCancelClass != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCancelClass,
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
        
        // Botão Iniciar (se permitido)
        Expanded(
          child: ElevatedButton.icon(
            onPressed: timeline.canStart ? onStartClass : null,
            icon: Icon(
              Icons.play_circle,
              size: 16,
              color: timeline.canStart ? Colors.white : Colors.grey,
            ),
            label: Text(
              'Iniciar aula',
              style: TextStyle(
                color: timeline.canStart ? Colors.white : Colors.grey,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: timeline.canStart 
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
        // Botão de confirmação para o aluno
        if (timeline.canConfirmStart && onConfirmStart != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onConfirmStart,
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
        
        // Informação sobre o prazo de confirmação
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: timeline.canComplete ? onCompleteClass : null,
        icon: Icon(
          Icons.stop_circle,
          size: 16,
          color: timeline.canComplete ? Colors.white : Colors.grey,
        ),
        label: Text(
          'Finalizar aula',
          style: TextStyle(
            color: timeline.canComplete ? Colors.white : Colors.grey,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: timeline.canComplete 
              ? AppColors.primaryOrange 
              : Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildDisputeButtons() {
    return Column(
      children: [
        // Botões de disputa
        if (timeline.canReportNoShow && onReportNoShow != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReportNoShow,
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
        
        if (timeline.canReportPersonalNoShow && onReportPersonalNoShow != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReportPersonalNoShow,
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
        
        // Informação sobre disputa
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
    if (timeline.cancellationDeadline != null && timeline.canCancel) {
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
              'Cancelamento permitido até ${timeline.formattedTimeUntilCancellation}',
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
    return timeline.cancellationDeadline != null && timeline.canCancel;
  }
}
