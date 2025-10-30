import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:peckme/model/complete_lead_model.dart';

class CompleteLeadServices {
  final String baseUrl =
      "https://fms.bizipac.com/apinew/ws_new/complete_lead.php?"; // change this

  Future<CompleteLeadModel> completeLead({
    required String loginId,
    required String leadId,
  }) async {
    final url = Uri.parse("$baseUrl");
    final response = await http.post(
      url,
      body: {"loginid": loginId, "leadid": leadId},
    );
    print("----------------");
    print(response.body);
    print("----------------");

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return CompleteLeadModel.fromJson(jsonBody);
    } else {
      throw Exception("Failed to connect to server: ${response.statusCode}");
    }
  }
}
