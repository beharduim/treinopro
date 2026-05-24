import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../data/models/class_dispute_dto.dart';
import '../../data/services/classes_api_service.dart';
import '../bloc/classes_bloc.dart';
import '../utils/dispute_hub_labels.dart';
import 'dispute_detail_page.dart';

class MyDisputesPage extends StatefulWidget {
  const MyDisputesPage({super.key});

  @override
  State<MyDisputesPage> createState() => _MyDisputesPageState();
}

class _MyDisputesPageState extends State<MyDisputesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _api = sl<ClassesApiService>();

  List<ClassDisputeDto> _openDisputes = [];
  List<ClassDisputeDto> _resolvedDisputes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDisputes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDisputes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getClassDisputes(status: 'open'),
        _api.getClassDisputes(status: 'resolved'),
      ]);

      if (!mounted) return;
      setState(() {
        _openDisputes = results[0];
        _resolvedDisputes = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
        title: const Text(
          'Minhas Disputas',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Color(0xFF2D3748),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryOrange,
          tabs: const [
            Tab(text: 'Em andamento'),
            Tab(text: 'Encerradas'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_openDisputes, emptyMessage: 'Nenhuma disputa em andamento.'),
                _buildList(
                  _resolvedDisputes,
                  emptyMessage: 'Nenhuma disputa encerrada.',
                ),
              ],
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Não foi possível carregar suas disputas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDisputes,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    List<ClassDisputeDto> disputes, {
    required String emptyMessage,
  }) {
    if (disputes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadDisputes,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Text(
                  emptyMessage,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDisputes,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: disputes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final dispute = disputes[index];
          return _DisputeListTile(
            dispute: dispute,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<ClassesBloc>(),
                    child: DisputeDetailPage(disputeId: dispute.classId),
                  ),
                ),
              );
              _loadDisputes();
            },
          );
        },
      ),
    );
  }
}

class _DisputeListTile extends StatelessWidget {
  final ClassDisputeDto dispute;
  final VoidCallback onTap;

  const _DisputeListTile({
    required this.dispute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final counterpart = dispute.reportedUserName ?? dispute.reporterName ?? 'Participante';
    final title = DisputeHubLabels.statusTitle(dispute);
    final subtitle = DisputeHubLabels.statusSubtitle(dispute);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E9EE)),
          ),
          child: Row(
            children: [
              Icon(
                dispute.isResolved ? Icons.check_circle_outline : Icons.gavel,
                color: dispute.isResolved
                    ? Colors.green.shade600
                    : Colors.orange.shade700,
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
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      counterpart,
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 13,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
