import 'package:flutter/material.dart';
import '../../../home/data/models/wallet_dashboard_model.dart';

class WalletWithdrawalStepper extends StatelessWidget {
  final List<WalletWithdrawalStepModel> steps;

  const WalletWithdrawalStepper({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: step.completed || step.current
                            ? const Color(0xFF2563EB)
                            : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: step.completed
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : step.current
                              ? Container(
                                  margin: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                            step.current ? FontWeight.w700 : FontWeight.w400,
                        color: step.current || step.completed
                            ? const Color(0xFF1E40AF)
                            : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: step.completed
                        ? const Color(0xFF2563EB)
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class WalletWithdrawalTrackerCard extends StatelessWidget {
  final WalletActiveWithdrawalModel withdrawal;
  final bool compact;

  const WalletWithdrawalTrackerCard({
    super.key,
    required this.withdrawal,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final requestedLabel = withdrawal.requestedAt != null
        ? 'Solicitado em ${_formatDate(withdrawal.requestedAt!)}'
        : 'Solicitado';

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 0),
      margin: EdgeInsets.only(bottom: compact ? 12 : 0),
      decoration: compact
          ? BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$requestedLabel • R\$ ${withdrawal.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 12 : 13,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(withdrawal.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  withdrawal.statusLabel,
                  style: TextStyle(
                    color: _statusColor(withdrawal.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (withdrawal.sourceLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Origem: ${withdrawal.sourceLabel}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 14),
          WalletWithdrawalStepper(steps: withdrawal.steps),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'completed' => const Color(0xFF15803D),
      'processing' => const Color(0xFF1D4ED8),
      'failed' || 'cancelled' => const Color(0xFFDC2626),
      _ => const Color(0xFF1D4ED8),
    };
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
