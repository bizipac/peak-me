class ExotelResponse {
  final String success;

  ExotelResponse({required this.success});

  factory ExotelResponse.fromJson(Map<String, dynamic> json) {
    return ExotelResponse(
      success: json['success']?.toString() ?? '0',
    );
  }
}
