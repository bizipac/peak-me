import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:peckme/model/child_executive_model.dart';

class ChildExecutiveController{

// Function to fetch the child executive list
  Future<List<ChildExecutiveModel>> fetchChildExecutives(String parentId) async {
    final uri = Uri.parse('https://fms.bizipac.com/apinew/ws_new/childlist.php?parentid=$parentId');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Check if the API call was successful
        if (responseData['success'] == 1 && responseData['data'] is List) {
          List<dynamic> dataList = responseData['data'];

          // Map the list of JSON objects to a list of ChildExecutive objects
          List<ChildExecutiveModel> executives = dataList.map((json) => ChildExecutiveModel.fromJson(json)).toList();

          return executives;
        } else {
          // Handle cases where the API call was not successful or data is missing
          print('API Error: ${responseData['message']}');
          return [];
        }
      } else {
        // Handle non-200 status codes
        print('HTTP Error: ${response.statusCode}');
        throw Exception('Failed to load child executives');
      }
    } catch (e) {
      // Handle network or other exceptions
      print('Error fetching data: $e');
      throw Exception('Failed to connect to the server');
    }
  }
}