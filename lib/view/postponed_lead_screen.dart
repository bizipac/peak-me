import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peckme/view/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/postponed_lead_controller.dart';
import '../model/reason_item_model.dart';
import '../services/reasom_services.dart';
import '../utils/app_constant.dart';

class PostponeLeadScreen extends StatefulWidget {
  final String leadId;
  final String customer_name;
  final String location;

  PostponeLeadScreen({
    super.key,
    required this.leadId,
    required this.customer_name,
    required this.location,
  });

  @override
  State<PostponeLeadScreen> createState() => _PostponeLeadScreenState();
}

class _PostponeLeadScreenState extends State<PostponeLeadScreen> {
  //fetch reason start code
  List<ReasonItem> reasons = [];
  String? selectedReason;
  final TextEditingController remark = TextEditingController();

  void loadReasons() async {
    try {
      final fetchedReasons = await ReasonService.fetchReasons(widget.leadId);
      setState(() {
        reasons = fetchedReasons;
      });
    } catch (e) {
      print("Error loading reasons: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load reasons")));
    }
  }

  //end fetch reason code here

  String currentDate = "";
  String currentTime = "";

  void setCurrentDate() {
    DateTime now = DateTime.now();
    setState(() {
      currentDate = '${now.day}-${now.month}-${now.year}';
      currentTime = '${now.hour}:${now.minute}:${now.second}';
      print(currentDate); // optional
    });
  }

  String _location = '';
  String uid = '';

  Future<void> loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    uid = prefs.getString('uid') ?? '';
  }

  @override
  void initState() {
    super.initState();
    setCurrentDate();
    loadReasons();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstant.appBarColor,
        title: Text(
          widget.customer_name.toString(),
          style: TextStyle(color: AppConstant.appBarWhiteColor, fontSize: 17),
        ),
        iconTheme: IconThemeData(color: AppConstant.appBarWhiteColor),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(widget.location.toString()),
            // Text(widget.leadId.toString()),
            // Text(uid.toString()),
            // Text(currentDate.toString()),
            // Text(currentTime.toString()),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Select reason for Refix Appointment : *',
                style: TextStyle(
                  color: AppConstant.darkHeadingColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RaleWay',
                ),
              ),
            ),
            reasons.isEmpty
                ? CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            hint: Text(
                              'Select Reason',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: AppConstant.appTextColor,
                              ),
                            ),
                            value: selectedReason,
                            items: reasons.map((item) {
                              return DropdownMenuItem<String>(
                                value: item.reason,
                                child: Text(
                                  item.reason,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedReason = value;
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppConstant.borderColor,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppConstant.borderColor,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppConstant.borderColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Enter remarks for Refix Appointment : ',
                style: TextStyle(
                  color: AppConstant.appTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RaleWay',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: remark,
                maxLines: 3,
                keyboardType: TextInputType.name,
                // 🔹 name वाला keyboard letters पर focus करता है
                textInputAction: TextInputAction.newline,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(
                    RegExp(r"[!@#\$%\^&\*\(\)_\+]"),
                  ),
                ],
                decoration: InputDecoration(
                  hintText: "Type your remark here...",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppConstant.appTextColor,
                  ),
                  filled: true,
                  fillColor: AppConstant.whiteBackColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppConstant.borderColor,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppConstant.borderColor,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppConstant.borderColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity, // full width
            height: 50, // fixed height
            child: ElevatedButton(
              onPressed: () async {
                print(remark.text);
                if (selectedReason == null ||
                    currentDate.isEmpty ||
                    currentTime.isEmpty ||
                    widget.location == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please fill all required fields"),
                    ),
                  );
                  return;
                }

                // ✅ Show loader
                EasyLoading.show(status: 'Please wait...');
                await Future.delayed(
                  const Duration(milliseconds: 100),
                ); // ensures loader displays

                try {
                  final result = await postponeLead(
                    loginId: uid.toString(),
                    leadId: widget.leadId.toString(),
                    remark: remark.text,
                    // use controller.text
                    location: widget.location.toString(),
                    reason: selectedReason!,
                    newDate: currentDate,
                    newTime: currentTime,
                  );

                  EasyLoading.dismiss(); // ✅ hide loader

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result.message)));

                  if (result.success == 1) {
                    Get.offAll(() => DashboardScreen());
                  }
                } catch (e) {
                  EasyLoading.dismiss(); // ✅ hide loader on error
                  print("Error: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to postpone lead")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstant.darkButton,
                foregroundColor: AppConstant.appTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                "Postpone Lead",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppConstant.whiteBackColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
