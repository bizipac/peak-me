import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/otp_model.dart';

class ForgotOtpPasswordService {
  static const String apiUrl =
      'https://fms.bizipac.com/apinew/ws_new/forgotPassword.php';

  static Future<OtpResponses> getOtp({
    required String mobile,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'mobile': mobile},
        headers: <String, String>{
          "Access-Control-Allow-Origin": "*",
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print("Success Response: $jsonData");
        return OtpResponses.fromJson(jsonData);
      } else {
        return OtpResponses(success: 0, message: 'Server Error');
      }
    } catch (e) {
      return OtpResponses(success: 0, message: 'Exception: $e');
    }
  }
}
