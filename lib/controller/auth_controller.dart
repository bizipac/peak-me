import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/user_model.dart';
import '../view/dashboard_screen.dart';

class AuthService {
  static const String apiUrl =
      'https://fms.bizipac.com/apinew/ws_new/userauth.php?';

  static Future<Map<String, dynamic>> login({
    required String mobile,
    required String password,
    required String userToken,
    required String teamho,
    required String imeiNumber,
    required context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'mobile': mobile,
          'password': password,
          'user_token': userToken,
          'teamho': teamho,
          'imei_number': imeiNumber,
        },
      );
      print('response the body ------------------------');
      print(response.body);
      print('response the body ------------------------');
      if (response.statusCode == 200) {
        //final data = json.decode(response.body);
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == 1 && data['data'] != null) {
          final FirebaseFirestore firestore = FirebaseFirestore.instance;

          final user = UserModel.fromJson(data['data'][0]);
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('uid', user.uid);
          await prefs.setString('name', user.name);
          await prefs.setString('userToken', userToken);
          await prefs.setString('mobile', user.mobile);
          await prefs.setString('rolename', user.rolename);
          await prefs.setString('company_name', user.imagePoliceVerification);
          await prefs.setString('roleId', user.roleId);
          await prefs.setString('branchId', user.branchId);
          await prefs.setString('branch_name', user.branch_name);
          await prefs.setString('authId', user.authId);
          await prefs.setString('image', user.image);
          await prefs.setString('address', user.address);

          //firebase store value
          var docRef = firestore
              .collection("users")
              .doc(mobile); // use mobile as doc ID
          await docRef.set({
            "UserId": mobile,
            "Password": password,
            "uid": user.uid,
            "rolename": user.rolename,
            "roleId": user.roleId,
            "branchId": user.branchId,
            "branch_name": user.branch_name,
            "OTP": teamho.toString(),
            "userToken": userToken,
            "dateTime": DateTime.now(),
          });
          await docRef.update({
            "UserId": mobile,
            "Password": password,
            "uid": user.uid,
            "rolename": user.rolename,
            "roleId": user.roleId,
            "branchId": user.branchId,
            "branch_name": user.branch_name,
            "OTP": teamho.toString(),
            "userToken": userToken,
            "dateTime": DateTime.now(),
            "OTP": teamho.toString(),
          });

          Get.offAll(() => DashboardScreen());
          return {'success': true, 'user': user, 'message': data['message']};
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
