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

    if (current.profile.wallet?.hasOpenWithdrawal == true) {
      emit(BalanceError(
        'Você já possui um saque aguardando aprovação. Aguarde a liberação da equipe TreinoPro.',
      ));
      emit(current);
      return;
    }

    try {
      final result = await _financialApi.requestWithdrawal(
        amount: event.amount.toStringAsFixed(2),
        method: 'stripe_connect',
        description: 'Saque solicitado pelo app',
      );

      final isIdempotent = result['idempotent'] == true;
      final walletJson = result['wallet'];
      BalanceLoaded updatedState = current;

      if (walletJson is Map<String, dynamic>) {
        final wallet = WalletBalanceModel.fromJson(walletJson);
        updatedState = BalanceLoaded(
          profile: FinancialProfileModel(
            preferredMethod: current.profile.preferredMethod,
            canReceivePayments: current.profile.canReceivePayments,
            stripeAccount: current.profile.stripeAccount,
            wallet: wallet,
          ),
          transactions: current.transactions,
        );
      } else {
        updatedState = await _loadBalanceData();
      }

      emit(updatedState.copyWith(
        successMessage: isIdempotent
            ? 'Você já possui um saque de R\$ ${(updatedState.profile.wallet?.pendingWithdrawalAmount ?? event.amount).toStringAsFixed(2).replaceAll('.', ',')} aguardando aprovação.'
            : 'Solicitação enviada! Aguarde a aprovação da equipe TreinoPro. O valor ficará em processamento até a liberação.',
      ));
    } catch (e) {
      emit(BalanceError('Erro ao solicitar saque: $e'));
      emit(current);
    }
  }

  Future<BalanceLoaded> _loadBalanceData() async {
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

    return BalanceLoaded(
      profile: enrichedProfile,
      transactions: transactions,
    );
  }
}
