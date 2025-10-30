class PostponeLeadResponse {
  final int success;
  final String message;

  PostponeLeadResponse({
    required this.success,
    required this.message,
  });

  factory PostponeLeadResponse.fromJson(Map<String, dynamic> json) {
    return PostponeLeadResponse(
      success: json['success'],
      message: json['message'],
    );
  }
}
