class SelfLeadResponse {
  final int success;
  final String message;
  final List<LeadDetail> data;

  SelfLeadResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SelfLeadResponse.fromJson(Map<String, dynamic> json) {
    return SelfLeadResponse(
      success: int.tryParse(json['success']?.toString() ?? '0') ?? 0,
      message: json['message']?.toString() ?? '',
      data: (json['data'] is List)
          ? (json['data'] as List).map((e) => LeadDetail.fromJson(e)).toList()
          : [],
    );
  }
}

class LeadDetail {
  final int leadId;
  final String customerName;
  final String mobile;
  final int statusId;
  final int clientId;
  final int branchId;
  final int lead_date;

  LeadDetail({
    required this.leadId,
    required this.customerName,
    required this.mobile,
    required this.statusId,
    required this.clientId,
    required this.branchId,
    required this.lead_date,
  });

  factory LeadDetail.fromJson(Map<String, dynamic> json) {
    return LeadDetail(
      leadId: int.tryParse(json['lead_id']?.toString() ?? '0') ?? 0,
      customerName: json['customer_name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      statusId: int.tryParse(json['status_id']?.toString() ?? '0') ?? 0,
      clientId: int.tryParse(json['client_id']?.toString() ?? '0') ?? 0,
      branchId: int.tryParse(json['branch_id']?.toString() ?? '0') ?? 0,
      lead_date: int.tryParse(json['lead_date']?.toString() ?? '0') ?? 0,
    );
  }
}
