// reason_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/reason_item_model.dart';

class ReasonService {
  static Future<List<ReasonItem>> fetchReasons(String leadId) async {
    final url = Uri.parse(
      "https://fms.bizipac.com/apinew/ws_new/reason.php?leadid=$leadId",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      if (jsonResponse['success'] == 1) {
        ReasonResponse result = ReasonResponse.fromJson(jsonResponse);
        return result.data;
      } else {
        throw Exception("No reasons found");
      }
    } else {
      throw Exception("Failed to connect to API");
    }
  }
}
