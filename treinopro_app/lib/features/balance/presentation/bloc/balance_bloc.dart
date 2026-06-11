import 'package:flutter_bloc/flutter_bloc.dart';
import 'balance_event.dart';
import 'balance_state.dart';
import '../../../payouts/data/services/payout_methods_api_service.dart';
import '../../../payouts/data/models/financial_profile_model.dart';
import '../../../home/data/services/personal_financial_api_service.dart';
import '../../../home/data/models/payment_models.dart';
import '../../../home/data/models/wallet_dashboard_model.dart';

class BalanceBloc extends Bloc<BalanceEvent, BalanceState> {
  final PayoutMethodsApiService _payoutApi;
  final PersonalFinancialApiService _financialApi;

  BalanceBloc({
    required PayoutMethodsApiService payoutApi,
    required PersonalFinancialApiService financialApi,
  })  : _payoutApi = payoutApi,
        _financialApi = financialApi,
        super(BalanceInitial()) {
    on<LoadBalance>(_onLoadBalance);
    on<RefreshBalance>(_onRefreshBalance);
    on<RequestWithdrawal>(_onRequestWithdrawal);
  }

  Future<void> _onLoadBalance(
    LoadBalance event,
    Emitter<BalanceState> emit,
  ) async {
    if (!event.silent) {
      emit(BalanceLoading());
    }

    try {
      final loaded = await _loadBalanceData();
      emit(loaded);
    } catch (e) {
      emit(BalanceError(e.toString()));
    }
  }

  Future<void> _onRefreshBalance(
    RefreshBalance event,
    Emitter<BalanceState> emit,
  ) async {
    add(const LoadBalance(silent: true));
  }

  Future<void> _onRequestWithdrawal(
    RequestWithdrawal event,
    Emitter<BalanceState> emit,
  ) async {
    final current = state;
    if (current is! BalanceLoaded) return;

    final bucket = event.sourceBucket == 'pix'
        ? current.profile.wallet?.pix
        : current.profile.wallet?.card;

    if (bucket == null || bucket.availableBalance <= 0) {
      emit(BalanceError(
        'Você não possui saldo disponível nesta carteira para sacar.',
      ));
      emit(current);
      return;
    }

    if (event.amount > bucket.availableBalance + 0.009) {
      emit(BalanceError(
        'Valor maior que o saldo disponível (${bucket.title}: R\$ ${bucket.availableBalance.toStringAsFixed(2).replaceAll('.', ',')}).',
      ));
      emit(current);
      return;
    }

    try {
      final result = await _financialApi.requestWithdrawal(
        amount: event.amount.toStringAsFixed(2),
        method: 'stripe_connect',
        sourceBucket: event.sourceBucket,
        description: 'Saque ${event.sourceBucket == 'pix' ? 'Pix' : 'Cartão'} solicitado pelo app',
      );

      final isIdempotent = result['idempotent'] == true;
      final walletJson = result['wallet'];
      BalanceLoaded updatedState = current;

      if (walletJson is Map<String, dynamic>) {
        updatedState = await _loadBalanceData();
      } else {
        updatedState = await _loadBalanceData();
      }

      emit(updatedState.copyWith(
        successMessage: isIdempotent
            ? 'Saque ${bucket.title} já registrado. Aguarde a aprovação.'
            : 'Solicitação de saque ${bucket.title} de R\$ ${event.amount.toStringAsFixed(2).replaceAll('.', ',')} enviada!',
      ));
    } catch (e) {
      emit(BalanceError('Erro ao solicitar saque: $e'));
      emit(current);
    }
  }

  Future<BalanceLoaded> _loadBalanceData() async {
    FinancialProfileModel profile;
    try {
      await _payoutApi.ensureStripeConnectedAccount();
      profile = await _payoutApi.getFinancialProfile();
    } catch (_) {
      try {
        profile = await _payoutApi.getFinancialProfile();
      } catch (__) {
        profile = const FinancialProfileModel(
          preferredMethod: 'stripe_connect',
          canReceivePayments: false,
          stripeAccount: null,
          wallet: null,
        );
      }
    }

    final dashboardData = await _financialApi.getWalletDashboard();
    final dashboard = WalletDashboardModel.fromJson(dashboardData);

    final walletJson = dashboardData['wallet'];
    final wallet = walletJson is Map<String, dynamic>
        ? WalletBalanceModel.fromJson(walletJson)
        : WalletBalanceModel.fromJson(
            await _financialApi.getWalletBalance(),
          );

    final enrichedProfile = FinancialProfileModel(
      preferredMethod: profile.preferredMethod,
      canReceivePayments: profile.canReceivePayments,
      stripeAccount: profile.stripeAccount,
      wallet: wallet,
    );

    final transactionsData =
        await _financialApi.getWalletTransactions(limit: 50);
    final transactions = transactionsData
        .map((data) => TransactionModel.fromJson(data))
        .toList();

    return BalanceLoaded(
      profile: enrichedProfile,
      transactions: transactions,
      dashboard: dashboard,
    );
  }
}
