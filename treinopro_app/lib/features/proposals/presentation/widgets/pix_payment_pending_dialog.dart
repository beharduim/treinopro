import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/proposal_response_dto.dart';

/// Exibe QR/código PIX e orienta o aluno após gerar pagamento pendente.
Future<void> showPixPaymentPendingDialog(
  BuildContext context,
  PaymentData payment, {
  VoidCallback? onAcknowledged,
}) async {
  final qrImageUrl = payment.qrCodeImageUrl ?? payment.qrCodeBase64;
  final qrCode = payment.qrCode;
  final hostedInstructionsUrl = payment.hostedInstructionsUrl;
  final expiresAt = payment.expiresAt;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Pagamento PIX gerado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pague o PIX para confirmar a proposta. A busca por personal começa automaticamente após a confirmação do pagamento.',
              ),
              if (expiresAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Expira em ${expiresAt.day.toString().padLeft(2, '0')}/${expiresAt.month.toString().padLeft(2, '0')} às ${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')}.',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.secondaryDark.withValues(alpha: 0.7),
                  ),
                ),
              ],
              if (qrImageUrl != null && qrImageUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    qrImageUrl,
                    height: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.qr_code_2, size: 180),
                  ),
                ),
              ],
              if (qrCode != null && qrCode.isNotEmpty) ...[
                const SizedBox(height: 16),
                SelectableText(
                  qrCode,
                  maxLines: 4,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.secondaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: qrCode));
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Código PIX copiado'),
                          backgroundColor: AppColors.primaryOrange,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar código PIX'),
                ),
              ],
              if (hostedInstructionsUrl != null &&
                  hostedInstructionsUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(hostedInstructionsUrl);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir instruções de pagamento'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onAcknowledged?.call();
            },
            child: const Text('Entendi'),
          ),
        ],
      );
    },
  );
}
