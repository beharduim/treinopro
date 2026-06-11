class WalletPendingReleaseItemModel {
  final String paymentId;
  final String? classId;
  final String? classDate;
  final String? studentName;
  final String sourceBucket;
  final String sourceLabel;
  final double amount;
  final DateTime? releaseAt;
  final String releaseForecast;

  const WalletPendingReleaseItemModel({
    required this.paymentId,
    this.classId,
    this.classDate,
    this.studentName,
    required this.sourceBucket,
    required this.sourceLabel,
    required this.amount,
    this.releaseAt,
    required this.releaseForecast,
  });

  factory WalletPendingReleaseItemModel.fromJson(Map<String, dynamic> json) {
    return WalletPendingReleaseItemModel(
      paymentId: json['paymentId']?.toString() ?? '',
      classId: json['classId']?.toString(),
      classDate: json['classDate']?.toString(),
      studentName: json['studentName']?.toString(),
      sourceBucket: json['sourceBucket']?.toString() ?? 'card',
      sourceLabel: json['sourceLabel']?.toString() ?? 'Cartão',
      amount: _parseAmount(json['amount']),
      releaseAt: json['releaseAt'] != null
          ? DateTime.tryParse(json['releaseAt'].toString())
          : null,
      releaseForecast: json['releaseForecast']?.toString() ?? '',
    );
  }
}

class WalletWithdrawalStepModel {
  final String key;
  final String label;
  final bool completed;
  final bool current;

  const WalletWithdrawalStepModel({
    required this.key,
    required this.label,
    required this.completed,
    required this.current,
  });

  factory WalletWithdrawalStepModel.fromJson(Map<String, dynamic> json) {
    return WalletWithdrawalStepModel(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      completed: json['completed'] == true,
      current: json['current'] == true,
    );
  }
}

class WalletActiveWithdrawalModel {
  final String id;
  final double amount;
  final String sourceBucket;
  final String sourceLabel;
  final String status;
  final String statusLabel;
  final DateTime? requestedAt;
  final int currentStep;
  final List<WalletWithdrawalStepModel> steps;

  const WalletActiveWithdrawalModel({
    required this.id,
    required this.amount,
    required this.sourceBucket,
    required this.sourceLabel,
    required this.status,
    required this.statusLabel,
    this.requestedAt,
    required this.currentStep,
    required this.steps,
  });

  factory WalletActiveWithdrawalModel.fromJson(Map<String, dynamic> json) {
    final stepsJson = json['steps'];
    return WalletActiveWithdrawalModel(
      id: json['id']?.toString() ?? '',
      amount: _parseAmount(json['amount']),
      sourceBucket: json['sourceBucket']?.toString() ?? 'card',
      sourceLabel: json['sourceLabel']?.toString() ?? 'Cartão',
      status: json['status']?.toString() ?? '',
      statusLabel: json['statusLabel']?.toString() ?? '',
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'].toString())
          : null,
      currentStep: json['currentStep'] is int
          ? json['currentStep'] as int
          : int.tryParse(json['currentStep']?.toString() ?? '') ?? 1,
      steps: stepsJson is List
          ? stepsJson
              .map((e) =>
                  WalletWithdrawalStepModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class WalletEarningItemModel {
  final String paymentId;
  final String? classId;
  final String? classDate;
  final String? studentName;
  final String sourceBucket;
  final String sourceLabel;
  final double amount;
  final String releaseStatus;
  final String releaseStatusLabel;
  final DateTime? capturedAt;

  const WalletEarningItemModel({
    required this.paymentId,
    this.classId,
    this.classDate,
    this.studentName,
    required this.sourceBucket,
    required this.sourceLabel,
    required this.amount,
    required this.releaseStatus,
    required this.releaseStatusLabel,
    this.capturedAt,
  });

  bool get isReleased => releaseStatus == 'released';

  factory WalletEarningItemModel.fromJson(Map<String, dynamic> json) {
    return WalletEarningItemModel(
      paymentId: json['paymentId']?.toString() ?? '',
      classId: json['classId']?.toString(),
      classDate: json['classDate']?.toString(),
      studentName: json['studentName']?.toString(),
      sourceBucket: json['sourceBucket']?.toString() ?? 'card',
      sourceLabel: json['sourceLabel']?.toString() ?? 'Cartão',
      amount: _parseAmount(json['amount']),
      releaseStatus: json['releaseStatus']?.toString() ?? 'pending_release',
      releaseStatusLabel:
          json['releaseStatusLabel']?.toString() ?? 'Em liberação',
      capturedAt: json['capturedAt'] != null
          ? DateTime.tryParse(json['capturedAt'].toString())
          : null,
    );
  }
}

class WalletDashboardModel {
  final double availableForWithdrawal;
  final double pendingReleaseTotal;
  final List<WalletPendingReleaseItemModel> pendingReleaseItems;
  final double activeWithdrawalsTotal;
  final List<WalletActiveWithdrawalModel> activeWithdrawals;
  final List<WalletEarningItemModel> earningsHistory;

  const WalletDashboardModel({
    required this.availableForWithdrawal,
    required this.pendingReleaseTotal,
    required this.pendingReleaseItems,
    required this.activeWithdrawalsTotal,
    required this.activeWithdrawals,
    required this.earningsHistory,
  });

  factory WalletDashboardModel.fromJson(Map<String, dynamic> json) {
    List<T> mapList<T>(
      dynamic value,
      T Function(Map<String, dynamic>) mapper,
    ) {
      if (value is! List) return [];
      return value
          .map((e) => mapper(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return WalletDashboardModel(
      availableForWithdrawal: _parseAmount(json['availableForWithdrawal']),
      pendingReleaseTotal: _parseAmount(json['pendingReleaseTotal']),
      pendingReleaseItems: mapList(
        json['pendingReleaseItems'],
        WalletPendingReleaseItemModel.fromJson,
      ),
      activeWithdrawalsTotal: _parseAmount(json['activeWithdrawalsTotal']),
      activeWithdrawals: mapList(
        json['activeWithdrawals'],
        WalletActiveWithdrawalModel.fromJson,
      ),
      earningsHistory: mapList(
        json['earningsHistory'],
        WalletEarningItemModel.fromJson,
      ),
    );
  }
}

double _parseAmount(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
