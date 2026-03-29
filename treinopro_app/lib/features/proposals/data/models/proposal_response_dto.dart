import 'package:json_annotation/json_annotation.dart';

part 'proposal_response_dto.g.dart';

@JsonSerializable()
class ProposalResponseDto {
  final String id;
  final String studentId;
  final StudentData student;
  final String locationName;
  final String locationAddress;
  final DateTime trainingDate;
  final String trainingTime;
  final int durationMinutes;
  final String modalityName;
  final double price;
  final String? additionalNotes;
  final String status;
  final String? paymentStatus;
  final bool? isRecontract;
  final String? targetPersonalId;
  final PaymentData? payment;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    this.isRecontract,
    this.targetPersonalId,
    this.payment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProposalResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ProposalResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProposalResponseDtoToJson(this);
}

@JsonSerializable()
class StudentData {
  final String id;
  final String name;
  final String email;
  final String firstName;
  final String lastName;
  final String? profilePicture;

  const StudentData({
    required this.id,
    required this.name,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
  });

  factory StudentData.fromJson(Map<String, dynamic> json) =>
      _$StudentDataFromJson(json);

  Map<String, dynamic> toJson() => _$StudentDataToJson(this);
}

@JsonSerializable()
class PaymentData {
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

  const PaymentData({
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

  factory PaymentData.fromJson(Map<String, dynamic> json) =>
      _$PaymentDataFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentDataToJson(this);
}
