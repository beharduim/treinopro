import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/proposals_bloc.dart';
import '../bloc/proposals_event.dart';
import '../bloc/proposals_state.dart';
import '../widgets/location_search_field.dart';
import '../widgets/visual_date_picker.dart';
import '../widgets/time_slot_selector.dart';
import '../utils/proposal_time_helpers.dart' show buildEndTimeDisplay;
import '../../../../core/di/dependency_injection.dart';
import '../../data/services/proposals_api_service.dart';

/// Etapa 1: Onde e Quando
class ProposalStep1Page extends StatelessWidget {
  const ProposalStep1Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProposalsBloc, ProposalsState>(
      builder: (context, state) {
        if (state is! ProposalsLoaded) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryOrange,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Título da etapa
              Text(
                'Onde e quando será o treino?',
                style: AppTextStyles.h6Semibold.copyWith(
                  color: AppColors.secondary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Escolha o local, a data e o horário que preferir.',
                style: AppTextStyles.paragraph.copyWith(
                  color: AppColors.secondaryDark,
                ),
              ),

              const SizedBox(height: 32),

              // Local do treino
              _buildLocationSection(context, state),

              const SizedBox(height: 32),

              // Data do treino
              _buildDateSection(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationSection(BuildContext context, ProposalsLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.location_on,
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
                    'Local do treino',
                    style: AppTextStyles.paragraph.copyWith(
                      color: AppColors.secondaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '(Ex: academia, praça, praia, residência...)',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.secondaryDark.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Campo de busca
        LocationSearchField(
          initialValue: state.proposal.locationName,
          suggestions: state.searchedLocations,
          isLoading: state.isLoadingLocations,
          onSearchChanged: (query) {
            context.read<ProposalsBloc>().add(ProposalsSearchLocations(query));
          },
          onLocationSelected: (location) {
            context.read<ProposalsBloc>().add(
              ProposalsUpdateLocation(location),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateSection(BuildContext context, ProposalsLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Título da seção
        Row(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.calendar_today,
                color: AppColors.primaryOrange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Data do treino ',
                    style: AppTextStyles.paragraph.copyWith(
                      color: AppColors.secondaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Selecione quando quer treinar',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.secondaryDark.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Seletor de data
        VisualDatePicker(
          selectedDate: state.proposal.trainingDate,
          onDateSelected: (date) {
            context.read<ProposalsBloc>().add(ProposalsUpdateDate(date));
          },
          minDate: DateTime.now(),
          maxDate: DateTime.now().add(const Duration(days: 90)),
        ),

        // Horário do treino (moved from Step2)
        if (state.proposal.trainingDate != null) ...[
          const SizedBox(height: 32),

          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.schedule,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Horário de início',
                      style: AppTextStyles.paragraph.copyWith(
                        color: AppColors.secondaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Escolha o horário da sua aula.',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.secondaryDark.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TimeSlotSelector(
            initialValue: state.proposal.trainingTime,
            isLoading: state.isLoadingTimeSlots,
            selectedDate: state.proposal.trainingDate,
            apiService: sl<ProposalsApiService>(),
            onTimeChanged: (time) {
              context.read<ProposalsBloc>().add(ProposalsUpdateTime(time));
            },
          ),

          const SizedBox(height: 24),

          // Exibe horário de término calculado e duração (moved from Step2)
          buildEndTimeDisplay(context, state),
        ],
      ],
    );
  }
}
