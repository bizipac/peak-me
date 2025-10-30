import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:peckme/model/new_lead_model.dart';

class LeadService {
  static const String baseUrl =
      "https://fms.bizipac.com/apinew/ws_new/search_lead.php"; // updated PHP file

  static Future<List<Lead>> searchLead(String type, String value) async {
    final url = Uri.parse("$baseUrl?$type=$value");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["success"] == 1 && data["data"].isNotEmpty) {
        return (data["data"] as List)
            .map((json) => Lead.fromJson(json))
            .toList();
      }
    }
    return [];
  }
}

