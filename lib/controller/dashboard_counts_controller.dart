// services/dashboard_service.dart
import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../model/dashboard_response_model.dart';

class DashboardService {
  static const String _baseUrl =
      'https://fms.bizipac.com/apinew/ws_new/dashboard_counts.php';

  final box = GetStorage(); // Local storage instance

  /// Pehle local data return karega, phir API se refresh karega
  Future<DashboardResponse> fetchDashboardCounts({required String uid}) async {
    // 1. Local data check
    final storedData = box.read("dashboard_response");
    if (storedData != null) {
      // Local data available hai to usko return karo
      final localResponse = DashboardResponse.fromJson(storedData);

      // Background me API refresh karna
      _refreshFromApi(uid);

      return localResponse;
    } else {
      // Agar local data nahi hai to direct API call karo
      return await _fetchFromApi(uid);
    }
  }

  /// API call karke latest data save karega
  Future<DashboardResponse> _fetchFromApi(String uid) async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl?uid=$uid'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Parse to model
        final dashboardResponse = DashboardResponse.fromJson(jsonData);

        // Local storage me save karo
        box.write("dashboard_response", jsonData);

        return dashboardResponse;
      } else {
        return DashboardResponse(
          success: 0,
          message: 'Server error',
          data: null,
        );
      }
    } catch (e) {
      return DashboardResponse(success: 0, message: e.toString(), data: null);
    }
  }

  /// Background refresh (UI ko block nahi karega)
  void _refreshFromApi(String uid) async {
    final latestData = await _fetchFromApi(uid);
    print("🔄 Dashboard refreshed: ${latestData.message}");
  }

  /// Agar sirf local data chahiye (without API)
  DashboardResponse? getStoredDashboard() {
    final storedData = box.read("dashboard_response");
    if (storedData != null) {
      return DashboardResponse.fromJson(storedData);
    }
    return null;
  }
}
