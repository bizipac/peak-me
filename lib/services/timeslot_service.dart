import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/time_slot_model.dart';

class TimeslotService {
  static Future<List<Timeslot>> fetchTimeSlots() async {
    const url =
        "https://fms.bizipac.com/apinew/ws_new/time_slot.php"; // Your actual API URL
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData['success'] == 1) {
        List<Timeslot> slots = (jsonData['data'] as List)
            .map((item) => Timeslot.fromJson(item))
            .toList();
        return slots;
      } else {
        throw Exception("No timeslots found.");
      }
    } else {
      throw Exception("Failed to fetch data.");
    }
  }
}
