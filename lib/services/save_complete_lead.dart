import 'dart:convert';
import 'package:http/http.dart' as http;

class LeadApiResponse {
  final int success;
  final String message;
  final int? responseId;
  final String? docUrl;

  LeadApiResponse({required this.success, required this.message, this.responseId, this.docUrl});

  factory LeadApiResponse.fromJson(Map<String, dynamic> json) {
    return LeadApiResponse(
      success: json['success'] is bool ? ((json['success'] as bool) ? 1 : 0) : (json['success'] ?? 0),
      message: json['message'] ?? '',
      responseId: json['response_id'] != null ? int.tryParse(json['response_id'].toString()) : null,
      docUrl: json['doc_url']?.toString(),
    );
  }
}

Future<LeadApiResponse> saveCompletedLeadUrl({
  required Uri endpoint,             // e.g. Uri.parse("https://www.bizipac.com/ws/addCompletedLeadUrl.php")
  required String loginid,           // "1019"
  required String leadid,            // "41983"
  required String doc_name,           // "Photo" ya "Pancard" ya "ITR Computation of Income"
  required String address,           // "kalawad road"
  required String geoLocation,          // "22.3039,70.8022" ya "kalawad road"
  required String doc_url,            // S3 PDF URL
  int doclist = 1,
}) async {
  final body = {
    'loginid': loginid,
    'leadid': leadid,
    'doc_name': doc_name,
    'address': address,
    'geoLocation': geoLocation,
    'doc_url': doc_url,
    'doclist': '$doclist',
  };

  final resp = await http.post(
    endpoint,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: body,
  );

  if (resp.statusCode == 200) {
    final Map<String, dynamic> jsonMap = json.decode(resp.body);
    return LeadApiResponse.fromJson(jsonMap);
  } else {
    return LeadApiResponse(success: 0, message: 'HTTP ${resp.statusCode}: ${resp.reasonPhrase}');
  }
}
