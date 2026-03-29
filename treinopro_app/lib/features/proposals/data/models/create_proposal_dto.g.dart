// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_proposal_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateProposalDto _$CreateProposalDtoFromJson(Map<String, dynamic> json) =>
    CreateProposalDto(
      locationId: json['locationId'] as String?,
      locationName: json['locationName'] as String,
      locationAddress: json['locationAddress'] as String,
      locationLat: (json['locationLat'] as num?)?.toDouble(),
      locationLng: (json['locationLng'] as num?)?.toDouble(),
      trainingDate: json['trainingDate'] as String,
      trainingTime: json['trainingTime'] as String,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      modalityId: json['modalityId'] as String?,
      modalityName: json['modalityName'] as String,
      price: (json['price'] as num).toDouble(),
      additionalNotes: json['additionalNotes'] as String?,
      paymentMethod: json['paymentMethod'] as String,
      cardId: json['cardId'] as String?,
      cardData: json['cardData'] == null
          ? null
          : CardData.fromJson(json['cardData'] as Map<String, dynamic>),
      installments: json['installments'] as String?,
      saveCard: json['saveCard'] as bool?,
      cardNickname: json['cardNickname'] as String?,
      payerEmail: json['payerEmail'] as String?,
      payerCpf: json['payerCpf'] as String?,
    );

Map<String, dynamic> _$CreateProposalDtoToJson(CreateProposalDto instance) =>
    <String, dynamic>{
      'locationId': instance.locationId,
      'locationName': instance.locationName,
      'locationAddress': instance.locationAddress,
      'locationLat': instance.locationLat,
      'locationLng': instance.locationLng,
      'trainingDate': instance.trainingDate,
      'trainingTime': instance.trainingTime,
      'durationMinutes': instance.durationMinutes,
      'modalityId': instance.modalityId,
      'modalityName': instance.modalityName,
      'price': instance.price,
      'additionalNotes': instance.additionalNotes,
      'paymentMethod': instance.paymentMethod,
      'cardId': instance.cardId,
      'cardData': instance.cardData,
      'installments': instance.installments,
      'saveCard': instance.saveCard,
      'cardNickname': instance.cardNickname,
      'payerEmail': instance.payerEmail,
      'payerCpf': instance.payerCpf,
    };

CardData _$CardDataFromJson(Map<String, dynamic> json) => CardData(
  cardNumber: json['cardNumber'] as String,
  cardHolderName: json['cardHolderName'] as String,
  expirationDate: json['expirationDate'] as String,
  cvv: json['cvv'] as String,
  cardType: json['cardType'] as String,
);

Map<String, dynamic> _$CardDataToJson(CardData instance) => <String, dynamic>{
  'cardNumber': instance.cardNumber,
  'cardHolderName': instance.cardHolderName,
  'expirationDate': instance.expirationDate,
  'cvv': instance.cvv,
  'cardType': instance.cardType,
};
