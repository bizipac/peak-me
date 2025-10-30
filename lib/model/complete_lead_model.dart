class CompleteLeadModel {
  final int success;
  final String message;
  final int? responseId;

  CompleteLeadModel({
    required this.success,
    required this.message,
    this.responseId,
  });

  factory CompleteLeadModel.fromJson(Map<String, dynamic> json) {
    return CompleteLeadModel(
      success: json['success'] ?? 0,
      message: json['message'] ?? '',
      responseId: json['response_id'] != null
          ? int.tryParse(json['response_id'].toString())
          : null,
    );
  }
}
