class SendVerificationCodeResponse {
  final String message;
  final DateTime expiresAt;

  SendVerificationCodeResponse({
    required this.message,
    required this.expiresAt,
  });

  factory SendVerificationCodeResponse.fromJson(Map<String, dynamic> json) {
    return SendVerificationCodeResponse(
      message: json['message'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}

class VerifyCodeResponse {
  final String message;
  final bool verified;

  VerifyCodeResponse({
    required this.message,
    required this.verified,
  });

  factory VerifyCodeResponse.fromJson(Map<String, dynamic> json) {
    return VerifyCodeResponse(
      message: json['message'] as String,
      verified: json['verified'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'verified': verified,
    };
  }
}
