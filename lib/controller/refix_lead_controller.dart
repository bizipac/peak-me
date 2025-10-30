import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../model/refix_lead_model.dart';

class RefixLeadService {
  static Future<RefixLeadResponse> submitRefixLead({
    required String loginId,
    required String leadId,
    required String newDate, // format: dd-MM-yyyy
    required String newTime, // format: HH:mm
    required String location,
    required String reason,
    required String remark,
  }) async {
    String latLongText = await _getCurrentLocation();
    final Uri url = Uri.parse(
      "https://fms.bizipac.com/apinew/ws_new/refixlead.php?loginid=$loginId&leadid=$leadId&newdate=$newDate&location=$location&reason=$reason&newtime=$newTime&remark=$remark&geoLocation=$latLongText",
    );
    print(url);
    final response = await http.post(url);
    print('-------------------------shubham----------');

    print(response.body);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return RefixLeadResponse.fromJson(jsonData);
    } else {
      return RefixLeadResponse(
        success: 0,
        message: "Server error: ${response.statusCode}",
      );
    }
  }
}

/// 🔹 Helper function: fetch current location
Future<String> _getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return "Location service disabled";
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return "Permission denied";
    }
  }
  if (permission == LocationPermission.deniedForever) {
    return "Permission permanently denied";
  }

  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  return "${position.latitude},${position.longitude}";
}
