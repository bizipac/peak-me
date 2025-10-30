import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/self_lead_model.dart';

class SelfLeadAlloterService {
  final String baseUrl = "https://fms.bizipac.com/apinew/ws_new";

  /// Step 1: Check lead status
  Future<SelfLeadResponse?> checkLead(
    String mobile,
    String branchId,
    String uid,
  ) async {
    final response = await http.get(
      Uri.parse(
        'https://fms.bizipac.com/apinew/ws_new/check_self_leads_status.php?mobile=$mobile&branch_id=$branchId&uid=$uid',
      ),
    );
    print("----------------");
    print(response.body);
    print("================");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("==============");
      print(data);
      print("---------------");
      return SelfLeadResponse.fromJson(data);
    }
    return null;
  }

  /// Step 2: Assign lead (accept button)
  Future<bool> assignLead(String mobile, String uid, String branchId) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/self_lead_asign.php?mobile=$mobile&uid=$uid&branch_id=$branchId',
      ),
    );
    print("------------");
    print(response.body);
    print("=============");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == 1;
    }
    return false;
  }
}
