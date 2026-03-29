class PersonalFinancialStatsModel {
  final double availableBalance;
  final double pendingBalance;
  final double totalEarned;
  final double totalWithdrawn;
  final MonthlyStats thisMonth;
  final List<WithdrawalHistory> recentWithdrawals;
  final ProfileStatus profileStatus;

  PersonalFinancialStatsModel({
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.thisMonth,
    required this.recentWithdrawals,
    required this.profileStatus,
  });

  factory PersonalFinancialStatsModel.fromJson(Map<String, dynamic> json) {
    // A API retorna os dados dentro de 'wallet' e campos diretos
    final wallet = json['wallet'] as Map<String, dynamic>? ?? {};
    
    return PersonalFinancialStatsModel(
      availableBalance: _parseDouble(wallet['availableBalance']) ?? 0.0,
      pendingBalance: _parseDouble(wallet['pendingBalance']) ?? 0.0,
      totalEarned: _parseDouble(json['totalEarnings']) ?? _parseDouble(wallet['totalEarned']) ?? 0.0,
      totalWithdrawn: _parseDouble(json['totalWithdrawals']) ?? _parseDouble(wallet['totalWithdrawn']) ?? 0.0,
      thisMonth: MonthlyStats.fromJson(json['thisMonth'] ?? {}),
      recentWithdrawals: (json['recentWithdrawals'] as List<dynamic>?)
          ?.map((item) => WithdrawalHistory.fromJson(item))
          .toList() ?? [],
      profileStatus: ProfileStatus.fromJson(json['profileStatus'] ?? {}),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'availableBalance': availableBalance,
      'pendingBalance': pendingBalance,
      'totalEarned': totalEarned,
      'totalWithdrawn': totalWithdrawn,
      'thisMonth': thisMonth.toJson(),
      'recentWithdrawals': recentWithdrawals.map((item) => item.toJson()).toList(),
      'profileStatus': profileStatus.toJson(),
    };
  }
}

class MonthlyStats {
  final double earned;
  final double withdrawn;
  final int classesCompleted;
  final double averagePerClass;

  MonthlyStats({
    required this.earned,
    required this.withdrawn,
    required this.classesCompleted,
    required this.averagePerClass,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      earned: PersonalFinancialStatsModel._parseDouble(json['earned']) ?? 0.0,
      withdrawn: PersonalFinancialStatsModel._parseDouble(json['withdrawn']) ?? 0.0,
      classesCompleted: json['classesCompleted'] ?? 0,
      averagePerClass: PersonalFinancialStatsModel._parseDouble(json['averagePerClass']) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'earned': earned,
      'withdrawn': withdrawn,
      'classesCompleted': classesCompleted,
      'averagePerClass': averagePerClass,
    };
  }
}

class WithdrawalHistory {
  final String id;
  final double amount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  WithdrawalHistory({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WithdrawalHistory.fromJson(Map<String, dynamic> json) {
    return WithdrawalHistory(
      id: json['id'] ?? '',
      amount: PersonalFinancialStatsModel._parseDouble(json['amount']) ?? 0.0,
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ProfileStatus {
  final bool isComplete;
  final bool canReceivePayments;
  final List<String> missingFields;
  final String verificationStatus;

  ProfileStatus({
    required this.isComplete,
    required this.canReceivePayments,
    required this.missingFields,
    required this.verificationStatus,
  });

  factory ProfileStatus.fromJson(Map<String, dynamic> json) {
    return ProfileStatus(
      isComplete: json['isComplete'] ?? false,
      canReceivePayments: json['canReceivePayments'] ?? false,
      missingFields: (json['missingFields'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ?? [],
      verificationStatus: json['verificationStatus'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isComplete': isComplete,
      'canReceivePayments': canReceivePayments,
      'missingFields': missingFields,
      'verificationStatus': verificationStatus,
    };
  }
}
