import 'package:equatable/equatable.dart';

/// Enum para status das propostas
enum ProposalStatus {
  pending,
  matched,
  completed,
  cancelled,
}

/// DTO de resposta da API para propostas
class ProposalResponseDto extends Equatable {
  final String id;
  final String studentId;
  final StudentInfo student;
  final String locationName;
  final String locationAddress;
  final DateTime trainingDate;
  final String trainingTime;
  final int durationMinutes;
  final String modalityName;
  final double price;
  final String? additionalNotes;
  final ProposalStatus status;
  final String? paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PaymentInfo? payment;

  const ProposalResponseDto({
    required this.id,
    required this.studentId,
    required this.student,
    required this.locationName,
    required this.locationAddress,
    required this.trainingDate,
    required this.trainingTime,
    required this.durationMinutes,
    required this.modalityName,
    required this.price,
    this.additionalNotes,
    required this.status,
    this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
    this.payment,
  });

  factory ProposalResponseDto.fromJson(Map<String, dynamic> json) {
    return ProposalResponseDto(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      student: StudentInfo.fromJson(json['student'] as Map<String, dynamic>),
      locationName: json['locationName'] as String,
      locationAddress: json['locationAddress'] as String,
      trainingDate: DateTime.parse(json['trainingDate'] as String),
      trainingTime: json['trainingTime'] as String,
      durationMinutes: json['durationMinutes'] as int,
      modalityName: json['modalityName'] as String,
      price: (json['price'] as num).toDouble(),
      additionalNotes: json['additionalNotes'] as String?,
      status: _parseProposalStatus(json['status'] as String),
      paymentStatus: json['paymentStatus'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      payment: json['payment'] != null ? PaymentInfo.fromJson(json['payment'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'student': student.toJson(),
      'locationName': locationName,
      'locationAddress': locationAddress,
      'trainingDate': trainingDate.toIso8601String(),
      'trainingTime': trainingTime,
      'durationMinutes': durationMinutes,
      'modalityName': modalityName,
      'price': price,
      'additionalNotes': additionalNotes,
      'status': status.name,
      'paymentStatus': paymentStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'payment': payment?.toJson(),
    };
  }

  static ProposalStatus _parseProposalStatus(String status) {
    switch (status) {
      case 'pending':
        return ProposalStatus.pending;
      case 'matched':
        return ProposalStatus.matched;
      case 'completed':
        return ProposalStatus.completed;
      case 'cancelled':
        return ProposalStatus.cancelled;
      default:
        return ProposalStatus.pending;
    }
  }

  @override
  List<Object?> get props => [
        id,
        studentId,
        student,
        locationName,
        locationAddress,
        trainingDate,
        trainingTime,
        durationMinutes,
        modalityName,
        price,
        additionalNotes,
        status,
        paymentStatus,
        createdAt,
        updatedAt,
        payment,
      ];
}

/// Informações do aluno
class StudentInfo extends Equatable {
  final String id;
  final String name;
  final String email;
  final String firstName;
  final String lastName;

  const StudentInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
    };
  }

  @override
  List<Object?> get props => [id, name, email, firstName, lastName];
}

/// Informações de pagamento
class PaymentInfo extends Equatable {
  final String paymentId;
  final String status;
  final String method;
  final double amount;
  final String? preferenceId;
  final String? checkoutUrl;
  final String? sandboxCheckoutUrl;
  final String? qrCode;
  final String? qrCodeBase64;
  final double? platformFee;
  final double? personalAmount;
  final String? message;
  final DateTime? expiresAt;

  const PaymentInfo({
    required this.paymentId,
    required this.status,
    required this.method,
    required this.amount,
    this.preferenceId,
    this.checkoutUrl,
    this.sandboxCheckoutUrl,
    this.qrCode,
    this.qrCodeBase64,
    this.platformFee,
    this.personalAmount,
    this.message,
    this.expiresAt,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      paymentId: json['paymentId'] as String,
      status: json['status'] as String,
      method: json['method'] as String,
      amount: (json['amount'] as num).toDouble(),
      preferenceId: json['preferenceId'] as String?,
      checkoutUrl: json['checkoutUrl'] as String?,
      sandboxCheckoutUrl: json['sandboxCheckoutUrl'] as String?,
      qrCode: json['qrCode'] as String?,
      qrCodeBase64: json['qrCodeBase64'] as String?,
      platformFee: json['platformFee'] != null ? (json['platformFee'] as num).toDouble() : null,
      personalAmount: json['personalAmount'] != null ? (json['personalAmount'] as num).toDouble() : null,
      message: json['message'] as String?,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'status': status,
      'method': method,
      'amount': amount,
      'preferenceId': preferenceId,
      'checkoutUrl': checkoutUrl,
      'sandboxCheckoutUrl': sandboxCheckoutUrl,
      'qrCode': qrCode,
      'qrCodeBase64': qrCodeBase64,
      'platformFee': platformFee,
      'personalAmount': personalAmount,
      'message': message,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        paymentId,
        status,
        method,
        amount,
        preferenceId,
        checkoutUrl,
        sandboxCheckoutUrl,
        qrCode,
        qrCodeBase64,
        platformFee,
        personalAmount,
        message,
        expiresAt,
      ];
}
