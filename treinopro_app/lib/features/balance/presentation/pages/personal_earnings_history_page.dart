import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/dependency_injection.dart' show sl;
import '../../../home/data/models/wallet_dashboard_model.dart';
import '../../../home/data/services/personal_financial_api_service.dart';

class PersonalEarningsHistoryPage extends StatefulWidget {
  const PersonalEarningsHistoryPage({super.key});

  @override
  State<PersonalEarningsHistoryPage> createState() =>
      _PersonalEarningsHistoryPageState();
}

class _PersonalEarningsHistoryPageState
    extends State<PersonalEarningsHistoryPage> {
  static const _pageSize = 20;

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  final List<WalletEarningItemModel> _items = [];
  int _offset = 0;
  int _total = 0;

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
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final api = sl<PersonalFinancialApiService>();
      final data = await api.getWalletEarnings(
        limit: _pageSize,
        offset: reset ? 0 : _offset,
      );
      final items = (data['items'] as List? ?? [])
          .map((e) => WalletEarningItemModel.fromJson(
              Map<String, dynamic>.from(e as Map)))
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
        _total = data['total'] is int
            ? data['total'] as int
            : int.tryParse(data['total']?.toString() ?? '') ?? _items.length;
        _offset = _items.length;
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
        title: const Text('Histórico de ganhos'),
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
                            Center(child: Text('Nenhuma aula encontrada.')),
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
                            return _earningCard(_items[index]);
                          },
                        ),
                ),
    );
  }

  bool get _hasMore => _items.length < _total;

  Widget _earningCard(WalletEarningItemModel item) {
    final isPix = item.sourceBucket == 'pix';
    final released = item.isReleased;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
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
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'R\$ ${item.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        ],
      ),
    );
  }
}
