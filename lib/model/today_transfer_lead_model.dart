class TodayTransferredData {
  final String executive;
  final String customerName;
  final int totalTransfered;
  final int totalRefixed;
  final int totalPostponed;
  final int totalCollected;

  TodayTransferredData({
    required this.executive,
    required this.customerName,
    required this.totalTransfered,
    required this.totalRefixed,
    required this.totalPostponed,
    required this.totalCollected,
  });

  factory TodayTransferredData.fromJson(Map<String, dynamic> json) {
    return TodayTransferredData(
      executive: json['executive'],
      customerName: json['customer_name'],
      totalTransfered: int.parse(json['totalTransfered'].toString()),
      totalRefixed: int.parse(json['totalRefixed'].toString()),
      totalPostponed: int.parse(json['totalPostponed'].toString()),
      totalCollected: int.parse(json['totalCollected'].toString()),
    );
  }
}

class TodayTransferredResponse {
  final bool success;
  final String message;
  final List<TodayTransferredData> data;

  TodayTransferredResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TodayTransferredResponse.fromJson(Map<String, dynamic> json) {
    return TodayTransferredResponse(
      success: json['success'] == 1,
      message: json['message'],
      data: (json['data'] as List)
          .map((item) => TodayTransferredData.fromJson(item))
          .toList(),
    );
  }
}
