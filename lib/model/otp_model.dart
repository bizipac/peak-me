class OtpResponses {
  final int success;
  final String message;
  final String? otp; // test ke liye

  OtpResponses({
    required this.success,
    required this.message,
    this.otp,
  });

  factory OtpResponses.fromJson(Map<String, dynamic> json) {
    return OtpResponses(
      success: json['success'] ?? 0,
      message: json['message'] ?? '',
      otp: json['otp']?.toString(),
    );
  }
}
