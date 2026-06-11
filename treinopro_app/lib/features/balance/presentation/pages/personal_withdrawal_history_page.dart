import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/dependency_injection.dart' show sl;
import '../../../home/data/models/wallet_dashboard_model.dart';
import '../../../home/data/services/personal_financial_api_service.dart';
import '../widgets/wallet_withdrawal_stepper.dart';

class PersonalWithdrawalHistoryPage extends StatefulWidget {
  const PersonalWithdrawalHistoryPage({super.key});

  @override
  State<PersonalWithdrawalHistoryPage> createState() =>
      _PersonalWithdrawalHistoryPageState();
}

class _PersonalWithdrawalHistoryPageState
    extends State<PersonalWithdrawalHistoryPage> {
  static const _pageSize = 20;

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  final List<WalletActiveWithdrawalModel> _items = [];
  int _offset = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _offset = 0;
        _items.clear();
        _hasMore = true;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final api = sl<PersonalFinancialApiService>();
      final raw = await api.getWithdrawalHistory(
        limit: _pageSize,
        offset: reset ? 0 : _offset,
      );
      final items = raw
          .map((e) => WalletActiveWithdrawalModel.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();

      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(items);
        } else {
          _items.addAll(items);
        }
        _offset = _items.length;
        _hasMore = items.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Histórico de saques'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.secondary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      TextButton(
                        onPressed: () => _load(reset: true),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _load(reset: true),
                  child: _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('Nenhum saque encontrado.')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _items.length) {
                              if (_loadingMore) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryOrange,
                                    ),
                                  ),
                                );
                              }
                              return Center(
                                child: TextButton(
                                  onPressed: () => _load(),
                                  child: const Text('Carregar mais'),
                                ),
                              );
                            }
                            return WalletWithdrawalTrackerCard(
                              withdrawal: _items[index],
                              compact: true,
                            );
                          },
                        ),
                ),
    );
  }
}
