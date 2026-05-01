class PayoutMethodsModel {
  final BankAccountModel? bankAccount;

  PayoutMethodsModel({this.bankAccount});

  factory PayoutMethodsModel.fromJson(Map<String, dynamic> json) {
    return PayoutMethodsModel(
      bankAccount: json['bankAccount'] != null
          ? BankAccountModel.fromJson(json['bankAccount'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'bankAccount': bankAccount?.toJson()};
  }
}

class BankAccountModel {
  final String id;
  final String bankName;
  final String agency;
  final String account;
  final String holderName;
  final String document;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  BankAccountModel({
    required this.id,
    required this.bankName,
    required this.agency,
    required this.account,
    required this.holderName,
    required this.document,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id'] ?? '',
      bankName: json['bankName'] ?? json['bank'] ?? '',
      agency: json['agency'] ?? '',
      account: json['accountNumber'] ?? json['account'] ?? '',
      holderName: json['accountHolderName'] ?? json['holderName'] ?? '',
      document: json['document'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bankName': bankName,
      'agency': agency,
      'account': account,
      'holderName': holderName,
      'document': document,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get maskedAccount {
    if (account.length <= 4) return account;
    return '****${account.substring(account.length - 4)}';
  }

  String get maskedDocument {
    if (document.length <= 4) return document;
    return '***.***.***-${document.substring(document.length - 2)}';
  }
}
