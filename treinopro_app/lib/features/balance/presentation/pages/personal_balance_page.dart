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
import '../../../home/data/models/wallet_bucket_model.dart';

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
  bool _isWithdrawing = false;

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
            setState(() => _isWithdrawing = false);
            final message = state.message.contains('Exception:')
                ? 'Não foi possível carregar sua carteira. Tente novamente.'
                : state.message;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          }
          if (state is BalanceLoaded && state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green,
              ),
            );
            setState(() => _isWithdrawing = false);
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
                    _buildBucketCard(state.profile, state.profile.wallet?.pix ?? const WalletBucketModel(bucket: 'pix')),
                    const SizedBox(height: 16),
                    _buildBucketCard(state.profile, state.profile.wallet?.card ?? const WalletBucketModel(bucket: 'card')),
                    const SizedBox(height: 16),
                    _buildStripeStatusCard(state.profile.stripeAccount),
                    const SizedBox(height: 24),
                    _buildWithdrawButton(
                      state.profile,
                      state.profile.wallet?.pix ?? const WalletBucketModel(bucket: 'pix'),
                    ),
                    const SizedBox(height: 12),
                    _buildWithdrawButton(
                      state.profile,
                      state.profile.wallet?.card ?? const WalletBucketModel(bucket: 'card'),
                    ),
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

  Widget _buildBucketCard(FinancialProfileModel profile, WalletBucketModel bucket) {
    final available = bucket.availableBalance;
    final withdrawalInReview = bucket.pendingWithdrawalAmount;
    final awaitingBankDeposit = bucket.awaitingBankDeposit;
    final settlementHint = bucket.settlementHint.isNotEmpty
        ? bucket.settlementHint
        : bucket.bucket == 'pix'
            ? 'até 3 dias úteis'
            : 'até 30 dias';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bucket.bucket == 'pix'
              ? [const Color(0xFF0F766E), const Color(0xFF134E4A)]
              : [AppColors.secondary, const Color(0xFF2D3748)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (bucket.bucket == 'pix' ? const Color(0xFF0F766E) : AppColors.secondary)
                .withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                bucket.bucket == 'pix' ? Icons.pix : Icons.credit_card,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saldo ${bucket.title} — libera $settlementHint',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(available),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (withdrawalInReview > 0) ...[
            const SizedBox(height: 20),
            Container(height: 1, color: Colors.white10),
            const SizedBox(height: 14),
            _buildBalanceSubRow(
              label: awaitingBankDeposit
                  ? 'Aguardando depósito no banco'
                  : 'Em liberação (saque solicitado)',
              value: withdrawalInReview,
              icon: awaitingBankDeposit
                  ? Icons.account_balance_outlined
                  : Icons.hourglass_top_outlined,
            ),
          ] else if (withdrawalInReview <= 0 && available <= 0) ...[
            const SizedBox(height: 8),
            Text(
              'Aulas pagas via ${bucket.title} entram nesta carteira.',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceSubRow({
    required String label,
    required double value,
    required IconData icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                _formatCurrency(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Icon(icon, color: Colors.white30, size: 24),
      ],
    );
  }

  Widget _buildPendingWithdrawalBanner(FinancialProfileModel profile) {
    final pendingWithdrawal = profile.wallet?.pendingWithdrawalAmount ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.hourglass_top, color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Saque de ${_formatCurrency(pendingWithdrawal)} aguardando aprovação da equipe TreinoPro. '
              'Assim que for liberado, o valor será enviado ao seu banco.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondary,
                height: 1.35,
              ),
            ),
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
      child: InkWell(
        onTap: () => _handleOnboarding(context),
        borderRadius: BorderRadius.circular(12),
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
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isReady ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawButton(
    FinancialProfileModel profile,
    WalletBucketModel bucket,
  ) {
    final canWithdraw = profile.stripeAccount?.isReadyForPayout ?? false;
    final balance = bucket.availableBalance;
    final pendingWithdrawal = bucket.pendingWithdrawalAmount;
    final awaitingBankDeposit = bucket.awaitingBankDeposit;
    final hasPendingWithdrawal = bucket.hasOpenWithdrawal || pendingWithdrawal > 0;
    final bucketLabel = bucket.title;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              bucket.bucket == 'pix' ? const Color(0xFF0F766E) : AppColors.primaryOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: _isWithdrawing
            ? null
            : hasPendingWithdrawal
                ? () => _showBlockedWithdrawalDialog(
                      context,
                      profile.stripeAccount,
                      balance,
                      pendingWithdrawal,
                      bucketLabel: bucketLabel,
                      awaitingBankDeposit: awaitingBankDeposit,
                    )
                : (canWithdraw && balance > 0)
                    ? () => _requestWithdrawal(context, profile, bucket)
                    : () => _showBlockedWithdrawalDialog(
                          context,
                          profile.stripeAccount,
                          balance,
                          pendingWithdrawal,
                          bucketLabel: bucketLabel,
                        ),
        child: _isWithdrawing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                hasPendingWithdrawal
                    ? 'Saque $bucketLabel em análise'
                    : 'Solicitar saque $bucketLabel',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  void _showBlockedWithdrawalDialog(
    BuildContext context,
    StripeConnectAccountModel? stripe,
    double balance,
    double pendingWithdrawal, {
    required String bucketLabel,
    bool awaitingBankDeposit = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saque Indisponível'),
        content: Text(
          pendingWithdrawal > 0
              ? awaitingBankDeposit
                  ? 'Você já possui um saque $bucketLabel de ${_formatCurrency(pendingWithdrawal)} em análise. '
                      'Aguarde o depósito na sua conta bancária antes de solicitar outro saque nesta carteira.'
                  : 'Você já possui um saque $bucketLabel de ${_formatCurrency(pendingWithdrawal)} aguardando aprovação. '
                      'Assim que a equipe TreinoPro liberar, o valor será enviado ao seu banco.'
              : balance <= 0
                  ? 'Você ainda não possui saldo $bucketLabel disponível para saque.'
                  : 'Sua conta bancária ainda não foi validada pela Stripe. Finalize seu cadastro para liberar os saques.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
          if (stripe?.payoutsEnabled == false || !(stripe?.isReadyForPayout ?? false))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleOnboarding(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Finalizar Cadastro',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
      builder: (ctx) => AddPayoutMethodBottomSheet(
        onSaved: () {
          context.read<BalanceBloc>().add(const LoadBalance());
        },
      ),
    );
  }

  Future<void> _requestWithdrawal(
    BuildContext context,
    FinancialProfileModel profile,
    WalletBucketModel bucket,
  ) async {
    final balance = bucket.availableBalance;
    if (balance <= 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar saque ${bucket.title}'),
        content: Text(
          'Deseja solicitar o saque ${bucket.title} de ${_formatCurrency(balance)}?\n\n'
          'Prazo estimado após aprovação: ${bucket.settlementHint.isNotEmpty ? bucket.settlementHint : (bucket.bucket == 'pix' ? 'até 3 dias úteis' : 'até 30 dias')}.\n\n'
          'O valor será enviado para análise da equipe TreinoPro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondary,
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    setState(() => _isWithdrawing = true);
    context.read<BalanceBloc>().add(
          RequestWithdrawal(balance, sourceBucket: bucket.bucket),
        );
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}
