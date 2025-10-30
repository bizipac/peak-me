import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/lead_detail_model.dart';

class LeadDetailsController {
  static Future<LeadResponse?> fetchLeadById(String leadId) async {
    print("-------------------------");
    print(leadId);
    print("---------------------------");
    final url = Uri.parse(
      "https://fms.bizipac.com/apinew/ws_new/new_lead_detail.php?lead_id=$leadId",
    );
    print(url);

    try {
      final response = await http.get(url);
      print('--------Lead details----------');
      // final ecryptedResponse = EncryptionHelper.encryptData(response.body);
      print('--------Encrypted Response---------');
      // print(ecryptedResponse);
      if (response.statusCode == 200) {
        // final decryptedResponse = EncryptionHelper.decryptData(ecryptedResponse);

        print('--------Decrypted Response---------');
        print(response.body);
        final jsonData = json.decode(response.body);

        return LeadResponse.fromJson(jsonData);
      } else {
        print("Server error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Fetch error: $e");
      return null;
    }
  }
}
