import 'dart:convert';

import 'package:http/http.dart' as http;

import '../handler/EncryptionHandler.dart';
import '../model/new_lead_model.dart';

class LeadReceivedController {
  Future<List<Lead>> fetchLeads({
    required String uid,
    required int start,
    required int end,
    required String branchId,
    required String app_version,
    required String appType,
  }) async {
    final String apiUrl =
        'https://fms.bizipac.com/apinew/ws_new/new_lead.php?uid=$uid&start=$start&end=$end&branch_id=$branchId&app_version=$app_version&app_type=$appType';

    const String HASH_KEY = "QWRTEfnfdys635";

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      print("---------------Encrypt data--------------");
      print(response.body);
      final decoded = jsonDecode(response.body);
      if (decoded['success'] == 1) {
        List<dynamic> leads = decoded['data'];
        for (var lead in leads) {
          lead['customer_name'] = decryptFMS(lead['customer_name'], HASH_KEY);
          lead['mobile'] = decryptFMS(lead['mobile'], HASH_KEY);
          if (lead['res_address'] != '') {
            lead['res_address'] = decryptFMS(lead['res_address'], HASH_KEY);
          }

        }
        print("---------------decrypt data--------------");
        print(decoded['clientname']);
        print(leads.toString());
        return leads.map((lead) => Lead.fromJson(lead)).toList();
      } else {
        print("error ssg");
        throw Exception("No data found.");
      }
    } else {
      print("error");
      throw Exception("Failed to load leads");
    }
  }
}
