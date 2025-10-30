import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../model/user_model.dart';
import '../view/auth/login.dart';

class UpdateAuthService {
  static const String apiUrl = 'https://fms.bizipac.com/apinew/ws_new/userForgotPassword.php?';

  static Future<Map<String, dynamic>> login({
    required String mobile,
    required String newPassword,
    required String otp,
    context,
  }) async {
    print("Mobile : $mobile");
    print("newPassword : $newPassword");
    print("otp : $otp");
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'mobile': mobile,
          'new_password': newPassword,
          'otp': otp,
        },
      );

      print('Response body ------------------------');
      print(response.body);
      print('Response body ------------------------');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == 1 && data['data'] != null) {
          final user = UserModel.fromJson(data['data'][0]);
          return {
            'success': true,
            'user': user,
            'message': data['message'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Invalid response',
          };
        }
      } else {
        return {'success': false, 'message': 'Server error'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
