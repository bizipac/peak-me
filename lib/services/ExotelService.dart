import 'dart:convert';

import 'package:http/http.dart' as http;

class ExotelService {
  /// Get virtual number from PHP API
  static Future<String?> getVirtualNumber(String leadId) async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://fms.bizipac.com/apinew/ws_new/exotel_getnumber.php?lead_id=$leadId",
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["success"] != null && data["success"] != 0) {
          return data["success"].toString();
        }
      }
      return null;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }
}
