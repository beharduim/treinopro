// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proposal_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProposalResponseDto _$ProposalResponseDtoFromJson(Map<String, dynamic> json) =>
    ProposalResponseDto(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      student: StudentData.fromJson(json['student'] as Map<String, dynamic>),
      locationName: json['locationName'] as String,
      locationAddress: json['locationAddress'] as String,
      trainingDate: DateTime.parse(json['trainingDate'] as String),
      trainingTime: json['trainingTime'] as String,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      modalityName: json['modalityName'] as String,
      price: (json['price'] as num).toDouble(),
      additionalNotes: json['additionalNotes'] as String?,
      status: json['status'] as String,
      paymentStatus: json['paymentStatus'] as String?,
      isRecontract: json['isRecontract'] as bool?,
      targetPersonalId: json['targetPersonalId'] as String?,
      payment: json['payment'] == null
          ? null
          : PaymentData.fromJson(json['payment'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ProposalResponseDtoToJson(
  ProposalResponseDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'studentId': instance.studentId,
  'student': instance.student,
  'locationName': instance.locationName,
  'locationAddress': instance.locationAddress,
  'trainingDate': instance.trainingDate.toIso8601String(),
  'trainingTime': instance.trainingTime,
  'durationMinutes': instance.durationMinutes,
  'modalityName': instance.modalityName,
  'price': instance.price,
  'additionalNotes': instance.additionalNotes,
  'status': instance.status,
  'paymentStatus': instance.paymentStatus,
  'isRecontract': instance.isRecontract,
  'targetPersonalId': instance.targetPersonalId,
  'payment': instance.payment,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

StudentData _$StudentDataFromJson(Map<String, dynamic> json) => StudentData(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  profilePicture: json['profilePicture'] as String?,
);

Map<String, dynamic> _$StudentDataToJson(StudentData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'profilePicture': instance.profilePicture,
    };

PaymentData _$PaymentDataFromJson(Map<String, dynamic> json) => PaymentData(
  paymentId: json['paymentId'] as String,
  status: json['status'] as String,
  method: json['method'] as String,
  amount: (json['amount'] as num).toDouble(),
  preferenceId: json['preferenceId'] as String?,
  checkoutUrl: json['checkoutUrl'] as String?,
  sandboxCheckoutUrl: json['sandboxCheckoutUrl'] as String?,
  qrCode: json['qrCode'] as String?,
  qrCodeBase64: json['qrCodeBase64'] as String?,
  qrCodeImageUrl: json['qrCodeImageUrl'] as String?,
  qrCodeSvgUrl: json['qrCodeSvgUrl'] as String?,
  hostedInstructionsUrl: json['hostedInstructionsUrl'] as String?,
  provider: json['provider'] as String?,
  stripePaymentIntentId: json['stripePaymentIntentId'] as String?,
  clientSecret: json['clientSecret'] as String?,
  customerId: json['customerId'] as String?,
  customerEphemeralKeySecret: json['customerEphemeralKeySecret'] as String?,
  publishableKey: json['publishableKey'] as String?,
  processingModel: json['processingModel'] as String?,
  platformFee: (json['platformFee'] as num?)?.toDouble(),
  personalAmount: (json['personalAmount'] as num?)?.toDouble(),
  message: json['message'] as String?,
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$PaymentDataToJson(PaymentData instance) =>
    <String, dynamic>{
      'paymentId': instance.paymentId,
      'status': instance.status,
      'method': instance.method,
      'amount': instance.amount,
      'preferenceId': instance.preferenceId,
      'checkoutUrl': instance.checkoutUrl,
      'sandboxCheckoutUrl': instance.sandboxCheckoutUrl,
      'qrCode': instance.qrCode,
      'qrCodeBase64': instance.qrCodeBase64,
      'qrCodeImageUrl': instance.qrCodeImageUrl,
      'qrCodeSvgUrl': instance.qrCodeSvgUrl,
      'hostedInstructionsUrl': instance.hostedInstructionsUrl,
      'provider': instance.provider,
      'stripePaymentIntentId': instance.stripePaymentIntentId,
      'clientSecret': instance.clientSecret,
      'customerId': instance.customerId,
      'customerEphemeralKeySecret': instance.customerEphemeralKeySecret,
      'publishableKey': instance.publishableKey,
      'processingModel': instance.processingModel,
      'platformFee': instance.platformFee,
      'personalAmount': instance.personalAmount,
      'message': instance.message,
      'expiresAt': instance.expiresAt?.toIso8601String(),
    };
