import 'package:json_annotation/json_annotation.dart';

part 'create_proposal_dto.g.dart';

@JsonSerializable()
class CreateProposalDto {
  final String? locationId;
  final String locationName;
  final String locationAddress;
  final double? locationLat;
  final double? locationLng;
  final String trainingDate;
  final String trainingTime;
  final int durationMinutes;
  final String? modalityId;
  final String modalityName;
  final double price;
  final String? additionalNotes;
  final String paymentMethod;
  final String? cardId;
  final String? savedCardCvv;
  final CardData? cardData;
  final String? installments;
  final bool? saveCard;
  final String? cardNickname;
  // Dados do pagador
  final String? payerEmail;
  final String? payerCpf;

  const CreateProposalDto({
    this.locationId,
    required this.locationName,
    required this.locationAddress,
    this.locationLat,
    this.locationLng,
    required this.trainingDate,
    required this.trainingTime,
    required this.durationMinutes,
    this.modalityId,
    required this.modalityName,
    required this.price,
    this.additionalNotes,
    required this.paymentMethod,
    this.cardId,
    this.savedCardCvv,
    this.cardData,
    this.installments,
    this.saveCard,
    this.cardNickname,
    this.payerEmail,
    this.payerCpf,
  });

  factory CreateProposalDto.fromJson(Map<String, dynamic> json) =>
      _$CreateProposalDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateProposalDtoToJson(this);
}

@JsonSerializable()
class CardData {
  final String cardNumber;
  final String cardHolderName;
  final String expirationDate;
  final String cvv;
  final String cardType;

  const CardData({
    required this.cardNumber,
    required this.cardHolderName,
    required this.expirationDate,
    required this.cvv,
    required this.cardType,
  });

  factory CardData.fromJson(Map<String, dynamic> json) =>
      _$CardDataFromJson(json);

  Map<String, dynamic> toJson() => _$CardDataToJson(this);
}
