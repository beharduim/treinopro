import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/proposals_state.dart';
import '../bloc/proposals_bloc.dart';
import '../bloc/proposals_event.dart';


Widget buildEndTimeDisplay(BuildContext context, ProposalsLoaded state) {
  String endTime = '--:--';

  if (state.proposal.trainingTime != null &&
      state.proposal.trainingTime!.isNotEmpty) {
    try {
      final startTimeParts = state.proposal.trainingTime!.split(':');
      if (startTimeParts.length == 2) {
        final startHour = int.parse(startTimeParts[0]);
        final startMinute = int.parse(startTimeParts[1]);
        final endHour = (startHour + 1) % 24;
        endTime =
            '${endHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      endTime = '--:--';
    }
  }

  if (state.proposal.durationMinutes != 60) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProposalsBloc>().add(ProposalsUpdateDuration(60));
    });
  }

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primaryOrange.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.primaryOrange.withOpacity(0.2),
        width: 1,
      ),
    ),
    child: Row(
      children: [
        Icon(Icons.schedule, color: AppColors.primaryOrange, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horário de término',
              style: AppTextStyles.small.copyWith(
                color: AppColors.secondaryDark.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              endTime,
              style: AppTextStyles.paragraph.copyWith(
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '1 hora',
            style: AppTextStyles.small.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
