import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<String?> getSessionId(String authId) async {
    try {
      final response = await http.post(
        Uri.parse("https://fms.bizipac.com/secureapi/sapi/corebanking/validateBanId"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"auth_id": authId}),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> outer = jsonDecode(response.body);

        if (outer['status'] == 'success') {
          // Step 1: stringified JSON ko nikaalo
          final innerString = outer['data']?['data'];

          // Step 2: isko JSON me decode karo
          final innerJson = jsonDecode(innerString);

          // Step 3: session id extract karo
          final sessionId = innerJson['data'];

          print("✅ Extracted sessionId: $sessionId");
          return sessionId?.toString();
        } else {
          print("❌ API error: $outer");
          return null;
        }
      } else {
        print("Error: ${response.statusCode} => ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }
  }
}
