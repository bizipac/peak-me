import 'dart:convert';

import 'package:http/http.dart' as http;

class VersionService {
  static const String baseUrl =
      "https://fms.bizipac.com/apinew/ws_new"; // replace with your URL

  static Future<String?> fetchLatestVersion() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/getAppVersion.php"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == 1 && data["data"] != null) {
          return data["data"]["app_version"] as String?;
        } else {
          print("API returned no data: ${data["message"]}");
        }
      } else {
        print("HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching version: $e");
    }
    return null;
  }
}
