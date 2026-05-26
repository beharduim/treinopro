import 'package:flutter_bloc/flutter_bloc.dart';
import 'balance_event.dart';
import 'balance_state.dart';
import '../../../payouts/data/services/payout_methods_api_service.dart';
import '../../../payouts/data/models/financial_profile_model.dart';
import '../../../home/data/services/personal_financial_api_service.dart';
import '../../../home/data/models/payment_models.dart';

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
      FinancialProfileModel profile;
      try {
        profile = await _payoutApi.getFinancialProfile();
      } catch (_) {
        profile = const FinancialProfileModel(
          preferredMethod: 'stripe_connect',
          canReceivePayments: false,
          stripeAccount: null,
          wallet: null,
        );
      }

      final walletData = await _financialApi.getWalletBalance();
      final wallet = WalletBalanceModel.fromJson(walletData);

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

      emit(BalanceLoaded(
        profile: enrichedProfile,
        transactions: transactions,
      ));
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

    try {
      final amountStr = event.amount.toStringAsFixed(2);
      final result = await _financialApi.requestWithdrawal(
        amount: amountStr,
        method: 'stripe_connect',
        description: 'Saque solicitado pelo app',
      );

      final message =
          'Solicitação enviada! Aguarde a aprovação da equipe TreinoPro. O valor ficará em processamento até a liberação.';

      emit(BalanceWithdrawSuccess(message));
      add(const LoadBalance(silent: true));
    } catch (e) {
      emit(BalanceError('Erro ao solicitar saque: $e'));
      emit(current);
    }
  }
}
