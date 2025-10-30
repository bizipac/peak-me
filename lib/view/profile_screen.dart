import 'package:flutter/material.dart';
import 'package:peckme/view/widget/terms_conditions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_constant.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String? uid = '';

  //String rolename = '';
  String branchName = '';
  String authId = '';
  late String? profile = '';

  //String address = '';

  void loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? '';
      mobile = prefs.getString('mobile') ?? '';
      uid = prefs.getString('uid') ?? '';
      rolename = prefs.getString('rolename') ?? '';
      branchName = prefs.getString('branch_name') ?? '';
      authId = prefs.getString('authId') ?? '';
      profile = prefs.getString('image') ?? '';
      address = prefs.getString('address') ?? '';
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadUserData();
    print("-----");
    print(profile);
  }

  String formatRoleName(String text) {
    text = text.toLowerCase();

    // "fieldexecutive" ko "field executive" me convert
    text = text.replaceAll("fieldexecutive", "field executive");
    text = text.replaceAll("childexecutive", "child executive");
    // Har word ka pehla letter capital
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return "";
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  late String? name = '';

  late String? mobile = '';

  late String? rolename = '';

  final String company = '';

  final String subCompany =
      "Cargo & Courier\nFulfillment Services\n(Franchisee of Bizipac Couriers Pvt Ltd)";

  late String? address = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(
        backgroundColor: AppConstant.appBarColor,
        title: Text(
          'Profile',
          style: TextStyle(color: AppConstant.appBarWhiteColor, fontSize: 18),
        ),
        iconTheme: IconThemeData(color: AppConstant.appBarWhiteColor),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsAndConditionsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 6,
          child: Container(
            width: 300,
            height: 525,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppConstant.borderColor, width: 2),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🔶 Top Header (Yellow BG with company info)
                Container(
                  width: double.infinity,
                  color: AppConstant.darkButton,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  child: Column(
                    children: [
                      Text(
                        formatRoleName(rolename!).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subCompany,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // 👤 Profile Image (square like ID card)
                SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 100,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppConstant.borderColor),
                      image: DecorationImage(
                        image: NetworkImage('$profile'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(5),
                  child: Table(
                    border: TableBorder.all(
                      color: AppConstant.borderColor,
                      width: 1,
                    ),
                    // Inner cell borders
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              "Name",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConstant.darkButton,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              name!,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              "User ID ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConstant.darkButton,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text("$uid"),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              "Role",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConstant.darkButton,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(formatRoleName(rolename!)),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              "Auth ID",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConstant.darkButton,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text("$authId"),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              "Mobile No.",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConstant.darkButton,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text("$mobile"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      const Divider(thickness: 1),
                      const SizedBox(height: 8),
                      Text(
                        address!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
