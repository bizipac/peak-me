import 'dart:convert';

import 'package:http/http.dart' as http;

import '../handler/EncryptionHandler.dart';
import '../model/new_lead_model.dart';

class ReceivedLeadController {
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
      print("---------------Encrypted data--------------");
      print(response.body);

      final decoded = jsonDecode(response.body);

      if (decoded['success'] == 1) {
        List<dynamic> leads = decoded['data'];

        for (var lead in leads) {
          // Decrypt fields
          lead['customer_name'] = decryptFMS(lead['customer_name'], HASH_KEY);
          lead['mobile'] = decryptFMS(lead['mobile'], HASH_KEY);
          var resAddress = lead['res_address'];
          if (resAddress != null && resAddress.toString().trim().isNotEmpty) {
            // Handle multi-part encrypted address
            lead['res_address'] = decryptFMS(resAddress, HASH_KEY);
          }
          var offAddress = lead['off_address'];
          if (offAddress != null && offAddress.toString().trim().isNotEmpty) {
            // Handle multi-part encrypted address
            lead['off_address'] = decryptFMS(offAddress, HASH_KEY);
          }
          var offName = lead['off_name'];
          if (offName != null && offName.toString().trim().isNotEmpty) {
            // Handle multi-part encrypted address
            lead['off_name'] = decryptFMS(offName, HASH_KEY);
          }
        }

        print("---------------Decrypted data--------------");
        print(leads.toString());

        return leads.map((lead) => Lead.fromJson(lead)).toList();
      } else {
        throw Exception("No data found.");
      }
    } else {
      throw Exception("Failed to load leads");
    }
  }
}
