import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:peckme/model/charts/chart_user_model.dart';

class GetAllUserChart extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<ChartData> monthlyUserData = RxList<ChartData>();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    fetchMonthlyUsers();
  }

  Future<void> fetchMonthlyUsers() async {
    final CollectionReference userCollection = _firestore.collection("users");

    final DateTime dateMonthAgo = DateTime.now().subtract(Duration(days: 180));

    final QuerySnapshot allUsersSnapshot = await userCollection
        .where("dateTime", isGreaterThanOrEqualTo: dateMonthAgo)
        .get();
    final Map<String, int> monthlyCount = {};

    final QuerySnapshot userSnapshot = await allUsersSnapshot;

    userSnapshot.docs.forEach((users) {
      final Timestamp timestamp = users['dateTime'];
      final DateTime userDate = timestamp.toDate();
      final String monthYearKey = '${userDate.year}-${userDate.month}';
      monthlyCount[monthYearKey] = (monthlyCount[monthYearKey] ?? 0) + 1;
    });
    final List<ChartData> monthlyData = monthlyCount.entries
        .map((entry) => ChartData(entry.key, entry.value.toDouble()))
        .toList();
    if (monthlyData.isEmpty) {
      monthlyUserData.add(ChartData("Data not found", 0));
    } else {
      monthlyData.sort((a, b) => a.month.compareTo(b.month));
      monthlyUserData.assignAll(monthlyData);
    }
  }
}
