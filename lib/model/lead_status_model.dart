class Lead {
  final String leadId;
  final String customerName;
  final String mobile;
  final String location;
  final String leadDate;
  final String apptime;
  final String pincode;
  final String clientId;
  final String amzAppId;
  final String status;

  Lead({
    required this.leadId,
    required this.customerName,
    required this.mobile,
    required this.location,
    required this.leadDate,
    required this.apptime,
    required this.pincode,
    required this.clientId,
    required this.amzAppId,
    required this.status,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      leadId: json['lead_id']?.toString() ?? '',
      customerName: json['customer_name'] ?? '',
      mobile: json['mobile'] ?? '',
      location: json['location'] ?? '',
      leadDate: json['lead_date'] ?? '',
      apptime: json['apptime'] ?? '',
      pincode: json['pincode']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      amzAppId: json['AMZAppId']?.toString() ?? '',
      status: json['status'] ?? 'Pending',
    );
  }
}

class LeadStatusResponse {
  final List<Lead> data;
  final int total;
  final int completedTotal;
  final int pendingTotal;
  final int success;
  final String message;

  LeadStatusResponse({
    required this.data,
    required this.total,
    required this.completedTotal,
    required this.pendingTotal,
    required this.success,
    required this.message,
  });

  factory LeadStatusResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    List<Lead> leads = list.map((e) => Lead.fromJson(e)).toList();

    return LeadStatusResponse(
      data: leads,
      total: _toInt(json['total']),
      completedTotal: _toInt(json['completed_total']),
      pendingTotal: _toInt(json['pending_total']),
      success: _toInt(json['success']),
      message: json['message'] ?? '',
    );
  }

  // helper to safely convert dynamic → int
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
