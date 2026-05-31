class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type;
  final String status;
  final String description;
  final DateTime createdAt;
  final DateTime? processedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.status,
    required this.description,
    required this.createdAt,
    this.processedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      processedAt: json['processedAt'] != null 
          ? DateTime.parse(json['processedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'status': status,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }
}

class PaymentModel {
  final String id;
  final String classId;
  final String studentId;
  final String personalId;
  final double totalAmount;
  final double platformFee;
  final double personalAmount;
  final String status;
  final String type;
  final DateTime createdAt;
  final DateTime? capturedAt;
  final Map<String, dynamic>? student;
  final Map<String, dynamic>? personal;

  PaymentModel({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.personalId,
    required this.totalAmount,
    required this.platformFee,
    required this.personalAmount,
    required this.status,
    required this.type,
    required this.createdAt,
    this.capturedAt,
    this.student,
    this.personal,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      classId: json['classId'] ?? '',
      studentId: json['studentId'] ?? '',
      personalId: json['personalId'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      platformFee: (json['platformFee'] ?? 0.0).toDouble(),
      personalAmount: (json['personalAmount'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      capturedAt: json['capturedAt'] != null 
          ? DateTime.parse(json['capturedAt']) 
          : null,
      student: json['student'],
      personal: json['personal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'studentId': studentId,
      'personalId': personalId,
      'totalAmount': totalAmount,
      'platformFee': platformFee,
      'personalAmount': personalAmount,
      'status': status,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'capturedAt': capturedAt?.toIso8601String(),
      'student': student,
      'personal': personal,
    };
  }
}

class WalletBalanceModel {
  final String id;
  final String userId;
  final double availableBalance;
  final double pendingBalance;
  final double pendingWithdrawalAmount;
  final bool hasOpenWithdrawal;
  final double totalEarned;
  final double totalWithdrawn;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletBalanceModel({
    required this.id,
    required this.userId,
    required this.availableBalance,
    required this.pendingBalance,
    this.pendingWithdrawalAmount = 0,
    this.hasOpenWithdrawal = false,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    final pendingWithdrawalAmount =
        (json['pendingWithdrawalAmount'] ?? 0.0).toDouble();
    return WalletBalanceModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      availableBalance: (json['availableBalance'] ?? 0.0).toDouble(),
      pendingBalance: (json['pendingBalance'] ?? 0.0).toDouble(),
      pendingWithdrawalAmount: pendingWithdrawalAmount,
      hasOpenWithdrawal: json['hasOpenWithdrawal'] == true ||
          pendingWithdrawalAmount > 0,
      totalEarned: (json['totalEarned'] ?? 0.0).toDouble(),
      totalWithdrawn: (json['totalWithdrawn'] ?? 0.0).toDouble(),
      isActive: _parseBool(json['isActive']),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'availableBalance': availableBalance,
      'pendingBalance': pendingBalance,
      'totalEarned': totalEarned,
      'totalWithdrawn': totalWithdrawn,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
