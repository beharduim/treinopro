import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/proposals_bloc.dart';
import '../bloc/proposals_state.dart';

/// Tela de revisão da proposta
class ProposalReviewPage extends StatelessWidget {
  const ProposalReviewPage({super.key});

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
            children: [
              // Título da etapa
              Text(
                'Revisão da proposta',
                style: AppTextStyles.h6Semibold.copyWith(
                  color: AppColors.secondary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Confira se está tudo certo antes de enviar:',
                style: AppTextStyles.paragraph.copyWith(
                  color: AppColors.secondaryDark,
                ),
              ),

              const SizedBox(height: 32),

              // Container único envolvendo todas as seções
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondaryDark.withValues(alpha: 0.24),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Card 1: Data e Horário (sem borda)
                    _buildSummarySection(
                      title: 'Agendamento',
                      children: [
                        // Data ocupa linha inteira
                        _buildSummaryItem(
                          icon: Icons.calendar_today,
                          label: 'Data do treino',
                          value: _formatDate(state.proposal.trainingDate),
                          isCompact: false,
                        ),

                        const SizedBox(height: 16),

                        // Horário e Duração na mesma linha
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryItem(
                                icon: Icons.schedule,
                                label: 'Horário',
                                value:
                                    state.proposal.trainingTime ??
                                    'Não definido',
                                isCompact: false,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildSummaryItem(
                                icon: Icons.timer,
                                label: 'Duração',
                                value: _getModalityDuration(state),
                                isCompact: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Linha separadora
                    Container(
                      height: 1,
                      color: AppColors.secondaryDark.withValues(alpha: 0.1),
                    ),

                    const SizedBox(height: 24),

                    // Card 2: Local e Modalidade (sem borda)
                    _buildSummarySection(
                      title: 'Treino',
                      children: [
                        _buildSummaryItem(
                          icon: Icons.location_on,
                          label: 'Local do treino',
                          value: state.proposal.locationName ?? 'Não definido',
                          isCompact: false,
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryItem(
                          icon: Icons.sports_gymnastics,
                          label: 'Modalidade escolhida',
                          value: state.proposal.modalityName ?? 'Não definido',
                          isCompact: false,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Linha separadora
                    Container(
                      height: 1,
                      color: AppColors.secondaryDark.withValues(alpha: 0.1),
                    ),

                    const SizedBox(height: 24),

                    // Valor da aula - Dentro do container
                    Column(
                      children: [
                        // Título centralizado
                        Center(
                          child: Text(
                            'Valor da aula',
                            style: AppTextStyles.paragraph.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Valor centralizado
                        Center(
                          child: Text(
                            state.proposal.price != null
                                ? 'R\$ ${state.proposal.price!.toStringAsFixed(0)}'
                                : 'Não definido',
                            style: AppTextStyles.h6Semibold.copyWith(
                              color: AppColors.primaryOrange,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              // Como funciona
              _buildHowItWorks(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummarySection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        Text(
          title,
          style: AppTextStyles.paragraph.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 16),

        // Conteúdo da seção
        ...children,
      ],
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    bool isCompact = true,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            color: AppColors.primaryOrange.withValues(alpha: 0.7),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.secondaryDark.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style:
                    (isHighlight
                            ? AppTextStyles.paragraph
                            : AppTextStyles.paragraph)
                        .copyWith(
                          color: isHighlight
                              ? AppColors.primaryOrange
                              : AppColors.secondary,
                          fontWeight: isHighlight
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: isHighlight ? 18 : 15,
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Título
          Row(
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(14.5),
                ),
                child: const Icon(
                  Icons.map,
                  color: AppColors.inputBackground,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Como funciona:',
                style: AppTextStyles.h6Semibold.copyWith(
                  color: AppColors.inputBackground,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lista de explicações
          Column(
            children: [
              _buildExplanationItem(
                'Sua proposta é enviada automaticamente para todos os personais disponíveis na região.',
              ),
              const SizedBox(height: 12),
              _buildExplanationItem(
                'Assim que um profissional aceitar, vocês são conectados e o chat é liberado para combinar detalhes ou avisar sobre imprevistos',
              ),
              const SizedBox(height: 12),
              _buildExplanationItem(
                'O TreinoPro atua apenas como intermediador, conectando aluno e personal — não se responsabiliza por eventuais lesões ocorridas durante o treino.',
              ),
              const SizedBox(height: 12),
              _buildExplanationItem(
                'O acesso à academia é de responsabilidade do aluno, seguindo as regras da unidade escolhida',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6, right: 12),
          decoration: const BoxDecoration(
            color: AppColors.inputBackground,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.paragraph.copyWith(
              color: AppColors.inputBackground,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Não definido';

    final weekdays = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];

    final months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    final weekday = weekdays[date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];

    return '$weekday, $day de $month';
  }

  String _getModalityDuration(ProposalsLoaded state) {
    if (state.proposal.durationMinutes == null) return 'Não definido';

    final duration = state.proposal.durationMinutes!;
    if (duration >= 60) {
      return '${(duration / 60).toStringAsFixed(duration % 60 == 0 ? 0 : 1)}h';
    }
    return '${duration}min';
  }
}
