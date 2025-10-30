import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/today_transfer_lead_model.dart';

Future<TodayTransferredResponse?> fetchTodayTransferred(String uid) async {
  final url = Uri.parse(
    'https://fms.bizipac.com/apinew/ws_new/todaystransfered.php?uid=$uid',
  );

  try {
    final response = await http.get(url);
    print('-----TodayTransferList ------------');
    print(response.body);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return TodayTransferredResponse.fromJson(jsonData);
    } else {
      print('Server error: ${response.statusCode}');
    }
  } catch (e) {
    print('Fetch error: $e');
  }

  return null;
}
