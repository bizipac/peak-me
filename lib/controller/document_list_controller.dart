import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/document_list_model.dart'; // Make sure to replace 'api_client' with your project name.

class DocumentService {
  final String apiUrl =
      'https://fms.bizipac.com/apinew/ws_new/documentlist.php';

  // Asynchronous function to fetch the list of documents from the API.
  Future<Document?> fetchDocuments() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      // Check if the server responded with a successful status code.
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        /// ✅ Make sure response has correct structure
        if (jsonData != null && jsonData is Map<String, dynamic>) {
          return Document.fromJson(jsonData);
        } else {
          print("Invalid JSON format");
          return null;
        }
      } else {
        print("Server error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      // Catch any network or parsing errors and re-throw them with a clear message.
      throw Exception('Failed to fetch data: $e');
    }
  }
}
