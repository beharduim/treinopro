import 'package:equatable/equatable.dart';

class WalletBucketModel {
  final String bucket;
  final double availableBalance;
  final double pendingBalance;
  final double pendingWithdrawalAmount;
  final bool hasOpenWithdrawal;
  final bool awaitingBankDeposit;
  final String settlementHint;

  const WalletBucketModel({
    required this.bucket,
    this.availableBalance = 0,
    this.pendingBalance = 0,
    this.pendingWithdrawalAmount = 0,
    this.hasOpenWithdrawal = false,
    this.awaitingBankDeposit = false,
    this.settlementHint = '',
  });

  factory WalletBucketModel.fromJson(
    Map<String, dynamic>? json, {
    String fallbackBucket = 'card',
  }) {
    if (json == null) {
      return WalletBucketModel(bucket: fallbackBucket);
    }

    return WalletBucketModel(
      bucket: (json['bucket'] ?? fallbackBucket).toString(),
      availableBalance: (json['availableBalance'] ?? 0.0).toDouble(),
      pendingBalance: (json['pendingBalance'] ?? 0.0).toDouble(),
      pendingWithdrawalAmount: (json['pendingWithdrawalAmount'] ?? 0.0).toDouble(),
      hasOpenWithdrawal: json['hasOpenWithdrawal'] == true,
      awaitingBankDeposit: json['awaitingBankDeposit'] == true,
      settlementHint: (json['settlementHint'] ?? '').toString(),
    );
  }

  String get title => bucket == 'pix' ? 'Pix' : 'Cartão';
}
