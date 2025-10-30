// model_reason.dart

class ReasonItem {
  final String reason;
  final String crType;
  final String crStatus;

  ReasonItem({
    required this.reason,
    required this.crType,
    required this.crStatus,
  });

  factory ReasonItem.fromJson(Map<String, dynamic> json) {
    return ReasonItem(
      reason: json['reason'] ?? '',
      crType: json['cr_type'] ?? '',
      crStatus: json['cr_status'] ?? '',
    );
  }
}

class ReasonResponse {
  final int success;
  final String message;
  final List<ReasonItem> data;

  ReasonResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ReasonResponse.fromJson(Map<String, dynamic> json) {
    return ReasonResponse(
      success: json['success'],
      message: json['message'],
      data: (json['data'] as List)
          .map((item) => ReasonItem.fromJson(item))
          .toList(),
    );
  }
}
