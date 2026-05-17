import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/balance_bloc.dart';
import '../bloc/balance_event.dart';
import '../bloc/balance_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/dependency_injection.dart' show sl;
import '../../../payouts/presentation/widgets/add_payout_method_bottom_sheet.dart';
import '../../../payouts/data/models/financial_profile_model.dart';
import '../../../home/data/models/payment_models.dart';

/// Página de saldo do personal trainer
class PersonalBalancePage extends StatelessWidget {
  const PersonalBalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<BalanceBloc>()..add(const LoadBalance()),
      child: const _PersonalBalanceView(),
    );
  }
}

class _PersonalBalanceView extends StatefulWidget {
  const _PersonalBalanceView();

  @override
  State<_PersonalBalanceView> createState() => _PersonalBalanceViewState();
}

class _PersonalBalanceViewState extends State<_PersonalBalanceView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Minha Carteira'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.secondary,
      ),
      body: BlocConsumer<BalanceBloc, BalanceState>(
        listener: (context, state) {
          if (state is BalanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is BalanceLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
          }

          if (state is BalanceLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<BalanceBloc>().add(RefreshBalance());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(state.profile),
                    const SizedBox(height: 16),
                    _buildStripeStatusCard(state.profile.stripeAccount),
                    const SizedBox(height: 24),
                    _buildWithdrawButton(state.profile),
                    const SizedBox(height: 32),
                    _buildTransactionsSection(state.transactions),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Erro ao carregar saldo', style: TextStyle(color: Colors.grey)),
                TextButton(
                  onPressed: () => context.read<BalanceBloc>().add(const LoadBalance()),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(FinancialProfileModel profile) {
    final available = profile.wallet?.availableBalance ?? 0.0;
    final pending = profile.wallet?.pendingBalance ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, Color(0xFF2D3748)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo disponível para saque',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(available),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: Colors.white10),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Em liberação (Stripe)',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(pending),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Icon(Icons.timer_outlined, color: Colors.white30, size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStripeStatusCard(StripeConnectAccountModel? stripe) {
    if (stripe == null) return const SizedBox.shrink();

    final isReady = stripe.isReadyForPayout;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReady ? Colors.green.withOpacity(0.05) : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isReady ? Colors.green : Colors.orange).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isReady ? Icons.check_circle : Icons.error_outline,
            color: isReady ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stripe.statusTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isReady ? Colors.green : Colors.orange,
                  ),
                ),
                Text(
                  stripe.statusDescription,
                  style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                ),
              ],
            ),
          ),
          if (!isReady)
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange),
              onPressed: () => _handleOnboarding(context),
            ),
        ],
      ),
    );
  }

  Widget _buildWithdrawButton(FinancialProfileModel profile) {
    final canWithdraw = profile.stripeAccount?.payoutsEnabled ?? false;
    final balance = profile.wallet?.availableBalance ?? 0.0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: (canWithdraw && balance > 0) 
          ? () => _requestWithdrawal(context)
          : () => _showBlockedWithdrawalDialog(context, profile.stripeAccount, balance),
        child: const Text(
          'Solicitar Saque',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showBlockedWithdrawalDialog(BuildContext context, StripeConnectAccountModel? stripe, double balance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saque Indisponível'),
        content: Text(
          balance <= 0 
            ? 'Você ainda não possui saldo disponível para saque.' 
            : 'Sua conta bancária ainda não foi validada pela Stripe. Finalize seu cadastro para liberar os saques.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
          if (stripe?.payoutsEnabled == false)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleOnboarding(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
              child: const Text('Finalizar Cadastro'),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(List<TransactionModel> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimas Atividades',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('Nenhuma movimentação encontrada.', style: TextStyle(color: Colors.grey)),
          ))
        else
          ...transactions.map((t) => _buildTransactionItem(t)),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final isCredit = transaction.type == 'personal_earnings' || transaction.type == 'adjustment_credit';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isCredit ? Colors.green : Colors.red).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.add : Icons.remove,
              color: isCredit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  _formatDate(transaction.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            (isCredit ? '+' : '-') + _formatCurrency(transaction.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _handleOnboarding(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddPayoutMethodBottomSheet(),
    );
  }

  void _requestWithdrawal(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sua solicitação de saque está sendo processada.')),
    );
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}
