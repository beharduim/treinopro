import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../payment_methods/presentation/pages/payment_methods_page.dart';
import '../../../payment_methods/presentation/bloc/payment_methods_bloc.dart';
import '../bloc/proposals_bloc.dart';
import '../bloc/proposals_event.dart';
import '../bloc/proposals_state.dart';
import '../widgets/smart_price_field.dart';
import '../widgets/payment_method_selector.dart';

/// Etapa 3: Valor da proposta
class ProposalStep3Page extends StatefulWidget {
  const ProposalStep3Page({super.key});

  @override
  State<ProposalStep3Page> createState() => _ProposalStep3PageState();
}

class _ProposalStep3PageState extends State<ProposalStep3Page> {
  @override
  void initState() {
    super.initState();
    // Carregar métodos de pagamento quando a tela é inicializada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProposalsBloc>().add(const ProposalsLoadPaymentMethods());
    });
  }

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
                'Quanto custa o treino?',
                style: AppTextStyles.h6Semibold.copyWith(
                  color: AppColors.secondary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Defina o valor que você está disposto a pagar por esta aula.',
                style: AppTextStyles.paragraph.copyWith(
                  color: AppColors.secondaryDark,
                ),
              ),

              const SizedBox(height: 32),

              // Valor da aula
              _buildPriceSection(context, state),

              const SizedBox(height: 32),

              // Observações adicionais
              _buildNotesSection(context, state),

              const SizedBox(height: 32),

              // Método de pagamento
              _buildPaymentMethodSection(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceSection(BuildContext context, ProposalsLoaded state) {
    final suggestedPrice = _getSuggestedPrice(state);

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
                Icons.attach_money,
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
                    'Valor da aula *',
                    style: AppTextStyles.paragraph.copyWith(
                      color: AppColors.secondaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Valor mínimo de R\$ 1',
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

        // Campo de preço inteligente
        SmartPriceField(
          initialValue: state.proposal.price,
          minValue: 1.0,
          suggestedValue: suggestedPrice,
          onValueChanged: (price) {
            context.read<ProposalsBloc>().add(ProposalsUpdatePrice(price));
          },
          suggestions: _getPriceSuggestions(suggestedPrice),
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context, ProposalsLoaded state) {
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
                Icons.note_alt_outlined,
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
                    'Observações (opcional)',
                    style: AppTextStyles.paragraph.copyWith(
                      color: AppColors.secondaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Envie algo que ajude o personal a adaptar o treino',
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

        // Campo de observações
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.secondaryDark, width: 1),
          ),
          child: TextField(
            onChanged: (notes) {
              context.read<ProposalsBloc>().add(ProposalsUpdateNotes(notes));
            },
            maxLines: 4,
            style: AppTextStyles.small.copyWith(color: AppColors.secondaryDark),
            decoration: InputDecoration(
              hintText:
                  'Ex: “Já treino há 2 anos, quero fazer um treino de peito hoje”',
              hintStyle: AppTextStyles.small.copyWith(
                color: AppColors.secondaryDark.withOpacity(0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  double? _getSuggestedPrice(ProposalsLoaded state) {
    if (state.proposal.modalityId == null) return null;

    final modality =
        state.availableModalities
            .where((m) => m.id == state.proposal.modalityId)
            .isNotEmpty
        ? state.availableModalities.firstWhere(
            (m) => m.id == state.proposal.modalityId,
          )
        : null;

    return modality?.suggestedPrice;
  }

  List<double> _getPriceSuggestions(double? suggestedPrice) {
    final baseSuggestions = [1.0, 5.0, 10.0, 40.0, 60.0, 80.0, 100.0];

    if (suggestedPrice != null && !baseSuggestions.contains(suggestedPrice)) {
      final suggestions = [...baseSuggestions, suggestedPrice];
      suggestions.sort();
      return suggestions;
    }

    return baseSuggestions;
  }

  Widget _buildPaymentMethodSection(
    BuildContext context,
    ProposalsLoaded state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seletor de métodos de pagamento original
        PaymentMethodSelector(
          availableMethods: state.availablePaymentMethods,
          selectedMethodId: state.proposal.paymentMethodId,
          isLoading: state.isLoadingPaymentMethods,
          onMethodSelected: (methodId, methodName) {
            context.read<ProposalsBloc>().add(
              ProposalsUpdatePaymentMethod(methodId, methodName),
            );
          },
        ),

        const SizedBox(height: 16),

        // Botão para adicionar nova forma de pagamento
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _navigateToPaymentMethods(context),
            icon: const Icon(
              Icons.add,
              color: AppColors.primaryOrange,
              size: 20,
            ),
            label: Text(
              'Adicionar Forma de Pagamento',
              style: AppTextStyles.paragraph.copyWith(
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: AppColors.primaryOrange,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToPaymentMethods(BuildContext context) async {
    final proposalsBloc = context.read<ProposalsBloc>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BlocProvider(
          create: (context) => sl<PaymentMethodsBloc>(),
          child: const PaymentMethodsPage(fromStep3: true),
        ),
      ),
    );

    if (!mounted) return;
    proposalsBloc.add(const ProposalsLoadPaymentMethods());
  }
}
