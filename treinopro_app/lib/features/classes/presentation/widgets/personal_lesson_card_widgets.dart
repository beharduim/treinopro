import 'package:flutter/material.dart';
import '../../data/models/class_response_dto.dart';

class PersonalLessonCardWidgets {
  static String formatPrice(double? price) {
    final classPrice = price ?? 0.0;
    return 'R\$ ${classPrice.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static bool hasMeta(ClassResponseDto classData) {
    final modality = classData.proposalModality?.trim();
    final payment = classData.paymentMethod?.trim();
    final price = classData.proposalPrice;
    return (modality != null && modality.isNotEmpty) ||
        (payment != null && payment.isNotEmpty) ||
        (price != null && price > 0);
  }

  static String paymentMethodLabel(String? method) {
    final normalized = (method ?? '').toLowerCase();
    if (normalized.contains('pix')) return 'PIX';
    if (normalized.contains('card') ||
        normalized.contains('cartao') ||
        normalized.contains('credit') ||
        normalized.contains('debit')) {
      return 'Cartão';
    }
    if (method == null || method.trim().isEmpty) return '';
    return method.trim();
  }

  static Color paymentMethodColor(String? method, Color fallback) {
    final normalized = (method ?? '').toLowerCase();
    if (normalized.contains('pix')) return const Color(0xFF0EA5E9);
    if (normalized.contains('card') ||
        normalized.contains('cartao') ||
        normalized.contains('credit') ||
        normalized.contains('debit')) {
      return const Color(0xFF10B981);
    }
    return fallback;
  }

  static String formatStudentName(String name, {String? studentId}) {
    if (name.trim().isEmpty) {
      if (studentId != null && studentId.isNotEmpty) return 'Aluno';
      return 'Usuário removido';
    }
    return name
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  static Widget metaRow(
    ClassResponseDto classData, {
    required Color accentColor,
  }) {
    final modality = classData.proposalModality?.trim();
    final paymentLabel = paymentMethodLabel(classData.paymentMethod);
    final price = classData.proposalPrice;
    final paymentColor = paymentMethodColor(classData.paymentMethod, accentColor);

    final hasModality = modality != null && modality.isNotEmpty;
    final hasPayment = paymentLabel.isNotEmpty;
    final hasPrice = price != null && price > 0;

    if (!hasModality && !hasPayment && !hasPrice) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasModality) ...[
            Icon(Icons.fitness_center, size: 14, color: accentColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                modality!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                  height: 1.2,
                ),
              ),
            ),
          ],
          if (hasPayment) ...[
            if (hasModality) _metaSeparator(),
            Icon(
              paymentLabel == 'PIX'
                  ? Icons.bolt_rounded
                  : Icons.credit_card_rounded,
              size: 14,
              color: paymentColor,
            ),
            const SizedBox(width: 4),
            Text(
              paymentLabel,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: paymentColor,
                height: 1.2,
              ),
            ),
          ],
          if (hasPrice) ...[
            if (hasModality || hasPayment) _metaSeparator(),
            Icon(Icons.payments_outlined, size: 14, color: accentColor),
            const SizedBox(width: 4),
            Text(
              formatPrice(price),
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accentColor,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _metaSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        '·',
        style: TextStyle(
          fontFamily: 'Fira Sans',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade400,
          height: 1.2,
        ),
      ),
    );
  }

  static Widget statusBadge({
    required String text,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static Widget lessonInfoRow({
    required IconData dateIcon,
    required String dateLabel,
    required String dateValue,
    required String timeValue,
    required String durationValue,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _infoItem(dateIcon, dateLabel, dateValue),
        _infoItem(Icons.access_time, 'Horário', timeValue),
        _infoItem(Icons.timer, 'Duração', durationValue),
      ],
    );
  }

  static Widget _infoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF42464D)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 10,
              color: Color(0xFF42464D),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }
}
