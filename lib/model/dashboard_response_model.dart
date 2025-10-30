// models/dashboard_counts.dart
class DashboardCounts {
  int totalPending;
  int totalCompleted;
  int totalMTD;

  DashboardCounts({
    required this.totalPending,
    required this.totalCompleted,
    required this.totalMTD,
  });

  factory DashboardCounts.fromJson(Map<String, dynamic> json) {
    return DashboardCounts(
      totalPending: json['totalPending'] ?? 0,
      totalCompleted: json['totalCompleted'] ?? 0,
      totalMTD: json['totalMTD'] ?? 0,
    );
  }
}

class DashboardResponse {
  DashboardCounts? data;
  int success;
  String message;

  DashboardResponse({this.data, required this.success, required this.message});

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      data: json['data'] != null
          ? DashboardCounts.fromJson(json['data'])
          : null,
      success: json['success'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}
