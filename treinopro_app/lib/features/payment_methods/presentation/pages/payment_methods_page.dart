import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/payment_method.dart';
import '../bloc/payment_methods_bloc.dart';
import '../bloc/payment_methods_event.dart';
import '../bloc/payment_methods_state.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/add_payment_method_bottom_sheet.dart';
import '../widgets/saved_cards_list.dart';
import '../widgets/payment_card_brands_hint.dart';

class PaymentMethodsPage extends StatefulWidget {
  final bool fromStep3;

  const PaymentMethodsPage({super.key, this.fromStep3 = false});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentMethodsBloc>().add(const LoadPaymentMethods());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFE),
      appBar: const CustomAppBar(
        title: 'Métodos de Pagamento',
        showBackButton: true,
      ),
      body: BlocConsumer<PaymentMethodsBloc, PaymentMethodsState>(
        listenWhen: (previous, current) {
          // Passar para o listener apenas eventos relevantes:
          // - Erro explícito
          if (current is PaymentMethodsError) return true;
          // - Estado carregado com erro
          if (current is PaymentMethodsLoaded && current.error != null) {
            return true;
          }
          // - Transição de isUpdating true -> false (operação concluída com sucesso)
          if (previous is PaymentMethodsLoaded && previous.isUpdating) {
            if (current is PaymentMethodsLoaded &&
                !current.isUpdating &&
                current.error == null) {
              return true;
            }
          }
          return false;
        },
        listener: (context, state) {
          if (state is PaymentMethodsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is PaymentMethodsLoaded && state.error != null) {
            // Mostrar mensagem amigável ao usuário; logar o erro técnico para debugging
            debugPrint('PaymentMethods error (user-facing): ${state.error}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Não foi possível salvar o método de pagamento. Tente novamente mais tarde.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            // Limpar erro após mostrar
            context.read<PaymentMethodsBloc>().add(const ClearErrors());
          } else if (state is PaymentMethodsLoaded &&
              !state.isUpdating &&
              state.error == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Método de pagamento salvo com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PaymentMethodsLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryOrange,
                ),
              ),
            );
          }

          if (state is PaymentMethodsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar métodos de pagamento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PaymentMethodsBloc>().add(
                        const LoadPaymentMethods(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (state is PaymentMethodsLoaded) {
            return _buildContent(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PaymentMethodsLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção de métodos de pagamento disponíveis
          _buildSectionTitle('Adicionar Método de Pagamento'),
          const SizedBox(height: 16),

          // Cards de métodos de pagamento
          _buildPaymentMethodCards(context),

          const SizedBox(height: 32),

          // Seção de cartões salvos
          if (state.settings.savedCards.isNotEmpty) ...[
            _buildSectionTitle('Cartões Salvos'),
            const SizedBox(height: 16),
            SavedCardsList(
              cards: state.settings.savedCards,
              onRemoveCard: (cardId) {
                context.read<PaymentMethodsBloc>().add(RemoveCard(cardId));
              },
              onSetDefault: (cardId) {
                context.read<PaymentMethodsBloc>().add(SetDefaultCard(cardId));
              },
            ),
            const SizedBox(height: 32),
          ],

          // Seção de configurações - COMENTADO PARA USO FUTURO
          // _buildSectionTitle('Configurações'),
          // const SizedBox(height: 16),
          // _buildSettingsCard(context, state),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A202C),
      ),
    );
  }

  Widget _buildPaymentMethodCards(BuildContext context) {
    return Column(
      children: [
        // Cartão de Crédito
        PaymentMethodCard(
          title: 'Cartão de Crédito',
          subtitle: PaymentCardBrandsCopy.subtitle,
          icon: Icons.credit_card,
          color: const Color(0xFF4F46E5),
          onTap: () => _showAddCardBottomSheet(context, CardType.credit),
        ),

        const SizedBox(height: 12),

        // Cartão de Débito
        PaymentMethodCard(
          title: 'Cartão de Débito',
          subtitle: PaymentCardBrandsCopy.subtitle,
          icon: Icons.account_balance_wallet,
          color: const Color(0xFF059669),
          onTap: () => _showAddCardBottomSheet(context, CardType.debit),
        ),

        const PaymentCardBrandsHint(),
      ],
    );
  }

  void _showAddCardBottomSheet(BuildContext context, CardType cardType) {
    final bloc = context.read<PaymentMethodsBloc>();
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => BlocProvider.value(
        value: bloc,
        child: AddPaymentMethodBottomSheet(
          cardType: cardType,
          bloc: bloc,
          fromStep3: widget.fromStep3,
          onCardSaved: () {
            bloc.add(const LoadPaymentMethods());
          },
        ),
      ),
    );
  }
}
