class RefixLeadResponse {
  final int success;
  final String message;

  RefixLeadResponse({
    required this.success,
    required this.message,
  });

  factory RefixLeadResponse.fromJson(Map<String, dynamic> json) {
    return RefixLeadResponse(
      success: json['success'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}
