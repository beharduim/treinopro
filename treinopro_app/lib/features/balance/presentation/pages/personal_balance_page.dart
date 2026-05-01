import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/data/services/personal_financial_api_service.dart';
import '../../../home/data/models/payment_models.dart';
import '../../../../core/di/dependency_injection.dart' show sl;
import '../../../payouts/presentation/widgets/add_payout_method_bottom_sheet.dart';
import '../../../payouts/data/services/payout_methods_api_service.dart';
import '../../../payouts/data/models/financial_profile_model.dart';

/// Página de saldo do personal trainer
class PersonalBalancePage extends StatefulWidget {
  const PersonalBalancePage({super.key});

  @override
  State<PersonalBalancePage> createState() => _PersonalBalancePageState();
}

class _PersonalBalancePageState extends State<PersonalBalancePage> {
  int _selectedHistoryTab = 1; // 0: Semana, 1: Mês, 2: Ano

  bool _isLoading = true;
  bool _isLoadingTransactions = false;
  bool _isRequestingWithdrawal = false;
  String? _error;

  // Dados da carteira
  double _availableBalance = 0.0;
  double _totalEarned = 0.0;

  // Dados de ganhos por período
  double _thisMonthEarned = 0.0;
  double _thisWeekEarned = 0.0;

  // Histórico de transações
  List<TransactionModel> _transactions = [];

  final PersonalFinancialApiService _financialApi =
      sl<PersonalFinancialApiService>();
  final PayoutMethodsApiService _payoutApi = sl<PayoutMethodsApiService>();

  FinancialProfileModel? _financialProfile;
  StripeConnectAccountModel? get _stripeAccount =>
      _financialProfile?.stripeAccount;

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
    _loadPayoutMethods();
  }

  Future<void> _loadFinancialData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('💰 [BALANCE] Carregando dados financeiros...');

      // Carregar dados da carteira
      final walletData = await _financialApi.getWalletBalance();
      final wallet = WalletBalanceModel.fromJson(walletData);

      // Carregar transações
      await _loadTransactions();

      setState(() {
        _availableBalance = wallet.availableBalance;
        _totalEarned = wallet.totalEarned;

        // Calcular ganhos do mês atual
        _thisMonthEarned = _calculateMonthlyEarnings();
        _thisWeekEarned = _calculateWeeklyEarnings();

        _isLoading = false;
      });

      print('✅ [BALANCE] Dados financeiros carregados com sucesso');
      print(
        '💰 [BALANCE] Saldo disponível: R\$ ${_availableBalance.toStringAsFixed(2)}',
      );
      print('💰 [BALANCE] Total ganho: R\$ ${_totalEarned.toStringAsFixed(2)}');
    } catch (e) {
      print('❌ [BALANCE] Erro ao carregar dados financeiros: $e');
      // Graceful degrade: mostra valores 0 e não bloqueia a UI
      setState(() {
        _availableBalance = 0;
        _totalEarned = 0;
        _thisMonthEarned = 0;
        _thisWeekEarned = 0;
        _error = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTransactions() async {
    try {
      setState(() {
        _isLoadingTransactions = true;
      });

      final transactionsData = await _financialApi.getWalletTransactions(
        limit: 50,
      );
      final transactions = transactionsData
          .map((data) => TransactionModel.fromJson(data))
          .toList();

      setState(() {
        _transactions = transactions;
        _isLoadingTransactions = false;
      });

      print('📜 [BALANCE] ${transactions.length} transações carregadas');
    } catch (e) {
      print('❌ [BALANCE] Erro ao carregar transações: $e');
      setState(() {
        _isLoadingTransactions = false;
      });
    }
  }

  double _calculateMonthlyEarnings() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    print('📅 [MONTHLY_CALC] Data atual: $now');
    print('📅 [MONTHLY_CALC] Início do mês: $startOfMonth');
    print('📅 [MONTHLY_CALC] Transações disponíveis: ${_transactions.length}');

    final monthlyTransactions = _transactions
        .where(
          (transaction) =>
              transaction.createdAt.isAfter(startOfMonth) &&
              transaction.type == 'personal_earnings' &&
              transaction.status == 'captured',
        )
        .toList();

    print('📅 [MONTHLY_CALC] Transações do mês: ${monthlyTransactions.length}');
    for (final transaction in monthlyTransactions) {
      print(
        '📅 [MONTHLY_CALC] - ${transaction.createdAt}: R\$ ${transaction.amount}',
      );
    }

    final total = monthlyTransactions.fold(
      0.0,
      (sum, transaction) => sum + transaction.amount,
    );
    print('📅 [MONTHLY_CALC] Total do mês: R\$ $total');

    return total;
  }

  double _calculateWeeklyEarnings() {
    final now = DateTime.now();
    // Corrigir cálculo do início da semana (segunda-feira = 1, domingo = 7)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    // Definir início da semana às 00:00:00
    final startOfWeekAtMidnight = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    final weeklyTransactions = _transactions
        .where(
          (transaction) =>
              transaction.createdAt.isAfter(startOfWeekAtMidnight) &&
              transaction.type == 'personal_earnings' &&
              transaction.status == 'captured',
        )
        .toList();

    final total = weeklyTransactions.fold(
      0.0,
      (sum, transaction) => sum + transaction.amount,
    );

    return total;
  }

  Future<void> _loadPayoutMethods() async {
    try {
      final profile = await _payoutApi.getFinancialProfile();
      setState(() {
        _financialProfile = profile;
      });
    } catch (e) {
      // Não definir erro aqui para não quebrar a página principal
    }
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _getWithdrawalStatusText() {
    if (_isRequestingWithdrawal) {
      return 'Solicitando saque...';
    }
    if (_availableBalance <= 0) {
      return 'Sem saldo disponível';
    }
    if (_stripeAccount == null) {
      return 'Configure seu recebimento';
    }
    if (!(_stripeAccount?.isReadyForPayout ?? false)) {
      return 'Finalize o onboarding';
    }
    return 'Solicitar saque';
  }

  bool _canRequestWithdrawal() {
    return !_isRequestingWithdrawal &&
        _availableBalance > 0 &&
        (_stripeAccount?.isReadyForPayout ?? false);
  }

  Future<void> _handleWithdrawalRequest() async {
    if (!_canRequestWithdrawal()) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D3748),
          title: const Text(
            'Solicitar saque',
            style: TextStyle(fontFamily: 'Outfit', color: Colors.white),
          ),
          content: Text(
            'Deseja solicitar o saque de ${_formatCurrency(_availableBalance)} para a conta de recebimento conectada?',
            style: const TextStyle(
              fontFamily: 'Fira Sans',
              color: Color(0xFFE5E7EB),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: const Color(0xFF2D3748),
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      setState(() {
        _isRequestingWithdrawal = true;
      });

      await _financialApi.requestWithdrawal(
        amount: _availableBalance.toStringAsFixed(2),
        method: 'bank_transfer',
        description: 'Solicitação de saque pelo app',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Saque solicitado com sucesso. O valor ficará em processamento.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _loadFinancialData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao solicitar saque: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingWithdrawal = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFE),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar com botão voltar e título
            _buildTopBar(),
            // Conteúdo principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Card principal de saldo
                    _buildBalanceCard(),
                    const SizedBox(height: 16),
                    // Card de histórico
                    _buildHistoryCard(),
                    const SizedBox(height: 16),
                    // Card de conta bancária
                    _buildBankAccountCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Botão voltar (ajustado para corresponder ao layout do Figma)
          IconButton(
            padding: EdgeInsets.zero,
            iconSize: 28,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.chevron_left,
              size: 28,
              color: Color(0xFF2D3748),
            ),
          ),
          // Título centralizado
          Expanded(
            child: Text(
              'Seus ganhos',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          // Espaço para balancear o layout
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF42464D), width: 0.24),
      ),
      child: Column(
        children: [
          if (_error != null) ...[
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 14,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Título com ícone e informação sobre saque
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 20,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 8),
              const Text(
                'Saldo disponível',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF9F9F9),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Os saques podem ser solicitados a qualquer momento. Após a solicitação, o valor ficará em análise e processamento.',
                        style: TextStyle(fontFamily: 'Fira Sans', fontSize: 14),
                      ),
                      backgroundColor: Color(0xFF2D3748),
                      duration: Duration(seconds: 4),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Icon(
                  Icons.help_outline,
                  size: 18,
                  color: AppColors.primaryOrange.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Valor principal
          _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _formatCurrency(_availableBalance),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF9F9F9),
                  ),
                ),
          const SizedBox(height: 24),
          // Botão de saque
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _canRequestWithdrawal()
                      ? _handleWithdrawalRequest
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          _getWithdrawalStatusText(),
                          style: TextStyle(
                            fontFamily: 'Fira Sans',
                            fontSize: 16,
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Divisor
          Container(height: 1, color: const Color(0xFFF9F9F9)),
          const SizedBox(height: 24),
          // Valores de ganhos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Este mês
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Este mês',
                        style: TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 12,
                          color: Color(0xFFF9F9F9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _formatCurrency(_thisMonthEarned),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF9F9F9),
                          ),
                        ),
                ],
              ),
              // Esta semana
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.primaryOrange,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Esta semana',
                        style: TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 12,
                          color: Color(0xFFF9F9F9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _formatCurrency(_thisWeekEarned),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF9F9F9),
                          ),
                        ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF42464D), width: 0.24),
      ),
      child: Column(
        children: [
          // Título com ícone
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.history,
                size: 20,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 8),
              const Text(
                'Seu histórico',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Abas
          Row(
            children: [
              Expanded(child: _buildHistoryTab('Semana', 0)),
              const SizedBox(width: 8),
              Expanded(child: _buildHistoryTab('Mês', 1)),
              const SizedBox(width: 8),
              Expanded(child: _buildHistoryTab('Ano', 2)),
            ],
          ),
          const SizedBox(height: 24),
          // Lista de meses
          _buildHistoryList(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(String label, int index) {
    final isSelected = _selectedHistoryTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedHistoryTab = index;
        });
        // Recarregar dados baseado na aba selecionada
        _loadTransactions();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryOrange, width: 1),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            color: isSelected
                ? const Color(0xFF2D3748)
                : AppColors.primaryOrange,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_isLoadingTransactions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Nenhuma transação encontrada',
            style: TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 16,
              color: Color(0xFFF3F3F3),
            ),
          ),
        ),
      );
    }

    // Filtrar transações baseado na aba selecionada
    List<TransactionModel> filteredTransactions = _getFilteredTransactions();

    if (filteredTransactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Nenhuma transação encontrada para este período',
            style: TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 16,
              color: Color(0xFFF3F3F3),
            ),
          ),
        ),
      );
    }

    // Se for aba "Semana", mostrar transações individuais com data/hora
    if (_selectedHistoryTab == 0) {
      return Column(
        children: filteredTransactions.map((transaction) {
          final dateTime = transaction.createdAt;
          final dateStr =
              '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
          final timeStr =
              '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

          final isLast = transaction == filteredTransactions.last;

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF9F9F9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 16,
                          color: Color(0xFFF3F3F3),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'R\$ ${transaction.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      color: Color(0xFFF3F3F3),
                    ),
                  ),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: 16),
                Container(height: 1, color: const Color(0xFFF9F9F9)),
                const SizedBox(height: 16),
              ],
            ],
          );
        }).toList(),
      );
    }

    // Se for aba "Ano", mostrar total do ano
    if (_selectedHistoryTab == 2) {
      final totalAmount = filteredTransactions
          .where((t) => t.type == 'personal_earnings' && t.status == 'captured')
          .fold(0.0, (sum, t) => sum + t.amount);
      final classesCount = filteredTransactions
          .where((t) => t.type == 'personal_earnings' && t.status == 'captured')
          .length;

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateTime.now().year}',
                    style: const TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF9F9F9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$classesCount ${classesCount == 1 ? 'aula' : 'aulas'}',
                    style: const TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 16,
                      color: Color(0xFFF3F3F3),
                    ),
                  ),
                ],
              ),
              Text(
                'R\$ ${totalAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  color: Color(0xFFF3F3F3),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Para "Mês" e "Tudo", agrupar por mês
    final Map<String, List<TransactionModel>> transactionsByMonth = {};

    for (final transaction in filteredTransactions) {
      final monthKey =
          '${transaction.createdAt.year}-${transaction.createdAt.month.toString().padLeft(2, '0')}';

      if (!transactionsByMonth.containsKey(monthKey)) {
        transactionsByMonth[monthKey] = [];
      }
      transactionsByMonth[monthKey]!.add(transaction);
    }

    // Converter para lista ordenada por data
    final sortedMonths = transactionsByMonth.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Mais recente primeiro

    return Column(
      children: sortedMonths.map((monthKey) {
        final transactions = transactionsByMonth[monthKey]!;
        final monthName = _getMonthName(int.parse(monthKey.split('-')[1]));
        final totalAmount = transactions
            .where(
              (t) => t.type == 'personal_earnings' && t.status == 'captured',
            )
            .fold(0.0, (sum, t) => sum + t.amount);
        final classesCount = transactions
            .where(
              (t) => t.type == 'personal_earnings' && t.status == 'captured',
            )
            .length;

        final isLast = monthKey == sortedMonths.last;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthName,
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF9F9F9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$classesCount ${classesCount == 1 ? 'aula' : 'aulas'}',
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                        color: Color(0xFFF3F3F3),
                      ),
                    ),
                  ],
                ),
                Text(
                  'R\$ ${totalAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    color: Color(0xFFF3F3F3),
                  ),
                ),
              ],
            ),
            if (!isLast) ...[
              const SizedBox(height: 16),
              Container(height: 1, color: const Color(0xFFF9F9F9)),
              const SizedBox(height: 16),
            ],
          ],
        );
      }).toList(),
    );
  }

  List<TransactionModel> _getFilteredTransactions() {
    final now = DateTime.now();

    switch (_selectedHistoryTab) {
      case 0: // Semana
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekAtMidnight = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        print('📅 [FILTER_WEEK] Início da semana: $startOfWeekAtMidnight');
        final weekTransactions = _transactions
            .where((t) => t.createdAt.isAfter(startOfWeekAtMidnight))
            .toList();
        print(
          '📅 [FILTER_WEEK] Transações filtradas: ${weekTransactions.length}',
        );
        return weekTransactions;

      case 1: // Mês
        final startOfMonth = DateTime(now.year, now.month, 1);
        print('📅 [FILTER_MONTH] Início do mês: $startOfMonth');
        final monthTransactions = _transactions
            .where((t) => t.createdAt.isAfter(startOfMonth))
            .toList();
        print(
          '📅 [FILTER_MONTH] Transações filtradas: ${monthTransactions.length}',
        );
        return monthTransactions;

      case 2: // Ano
      default:
        final startOfYear = DateTime(now.year, 1, 1);
        print('📅 [FILTER_YEAR] Início do ano: $startOfYear');
        final yearTransactions = _transactions
            .where((t) => t.createdAt.isAfter(startOfYear))
            .toList();
        print(
          '📅 [FILTER_YEAR] Transações filtradas: ${yearTransactions.length}',
        );
        return yearTransactions;
    }
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  Widget _buildBankAccountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF42464D), width: 0.24),
      ),
      child: Column(
        children: [
          // Título com ícone
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.credit_card,
                size: 20,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Métodos de recebimento',
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Aviso de recebimento
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue[300], size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'O TreinoPro cria sua conta conectada automaticamente. Para liberar saques, conclua o onboarding embutido e cadastre sua conta bancária.',
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 14,
                      color: Color(0xFF93C5FD), // tailwind blue-300
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Containers de métodos de recebimento
          _buildPayoutItems(),
        ],
      ),
    );
  }

  Widget _buildPayoutItems() {
    return Column(
      children: [
        _buildMethodOption(
          title: 'Conta bancária via TreinoPro',
          subtitle: _buildReceivingSubtitle(),
          icon: Icons.account_balance_wallet,
          color: AppColors.primaryOrange,
          isSelected: _stripeAccount?.isReadyForPayout ?? false,
          onTap: _onConfigureReceiving,
        ),
      ],
    );
  }

  String _buildReceivingSubtitle() {
    if (_stripeAccount == null) {
      return 'Complete seu onboarding embutido para liberar saques';
    }
    if (_stripeAccount!.isReadyForPayout) {
      return 'Conta apta para saque';
    }

    final count = _stripeAccount!.outstandingRequirements.length;
    if (count > 0) {
      return 'Faltam $count requisito${count == 1 ? '' : 's'} para liberar saques';
    }

    return 'Continue o onboarding para concluir sua configuração';
  }

  Widget _buildMethodOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color.fromRGBO(226, 232, 240, 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryOrange, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 13,
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? AppColors.primaryOrange
                  : const Color(0xFFCBD5E0),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _onConfigureReceiving() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AddPayoutMethodBottomSheet(
          initialType: PayoutMethodType.stripeConnect,
          onSaved: () {
            _loadPayoutMethods();
          },
        );
      },
    );
  }
}
