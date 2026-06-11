import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/balance_bloc.dart';
import '../bloc/balance_event.dart';
import '../bloc/balance_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/dependency_injection.dart' show sl;
import '../../../payouts/presentation/widgets/add_payout_method_bottom_sheet.dart';
import '../../../payouts/data/models/financial_profile_model.dart';
import '../../../home/data/models/wallet_bucket_model.dart';
import '../../../home/data/models/wallet_dashboard_model.dart';
import 'personal_earnings_history_page.dart';
import 'personal_withdrawal_history_page.dart';
import '../widgets/wallet_withdrawal_stepper.dart';

/// Carteira do personal — layout unificado (mock Minha Carteira)
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
  bool _showAllPending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Minha Carteira'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHowItWorks(context),
          ),
        ],
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            );
          }

          if (state is BalanceLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<BalanceBloc>().add(RefreshBalance());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvailableSection(state),
                    const SizedBox(height: 16),
                    _buildPendingReleaseSection(state.dashboard),
                    const SizedBox(height: 16),
                    _buildActiveWithdrawalsSection(context, state.dashboard),
                    const SizedBox(height: 16),
                    _buildEarningsSection(state.dashboard),
                    const SizedBox(height: 16),
                    _buildHowItWorksFooter(),
                    if (!(state.profile.stripeAccount?.isReadyForPayout ?? false))
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildStripeStatusCard(state.profile.stripeAccount),
                      ),
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
                const Text(
                  'Erro ao carregar saldo',
                  style: TextStyle(color: Colors.grey),
                ),
                TextButton(
                  onPressed: () =>
                      context.read<BalanceBloc>().add(const LoadBalance()),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvailableSection(BalanceLoaded state) {
    final available = state.dashboard.availableForWithdrawal;
    final profile = state.profile;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Disponível para saque',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showHowItWorks(context),
                child: const Icon(Icons.info_outline,
                    color: Colors.white70, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(available),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF047857),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: _isWithdrawing
                  ? null
                  : () => _handleWithdrawTap(context, profile),
              child: _isWithdrawing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Solicitar saque',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReleaseSection(WalletDashboardModel dashboard) {
    if (dashboard.pendingReleaseItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = _showAllPending
        ? dashboard.pendingReleaseItems
        : dashboard.pendingReleaseItems.take(3).toList();

    return _sectionCard(
      headerColor: const Color(0xFFFFF7ED),
      borderColor: const Color(0xFFFED7AA),
      title: 'Aguardando liberação',
      total: dashboard.pendingReleaseTotal,
      child: Column(
        children: [
          _tableHeader(['ORIGEM', 'VALOR', 'PREVISÃO']),
          ...items.map(_buildPendingRow),
          if (dashboard.pendingReleaseItems.length > 3)
            TextButton(
              onPressed: () =>
                  setState(() => _showAllPending = !_showAllPending),
              child: Text(
                _showAllPending ? 'Ver menos' : 'Ver todos',
                style: const TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingRow(WalletPendingReleaseItemModel item) {
    final isPix = item.sourceBucket == 'pix';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isPix ? Icons.pix : Icons.credit_card,
                  size: 16,
                  color: isPix ? const Color(0xFF0F766E) : AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.sourceLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        item.classDate != null
                            ? 'Aula • ${item.classDate}'
                            : 'Aula',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency(item.amount),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.releaseAt != null
                      ? _formatDate(item.releaseAt!)
                      : '—',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.right,
                ),
                Text(
                  item.releaseForecast,
                  style: const TextStyle(
                    color: Color(0xFFEA580C),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWithdrawalsSection(
    BuildContext context,
    WalletDashboardModel dashboard,
  ) {
    if (dashboard.activeWithdrawals.isEmpty) {
      return const SizedBox.shrink();
    }

    return _sectionCard(
      headerColor: const Color(0xFFEFF6FF),
      borderColor: const Color(0xFFBFDBFE),
      title: 'Saques em andamento',
      total: dashboard.activeWithdrawalsTotal,
      child: Column(
        children: [
          ...dashboard.activeWithdrawals.map(
            (w) => WalletWithdrawalTrackerCard(withdrawal: w),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<BalanceBloc>(),
                      child: const PersonalWithdrawalHistoryPage(),
                    ),
                  ),
                );
              },
              child: const Text(
                'Ver histórico de saques',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsSection(WalletDashboardModel dashboard) {
    if (dashboard.earningsHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Histórico de ganhos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          ...dashboard.earningsHistory.take(5).map(_buildEarningRow),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PersonalEarningsHistoryPage(),
                ),
              );
            },
            child: const Text(
              'Ver todas as aulas',
              style: TextStyle(
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningRow(WalletEarningItemModel item) {
    final isPix = item.sourceBucket == 'pix';
    final released = item.isReleased;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.classDate != null && item.studentName != null
                      ? '${item.classDate} • ${item.studentName}'
                      : item.studentName ?? item.classDate ?? 'Aula',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPix
                        ? const Color(0xFFCCFBF1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.sourceLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPix
                          ? const Color(0xFF0F766E)
                          : AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(item.amount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: released
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.releaseStatusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: released
                    ? const Color(0xFF15803D)
                    : const Color(0xFFEA580C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required Color headerColor,
    required Color borderColor,
    required String title,
    required double total,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  _formatCurrency(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(List<String> labels) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              labels[0],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              labels[1],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              labels[2],
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como funciona?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '• Pix: disponibilidade em até 3 dias úteis.\n'
            '• Cartão de crédito (nacional): disponibilidade em até 30 dias.\n\n'
            'Os prazos podem variar conforme regras da Stripe e da operadora do cartão.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              height: 1.45,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Transparência e confiança: você sempre saberá onde está seu dinheiro e quando ele ficará disponível.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondary,
              height: 1.4,
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
        color: isReady
            ? Colors.green.withOpacity(0.05)
            : Colors.orange.withOpacity(0.05),
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                    ),
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

  void _showHowItWorks(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Como funciona?'),
        content: const SingleChildScrollView(
          child: Text(
            'Disponível para saque: valor já liberado pela Stripe, pronto para transferência ao seu banco após aprovação.\n\n'
            'Aguardando liberação: pagamentos de aulas ainda no prazo de compensação (Pix ou cartão).\n\n'
            'Saques em andamento: acompanhe cada etapa até o depósito na sua conta.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleWithdrawTap(
    BuildContext context,
    FinancialProfileModel profile,
  ) async {
    final pix = profile.wallet?.pix ??
        const WalletBucketModel(bucket: 'pix');
    final card = profile.wallet?.card ??
        const WalletBucketModel(bucket: 'card');
    final canWithdraw = profile.stripeAccount?.isReadyForPayout ?? false;

    final bucketsWithBalance = [
      if (pix.availableBalance > 0) pix,
      if (card.availableBalance > 0) card,
    ];

    if (!canWithdraw) {
      _showBlockedWithdrawalDialog(context, profile.stripeAccount, 0, 0);
      return;
    }

    if (bucketsWithBalance.isEmpty) {
      _showBlockedWithdrawalDialog(context, profile.stripeAccount, 0, 0);
      return;
    }

    WalletBucketModel selected = bucketsWithBalance.first;
    if (bucketsWithBalance.length > 1) {
      final picked = await showModalBottomSheet<WalletBucketModel>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'De qual origem deseja sacar?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ...bucketsWithBalance.map(
                (b) => ListTile(
                  leading: Icon(
                    b.bucket == 'pix' ? Icons.pix : Icons.credit_card,
                  ),
                  title: Text('Saldo ${b.title}'),
                  subtitle: Text(_formatCurrency(b.availableBalance)),
                  onTap: () => Navigator.pop(ctx, b),
                ),
              ),
            ],
          ),
        ),
      );
      if (picked == null || !context.mounted) return;
      selected = picked;
    }

    await _requestWithdrawal(context, profile, selected);
  }

  void _showBlockedWithdrawalDialog(
    BuildContext context,
    StripeConnectAccountModel? stripe,
    double balance,
    double pendingWithdrawal, {
    String bucketLabel = '',
    bool awaitingBankDeposit = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saque indisponível'),
        content: Text(
          pendingWithdrawal > 0
              ? awaitingBankDeposit
                  ? 'Você já possui um saque${bucketLabel.isNotEmpty ? ' $bucketLabel' : ''} de ${_formatCurrency(pendingWithdrawal)} em análise. '
                      'Aguarde o depósito na sua conta bancária.'
                  : 'Você já possui um saque${bucketLabel.isNotEmpty ? ' $bucketLabel' : ''} de ${_formatCurrency(pendingWithdrawal)} aguardando aprovação.'
              : balance <= 0
                  ? 'Você ainda não possui saldo disponível para saque.'
                  : 'Sua conta bancária ainda não foi validada. Finalize seu cadastro para liberar os saques.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
          if (stripe?.payoutsEnabled == false ||
              !(stripe?.isReadyForPayout ?? false))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleOnboarding(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Finalizar cadastro'),
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
    final maxAmount = bucket.availableBalance;
    if (maxAmount <= 0) return;

    final amountController = TextEditingController(
      text: maxAmount.toStringAsFixed(2).replaceAll('.', ','),
    );

    final confirmedAmount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Solicitar saque ${bucket.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disponível: R\$ ${maxAmount.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor do saque',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Você pode solicitar vários saques enquanto houver saldo disponível.',
              style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.35),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = amountController.text
                  .replaceAll(',', '.')
                  .replaceAll(RegExp(r'[^0-9.]'), '');
              final amount = double.tryParse(raw) ?? 0;
              if (amount <= 0 || amount > maxAmount + 0.009) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      amount <= 0
                          ? 'Informe um valor válido.'
                          : 'Valor acima do saldo disponível.',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(ctx, amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    amountController.dispose();

    if (confirmedAmount == null || !context.mounted) return;

    setState(() => _isWithdrawing = true);
    context.read<BalanceBloc>().add(
          RequestWithdrawal(confirmedAmount, sourceBucket: bucket.bucket),
        );
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    return '$dd/$mm/$yyyy';
  }
}
