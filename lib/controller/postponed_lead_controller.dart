import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../model/postponed_lead_model.dart'; // adjust path as needed

Future<PostponeLeadResponse> postponeLead({
  required String loginId,
  required String leadId,
  required String remark,
  required String location,
  required String reason,
  required String newDate, // Optional, currently not used in PHP
  required String newTime, // Optional, currently not used in PHP
}) async {
  String latLongText = await _getCurrentLocation();
  final uri = Uri.parse(
    "https://fms.bizipac.com/apinew/ws_new/postponedlead.php",
  );

  final response = await http.post(
    uri,
    body: {
      "loginid": loginId,
      "leadid": leadId,
      "remark": remark,
      "location": location,
      "reason": reason,
      "newdate": newDate,
      "newtime": newTime,
      "geoLocation": latLongText,
    },
  );

  if (response.statusCode == 200) {
    final jsonResponse = json.decode(response.body);
    return PostponeLeadResponse.fromJson(jsonResponse);
  } else {
    throw Exception("Failed to postpone lead");
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
