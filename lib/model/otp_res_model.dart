class OtpResponse {
  final int success;
  final String message;

  OtpResponse({required this.success, required this.message});

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      success: json['success'] ?? 0,
      message: json['message'].toString(),
    );
  }
}
