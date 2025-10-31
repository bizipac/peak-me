import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> updateAuthId(String userId, {Function(String)? onUpdated}) async {
  final prefs = await SharedPreferences.getInstance();

  try {
    final uri = Uri.parse(
      "https://fms.bizipac.com/apinew/ws_new/get_auth_id_by_user_id.php?userid=$userId",
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == 1 &&
          data['data'] != null &&
          data['data'].isNotEmpty) {
        final newAuthId = data['data'][0]['auth_id'] ?? '';

        // 1️⃣ Update SharedPreferences
        await prefs.setString('authId', newAuthId);

        // 2️⃣ Update local state via callback
        if (onUpdated != null) {
          onUpdated(newAuthId);
        }

        print("Auth ID updated: $newAuthId");
      } else {
        print("Auth ID not found in response");
      }
    } else {
      print("API call failed with status: ${response.statusCode}");
    }
  } catch (e) {
    print("Error fetching auth_id: $e");
  }
}
