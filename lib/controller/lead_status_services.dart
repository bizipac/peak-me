import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/lead_status_model.dart';


class LeadService {
  final String baseUrl;

  LeadService({required this.baseUrl});

  Future<LeadStatusResponse> fetchLeads(String uid, String branchId) async {
    final url = Uri.parse(
        '$baseUrl/today_completed_lead.php?uid=$uid&branch_id=$branchId');

    final response = await http.get(url);
    print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LeadStatusResponse.fromJson(data);
    } else {
      throw Exception("Failed to load leads");
    }
  }
}
