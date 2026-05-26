import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/class_response_dto.dart';
import '../../data/models/class_timeline_dto.dart';
import 'class_action_buttons.dart';

class ClassCard extends StatelessWidget {
  final ClassResponseDto classData;
  final ClassTimelineDto? timeline;
  final VoidCallback? onStartClass;
  final VoidCallback? onConfirmStart;
  final VoidCallback? onCompleteClass;
  final VoidCallback? onCancelClass;
  final VoidCallback? onReportNoShow;
  final VoidCallback? onReportPersonalNoShow;
  final VoidCallback? onChat;
  final VoidCallback? onTap;

  const ClassCard({
    super.key,
    required this.classData,
    this.timeline,
    this.onStartClass,
    this.onConfirmStart,
    this.onCompleteClass,
    this.onCancelClass,
    this.onReportNoShow,
    this.onReportPersonalNoShow,
    this.onChat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _getCardBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: _getCardBorder(),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildDivider(),
            const SizedBox(height: 16),
            _buildClassInfo(),
            const SizedBox(height: 20),
            if (timeline != null)
              ClassActionButtons(
                classData: classData,
                timeline: timeline!,
                onStartClass: onStartClass,
                onConfirmStart: onConfirmStart,
                onCompleteClass: onCompleteClass,
                onCancelClass: onCancelClass,
                onReportNoShow: onReportNoShow,
                onReportPersonalNoShow: onReportPersonalNoShow,
                onChat: onChat,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _getAvatarBorderColor(),
              width: 2,
            ),
            color: _getAvatarBackgroundColor(),
          ),
          child: Icon(
            _getAvatarIcon(),
            size: 24,
            color: _getAvatarIconColor(),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Informações do usuário
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getUserName(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      classData.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Status badge
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusBadgeColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(),
        style: TextStyle(
          fontFamily: 'Fira Sans',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _getStatusTextColor(),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildClassInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoItem(
          Icons.calendar_today,
          'Data',
          _formatDate(classData.date),
        ),
        _buildInfoItem(
          Icons.access_time,
          'Horário',
          classData.time,
        ),
        _buildInfoItem(
          Icons.timer,
          'Duração',
          '${classData.duration}min',
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Fira Sans',
            fontSize: 10,
            color: Color(0xFF42464D),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Fira Sans',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  // Métodos auxiliares para cores e ícones baseados no status
  Color _getCardBackgroundColor() {
    switch (classData.status) {
      case ClassStatus.ACTIVE:
        return AppColors.primaryOrange.withOpacity(0.05);
      case ClassStatus.NO_SHOW_DISPUTE:
        return Colors.red.shade50;
      case ClassStatus.CUSTODY:
        return Colors.blue.shade50;
      default:
        return Colors.white;
    }
  }

  Border? _getCardBorder() {
    switch (classData.status) {
      case ClassStatus.ACTIVE:
        return Border.all(color: AppColors.primaryOrange, width: 2);
      case ClassStatus.NO_SHOW_DISPUTE:
        return Border.all(color: Colors.red.shade300, width: 1);
      case ClassStatus.CUSTODY:
        return Border.all(color: Colors.blue.shade300, width: 1);
      default:
        return Border.all(color: Colors.grey.shade200, width: 1);
    }
  }

  Color _getAvatarBorderColor() {
    switch (classData.status) {
      case ClassStatus.ACTIVE:
        return AppColors.primaryOrange;
      case ClassStatus.NO_SHOW_DISPUTE:
        return Colors.red;
      case ClassStatus.CUSTODY:
        return Colors.blue;
      default:
        return AppColors.primaryOrange;
    }
  }

  Color _getAvatarBackgroundColor() {
    switch (classData.status) {
      case ClassStatus.ACTIVE:
        return AppColors.primaryOrange.withOpacity(0.1);
      case ClassStatus.NO_SHOW_DISPUTE:
        return Colors.red.withOpacity(0.1);
      case ClassStatus.CUSTODY:
        return Colors.blue.withOpacity(0.1);
      default:
        return Colors.grey.shade100;
    }
  }

  IconData _getAvatarIcon() {
    switch (classData.status) {
      case ClassStatus.ACTIVE:
        return Icons.play_circle;
      case ClassStatus.NO_SHOW_DISPUTE:
        return Icons.warning;
      case ClassStatus.CUSTODY:
        return Icons.security;
      default:
        return Icons.person;
    }
  }

  Color _getAvatarIconColor() {
    switch (classData.status) {
      case ClassStatus.ACTIVE:
        return AppColors.primaryOrange;
      case ClassStatus.NO_SHOW_DISPUTE:
        return Colors.red;
      case ClassStatus.CUSTODY:
        return Colors.blue;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getUserName() {
    // Assumindo que estamos mostrando o nome do outro usuário
    // Se for personal trainer vendo, mostra nome do aluno
    // Se for aluno vendo, mostra nome do personal
    return classData.studentName.isNotEmpty 
        ? classData.studentName 
        : 'Usuário';
  }

  Color _getStatusBadgeColor() {
    switch (classData.status) {
      case ClassStatus.SCHEDULED:
        return Colors.blue.shade100;
      case ClassStatus.PENDING_CONFIRMATION:
        return Colors.orange.shade100;
      case ClassStatus.ACTIVE:
        return AppColors.primaryOrange.withOpacity(0.2);
      case ClassStatus.COMPLETED:
        return Colors.green.shade100;
      case ClassStatus.CANCELLED:
        return Colors.grey.shade100;
      case ClassStatus.NO_SHOW_DISPUTE:
        return Colors.red.shade100;
      case ClassStatus.CUSTODY:
        return Colors.blue.shade100;
    }
  }

  Color _getStatusTextColor() {
    switch (classData.status) {
      case ClassStatus.SCHEDULED:
        return Colors.blue.shade700;
      case ClassStatus.PENDING_CONFIRMATION:
        return Colors.orange.shade700;
      case ClassStatus.ACTIVE:
        return AppColors.primaryOrange;
      case ClassStatus.COMPLETED:
        return Colors.green.shade700;
      case ClassStatus.CANCELLED:
        return Colors.grey.shade700;
      case ClassStatus.NO_SHOW_DISPUTE:
        return Colors.red.shade700;
      case ClassStatus.CUSTODY:
        return Colors.blue.shade700;
    }
  }

  String _getStatusText() {
    switch (classData.status) {
      case ClassStatus.SCHEDULED:
        return 'Agendada';
      case ClassStatus.PENDING_CONFIRMATION:
        return 'Aguardando';
      case ClassStatus.ACTIVE:
        return 'Ativa';
      case ClassStatus.COMPLETED:
        return 'Concluída';
      case ClassStatus.CANCELLED:
        return 'Cancelada';
      case ClassStatus.NO_SHOW_DISPUTE:
        return 'Em Disputa';
      case ClassStatus.CUSTODY:
        return 'Em Custódia';
    }
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
}
