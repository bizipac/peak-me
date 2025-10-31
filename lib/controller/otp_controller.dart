import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/otp_res_model.dart';

class OtpService {
  static const String apiUrl =
      'https://fms.bizipac.com/apinew/ws_new/userverification.php?';

  static Future<OtpResponse> getOtp({
    required String mobile,
    required String upassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'mobile': mobile, 'password': upassword},
        headers: <String, String>{
          "Access-Control-Allow-Origin": "*", //specify the context type as Json
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        print("Suucess");
        return OtpResponse.fromJson(jsonData);
      } else {
        return OtpResponse(success: 0, message: 'Server Error');
      }
    } catch (e) {
      return OtpResponse(success: 0, message: 'Exception: $e');
    }
  }
}
