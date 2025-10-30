import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:peckme/model/DocumentResponse.dart';

class DocumentController {
  static Future<DocumentResponse?> fetchDocument() async {
    final url = Uri.parse("https://fms.bizipac.com/apinew/display/document.php");
    try {
      final response = await http.get(url);

      print('--------Document API Response----------');
      print("Status Code: ${response.statusCode}");
      print("Raw Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        /// ✅ Make sure response has correct structure
        if (jsonData != null && jsonData is Map<String, dynamic>) {
          return DocumentResponse.fromJson(jsonData);
        } else {
          print("Invalid JSON format");
          return null;
        }
      } else {
        print("Server error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Fetch document error: $e");
      return null;
    }
  }
}
