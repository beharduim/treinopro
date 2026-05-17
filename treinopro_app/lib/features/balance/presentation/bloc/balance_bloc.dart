import 'package:flutter_bloc/flutter_bloc.dart';
import 'balance_event.dart';
import 'balance_state.dart';
import '../../../payouts/data/services/payout_methods_api_service.dart';
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
  }

  Future<void> _onLoadBalance(
    LoadBalance event,
    Emitter<BalanceState> emit,
  ) async {
    if (!event.silent) {
      emit(BalanceLoading());
    }

    try {
      // Carregar perfil financeiro (que agora inclui o wallet via getPayoutMethods)
      final profile = await _payoutApi.getFinancialProfile();
      
      // Carregar transações separadamente (pois o endpoint de perfil não traz histórico)
      final transactionsData = await _financialApi.getWalletTransactions(limit: 50);
      final transactions = transactionsData
          .map((data) => TransactionModel.fromJson(data))
          .toList();

      emit(BalanceLoaded(
        profile: profile,
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
}
