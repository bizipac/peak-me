import 'dart:convert';
import 'package:http/http.dart' as http;

// Your API function
Future<Map<String, dynamic>?> sendMultipleLeadTransfer({
  required List<Map<String, dynamic>> dataList, // Corrected type to List<Map<String, dynamic>>
}) async {
  final payload = jsonEncode({"data": dataList}); // Wrap the list in a map and encode

  print("----------------");
  print(payload);
  print("https://fms.bizipac.com/apinew/ws_new/multipleLeadTransfer.php?leaddata=$payload");

  final response = await http.post(
    Uri.parse("https://fms.bizipac.com/apinew/ws_new/multipleLeadTransfer.php"),
    body:  {'leaddata': payload}, // Send as a map with key 'leaddata'
  );

  print("https://fms.bizipac.com/apinew/ws_new/multipleLeadTransfer.php?leaddata=$payload");
  print(response.body);
  print("----------------");

  if (response.statusCode == 200) {
    final body = response.body;
    try {
      final Map<String, dynamic> respJson = jsonDecode(body);
      return respJson;
    } catch (e) {
      throw Exception('Invalid JSON response: $e\n${response.body}');
    }
  } else {
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }
}