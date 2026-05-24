import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../data/models/class_dispute_dto.dart';
import '../../data/models/class_response_dto.dart';
import '../../data/services/classes_api_service.dart';
import '../bloc/classes_bloc.dart';
import '../utils/dispute_hub_labels.dart';
import '../widgets/dispute_defense_modal.dart';

class DisputeDetailPage extends StatefulWidget {
  final String disputeId;

  const DisputeDetailPage({super.key, required this.disputeId});

  @override
  State<DisputeDetailPage> createState() => _DisputeDetailPageState();
}

class _DisputeDetailPageState extends State<DisputeDetailPage> {
  final _api = sl<ClassesApiService>();
  ClassDisputeDto? _dispute;
  ClassResponseDto? _classData;
  String? _currentUserId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = sl<SharedPreferences>();
      _currentUserId = prefs.getString('user_id');

      final dispute = await _api.getClassDisputeById(widget.disputeId);
      ClassResponseDto? classData;
      try {
        classData = await _api.getClassById(widget.disputeId);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _dispute = dispute;
        _classData = classData;
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

  Future<void> _openDefenseModal() async {
    final classData = _classData;
    if (classData == null) return;

    await DisputeDefenseModal.show(
      context,
      widget.disputeId,
      classData,
    );
    _load();
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
          'Detalhe da disputa',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF2D3748),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final dispute = _dispute!;
    final canDefend = _currentUserId != null &&
        DisputeHubLabels.canUserSubmitDefense(
          dispute: dispute,
          currentUserId: _currentUserId!,
        );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(dispute: dispute),
          const SizedBox(height: 16),
          _InfoSection(
            title: 'Participantes',
            children: [
              _InfoRow('Reportado por', dispute.reporterName ?? dispute.reportedBy),
              _InfoRow('Envolvido', dispute.reportedUserName ?? '—'),
              _InfoRow(
                'Abertura',
                _formatDateTime(dispute.reportedAt),
              ),
              if (dispute.resolvedAt != null)
                _InfoRow(
                  'Encerramento',
                  _formatDateTime(dispute.resolvedAt!),
                ),
            ],
          ),
          if (dispute.studentDefenseText != null ||
              dispute.personalDefenseText != null) ...[
            const SizedBox(height: 16),
            _InfoSection(
              title: 'Defesas enviadas',
              children: [
                if (dispute.studentDefenseText != null)
                  _InfoRow('Aluno', dispute.studentDefenseText!),
                if (dispute.personalDefenseText != null)
                  _InfoRow('Personal', dispute.personalDefenseText!),
              ],
            ),
          ],
          if (dispute.isResolved) ...[
            const SizedBox(height: 16),
            _InfoSection(
              title: 'Decisão final',
              children: [
                _InfoRow(
                  'Resultado',
                  DisputeHubLabels.statusTitle(dispute),
                ),
                if (dispute.resolution != null && dispute.resolution!.isNotEmpty)
                  _InfoRow('Detalhes', dispute.resolution!),
              ],
            ),
          ],
          if (canDefend && _classData != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openDefenseModal,
                icon: const Icon(Icons.upload_file),
                label: const Text('Enviar minha defesa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} ${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusCard extends StatelessWidget {
  final ClassDisputeDto dispute;

  const _StatusCard({required this.dispute});

  @override
  Widget build(BuildContext context) {
    final color = dispute.isResolved
        ? (dispute.isResolvedForStudent
              ? Colors.blue.shade700
              : Colors.green.shade700)
        : Colors.orange.shade800;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DisputeHubLabels.statusTitle(dispute),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DisputeHubLabels.statusSubtitle(dispute),
            style: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E9EE)),
      ),
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
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
