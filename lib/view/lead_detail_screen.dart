import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:peckme/services/complete_lead_services.dart';
import 'package:peckme/view/child_executive_screen.dart';
import 'package:peckme/view/dashboard_screen.dart';
import 'package:peckme/view/postponed_lead_screen.dart';
import 'package:peckme/view/refix_lead_screen.dart';
import 'package:peckme/view/widget/doc_scren.dart';
import 'package:peckme/view/widget/webview_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/lead_detail_controller.dart';
import '../model/collected_doc_model.dart';
import '../model/lead_detail_model.dart';
import '../model/new_lead_model.dart';
import '../services/ExotelService.dart';
import '../services/getCurrentLocation.dart';
import '../services/session_id_services.dart';
import '../utils/app_constant.dart';

class LeadDetailScreen extends StatefulWidget {
  Lead lead;

  LeadDetailScreen({super.key, required this.lead});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  late List<String> collectedDoc;
  Future<LeadResponse?>? _futureLead;

  final platform = const MethodChannel("com.example.peckme/channel1");

  String user_id = '';
  String branchId = '';
  String authId = '';
  String name = '';

  List<CollectedDoc> collectedDocs = [];

  Future<void> deleteCollectedDoc(int index) async {
    if (index < 0 || index >= collectedDocs.length) return;

    final doc = collectedDocs[index];

    // 1️⃣ Delete local file
    final file = File(doc.path);
    if (await file.exists()) {
      await file.delete();
    }

    // 2️⃣ Remove from local list
    setState(() {
      collectedDocs.removeAt(index);
    });

    // 3️⃣ Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final jsonList = collectedDocs.map((d) => d.toJson()).toList();
    await prefs.setString("collectedDocs", jsonEncode(jsonList));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("✅ Document deleted")));
  }

  Future<void> deleteLastDocument() async {
    if (collectedDocs.isEmpty) return;

    final lastIndex = collectedDocs.length - 1;
    await deleteCollectedDoc(lastIndex);
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(
        dateString,
      ); // API से जो format आता है वो parse होगा
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateString; // अगर parse fail हो जाए तो original string return
    }
  }

  Future<List<CollectedDoc>> getCollectedDocsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString("collectedDocs");

    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((j) => CollectedDoc.fromJson(j)).toList();
  }

  void loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      user_id = prefs.getString('uid') ?? '';
      branchId = prefs.getString('branchId') ?? '';
      authId = prefs.getString('authId') ?? '';
      name = prefs.getString('name') ?? '';
    });
    final docs = await getCollectedDocsFromPrefs();
    setState(() {
      collectedDocs = docs;
    });
  }

  void _launchInBrowser(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _callLeads(BuildContext context, String leadId) async {
    String? number = await ExotelService.getVirtualNumber(leadId);
    if (number != null) {
      await FlutterPhoneDirectCaller.callNumber(number);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No number found")));
    }
  }

  _callNativeMethod({
    required String clientId,
    required String leadId,
    required String customerName,
    required String sessionId,
    required String amzAppID,
    required String user_id,
    required String branch_id,
    required String auth_id,
    required String client_lead_id,
    required String gpslat,
    required String gpslong,
    required String banID,
    required String userName,
    required String athena_lead_id,
    required String agentName,
  }) async {
    try {
      final result = await platform.invokeMethod<String>('callNativeMethod', {
        "client_id": clientId, // You can change this dynamically
        "lead_id": leadId, // You can change this dynamically
        "sessionId": sessionId, // You can change this dynamically
        "amzAppID": amzAppID,
        "customerName": customerName, // You can change this dynamically
        "user_id": user_id,
        "branch_id": branch_id,
        "auth_id": auth_id,
        "client_lead_id": client_lead_id,
        "gpslat": gpslat,
        "gpslong": gpslong,
        "banID": banID,
        "userName": userName,
        "athena_lead_id": athena_lead_id,
        "agentName": agentName,
      });
      print("Result from native: $result");
      Get.snackbar(
        "Message",
        "$result",
        icon: Image.asset("assets/logo/cmp_logo.png", height: 30, width: 30),
        shouldIconPulse: true,
        // Small animation on the icon
        backgroundColor: AppConstant.appSnackBarBackground,
        colorText: AppConstant.appTextColor,
        snackPosition: SnackPosition.BOTTOM,
        // or TOP
        borderRadius: 15,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
        isDismissible: true,
        forwardAnimationCurve: Curves.easeOutBack,
      );
    } on PlatformException catch (e) {
      print("Exception while calling Native Method  : $e");
    }
  }

  // Function to launch another app

  String location_lat = '';
  String location_long = '';

  void _getLocation() async {
    try {
      Position position = await getCurrentLocation();
      setState(() {
        location_lat = '${position.latitude}';
        location_long = '${position.longitude}';
      });
    } catch (e) {
      setState(() {
        location_lat = 'Error: ${e.toString()}';
        location_long = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _futureLead = LeadDetailsController.fetchLeadById(widget.lead.leadId);
    print("-----------------");
    print(_futureLead);
    _getLocation();
    loadUserData();

    platform.setMethodCallHandler((call) async {
      if (call.method == "onSdkExit") {
        String rawResponse = call.arguments ?? "{}";
        print("✅ SDK returned: $rawResponse");

        try {
          final Map<String, dynamic> response = jsonDecode(rawResponse);

          if ((response["currentProgress"] ?? "") == "CKYC_APPROVAL") {
            // Save to server
            await _saveResponseToServer(response);

            // Navigate to Dashboard
            if (mounted) {
              Get.offAll(() => DashboardScreen());
              Get.snackbar(
                "Success",
                "Lead Completed successfully ✅!",
                icon: Image.asset(
                  "assets/logo/cmp_logo.png",
                  height: 30,
                  width: 30,
                ),
                shouldIconPulse: true,
                backgroundColor: AppConstant.snackBackColor,
                colorText: AppConstant.snackFontColor,
                snackPosition: SnackPosition.BOTTOM,
                borderRadius: 15,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                duration: const Duration(seconds: 3),
                isDismissible: true,
                forwardAnimationCurve: Curves.easeOutBack,
              );
            }
          } else {
            if (mounted) Get.back();
          }
        } catch (e) {
          print("❌ JSON parse error: $e");
          if (mounted) Get.back();
        }
      }
    });
  }

  Future<void> _saveResponseToServer(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse("https://fms.bizipac.com/apinew/ws_new/amzonrevert.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userid": user_id.toString(), "response": data}),
      );
      print("📡 Server reply: ${res.body}");
    } catch (e) {
      print("❌ Error saving response: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstant.appBarColor,
        title: Text(
          'Lead Details ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color: AppConstant.appBarWhiteColor,
          ),
        ),
        iconTheme: IconThemeData(color: AppConstant.appBarWhiteColor),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: CircleAvatar(
              backgroundColor: AppConstant.appBattonBack,
              child: IconButton(
                onPressed: () async {
                  final response = widget.lead.leadId;
                  _callLeads(context, response);
                },
                icon: Icon(Icons.call, color: AppConstant.iconColor),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<LeadResponse?>(
        future: _futureLead,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data!.data.isNotEmpty) {
            final lead = snapshot.data!.data[0]; // Get the first item
            final String? callDate = lead.callDate;
            print("Auth/BanId : $authId");
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Text(location_lat+location_long),
                    // Card Section
                    Container(
                      margin: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.01,
                        horizontal: screenWidth * 0.03,
                      ),
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppConstant.borderColor,
                          width: 2,
                        ), // 1px border
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          bool isWide =
                              constraints.maxWidth > 600; // tablet/web check

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Top Row
                              isWide
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: _infoText(
                                            "Lead ID",
                                            lead.leadId,
                                          ),
                                        ),
                                        Expanded(
                                          child: _infoText(
                                            "Client ID",
                                            lead.clientId,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _infoText("Lead ID", lead.leadId),
                                        SizedBox(height: 2),
                                        _infoText("Client ID", lead.clientId),
                                      ],
                                    ),
                              SizedBox(height: 2),

                              /// Grid-like layout for info
                              Wrap(
                                spacing: 1,
                                runSpacing: 1,
                                children: [
                                  SizedBox(
                                    width: isWide
                                        ? (constraints.maxWidth / 2) - 20
                                        : constraints.maxWidth,
                                    child: _infoText(
                                      "Customer Name",
                                      lead.customerName,
                                      //isExpanded: true,
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide
                                        ? (constraints.maxWidth / 2) - 20
                                        : constraints.maxWidth,
                                    child: _infoText("Product", lead.product),
                                  ),
                                  SizedBox(
                                    width: isWide
                                        ? (constraints.maxWidth / 2) - 20
                                        : constraints.maxWidth,
                                    child: _infoText(
                                      "Lead Date",
                                      _formatDate(lead.leadDate),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide
                                        ? (constraints.maxWidth / 2) - 20
                                        : constraints.maxWidth,
                                    child: _infoText(
                                      "App No",
                                      lead.athenaLeadId,
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide
                                        ? (constraints.maxWidth / 2) - 20
                                        : constraints.maxWidth,
                                    child: _infoText(
                                      "Address",
                                      lead.resAddress,
                                      //isExpanded: true,
                                      maxLines: 5,
                                    ),
                                  ),
                                ],
                              ),

                              /// Expand Button
                              Center(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        elevation: 6,
                                        clipBehavior: Clip.hardEdge,
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          side: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                        insetPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 24,
                                            ),
                                        content: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.9,
                                            maxHeight:
                                                MediaQuery.of(
                                                  context,
                                                ).size.height *
                                                0.8,
                                          ),
                                          child: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Align(
                                                  alignment: Alignment.topRight,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                      Icons.close,
                                                      color: Colors.black54,
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                  ),
                                                ),
                                                if (lead.empName != null &&
                                                    lead.empName!.isNotEmpty)
                                                  _infoRow(
                                                    "Emp Name",
                                                    lead.empName,
                                                  ),
                                                if (lead.clientName != null &&
                                                    lead.clientName!.isNotEmpty)
                                                  _infoRow(
                                                    "Client Name",
                                                    lead.clientName,
                                                  ),
                                                if (lead.product != null &&
                                                    lead.product!.isNotEmpty)
                                                  _infoRow(
                                                    "Product",
                                                    lead.product,
                                                  ),
                                                if (lead.source != null &&
                                                    lead.source!.isNotEmpty)
                                                  _infoRow(
                                                    "Source",
                                                    lead.source,
                                                  ),
                                                if (lead.appLoc != null &&
                                                    lead.appLoc!.isNotEmpty)
                                                  _infoRow(
                                                    "App Location",
                                                    lead.appLoc,
                                                  ),
                                                if (lead.productCode != null &&
                                                    lead
                                                        .productCode!
                                                        .isNotEmpty)
                                                  _infoRow(
                                                    "Product code",
                                                    lead.productCode,
                                                    maxLines: 5,
                                                  ),
                                                if (lead.source2 != null &&
                                                    lead.source2!.isNotEmpty)
                                                  _infoRow(
                                                    "Product Category",
                                                    lead.source2,
                                                    maxLines: 5,
                                                  ),
                                                if (lead.source3 != null &&
                                                    lead.source3!.isNotEmpty)
                                                  _infoRow(
                                                    "Proxy No",
                                                    lead.source3,
                                                    maxLines: 5,
                                                  ),
                                                if (lead.formNo != null &&
                                                    lead.formNo!.isNotEmpty)
                                                  _infoRow(
                                                    "Card No",
                                                    lead.formNo,
                                                    maxLines: 5,
                                                  ),
                                                if (lead.doc != null &&
                                                    lead.doc!.isNotEmpty)
                                                  _infoRow(
                                                    "Doc By Tc",
                                                    lead.doc,
                                                    maxLines: 5,
                                                  ),
                                                if (lead.doc != null &&
                                                    lead.doc!.isNotEmpty)
                                                  _infoRow(
                                                    "Doc By Tc",
                                                    lead.doc,
                                                    maxLines: 5,
                                                  ),
                                                if (lead.accHolder != null &&
                                                    lead.accHolder!.isNotEmpty)
                                                  _infoRow(
                                                    "SIM No",
                                                    lead.accHolder,
                                                  ),
                                                if (lead.aadharCard != null &&
                                                    lead.aadharCard!.isNotEmpty)
                                                  _infoRow(
                                                    "Aadharcard",
                                                    lead.aadharCard,
                                                  ),
                                                if (lead.athenaLeadId != null &&
                                                    lead
                                                        .athenaLeadId!
                                                        .isNotEmpty)
                                                  _infoRow(
                                                    "App No",
                                                    lead.athenaLeadId,
                                                  ),
                                                if (lead.appAdd != null &&
                                                    lead.appAdd!.isNotEmpty)
                                                  _infoRow(
                                                    "App Add",
                                                    lead.appAdd,
                                                  ),
                                                if (lead.secCode != null &&
                                                    lead.secCode!.isNotEmpty)
                                                  _infoRow(
                                                    "Device Id ",
                                                    lead.secCode,
                                                  ),
                                                if (lead.compName != null &&
                                                    lead.compName!.isNotEmpty)
                                                  _infoRow(
                                                    "UPI Id",
                                                    lead.compName,
                                                  ),
                                                if (lead.city != null &&
                                                    lead.city!.isNotEmpty)
                                                  _infoRow("City", lead.city),
                                                if (lead.offPincode != null &&
                                                    lead.offPincode!.isNotEmpty)
                                                  _infoRow(
                                                    "Office Pin Code",
                                                    lead.offPincode,
                                                  ),
                                                if (lead.resPin != null &&
                                                    lead.resPin!.isNotEmpty)
                                                  _infoRow(
                                                    "Res Pin Code",
                                                    lead.resPin,
                                                  ),
                                                if (lead.location != null &&
                                                    lead.location!.isNotEmpty)
                                                  _infoRow(
                                                    "Location",
                                                    lead.location,
                                                  ),
                                                if (lead.appAdd != null &&
                                                    lead.appAdd!.isNotEmpty)
                                                  _infoRow(
                                                    "App Address",
                                                    lead.appAdd,
                                                    maxLines: 5,
                                                  ),
                                                if (lead.offAddress != null &&
                                                    lead.offAddress!.isNotEmpty)
                                                  _infoRow(
                                                    "Off Address",
                                                    lead.offAddress,
                                                    maxLines: 5,
                                                  ),
                                                if (lead.resAddress != null &&
                                                    lead.resAddress!.isNotEmpty)
                                                  _infoRow(
                                                    "Res Address",
                                                    lead.resAddress,
                                                    maxLines: 5,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_drop_down_circle,
                                        color: AppConstant.iconColor,
                                        size: 28,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "View More",
                                        style: TextStyle(
                                          color: AppConstant.darkButton,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.0),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.95,
                            child: ElevatedButton(
                              onPressed: () async {
                                List<Map<String, dynamic>> leadData = [];
                                // 2. Iterate through the selectedLeads and format each one
                                leadData.add({
                                  "leadid": lead.leadId,
                                  // Get the lead ID from the current lead object
                                });
                                // 3. Wrap the list in the final parent map
                                Map<String, dynamic> finalPayload = {
                                  "lead_id": leadData,
                                };
                                Get.to(
                                  () =>
                                      ChildExecutiveScreen(data: finalPayload),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstant.whiteBackColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Assign Lead',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppConstant.iconColor,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(
                                    Icons.send_to_mobile_outlined,
                                    size: 18,
                                    color: AppConstant.iconColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Get.to(
                                () => PostponeLeadScreen(
                                  leadId: lead.leadId.toString(),
                                  customer_name: lead.customerName.toString(),
                                  location: lead.location,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstant.whiteBackColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Assign for TC',
                                  style: TextStyle(
                                    color: AppConstant.darkButton,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(
                                  Icons.send,
                                  size: 15,
                                  color: AppConstant.iconColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Get.to(
                                () => RefixLeadScreen(
                                  leadId: lead.leadId.toString(),
                                  customer_name: lead.customerName.toString(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstant.whiteBackColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Re-schedule',
                                  style: TextStyle(
                                    color: AppConstant.iconColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(
                                  Icons.schedule_outlined,
                                  size: 15,
                                  color: AppConstant.iconColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    lead.client_mobile_app == "1"
                        ? lead.clientId == "11"
                              ? ElevatedButton(
                                  onPressed: () async {
                                    String name = '';
                                    String uid = '';
                                    String branchId = '';
                                    String authId = '';
                                    final SharedPreferences prefs =
                                        await SharedPreferences.getInstance();

                                    setState(() {
                                      name = prefs.getString('name') ?? '';
                                      uid = prefs.getString('uid') ?? '';
                                      branchId =
                                          prefs.getString('branchId') ?? '';
                                      authId = prefs.getString('authId') ?? '';
                                    });

                                    _callNativeMethod(
                                      clientId: lead.clientId,
                                      leadId: lead.leadId,
                                      sessionId: "",
                                      // safe now
                                      amzAppID: lead.athenaLeadId,
                                      customerName: lead.customerName,
                                      banID: authId,
                                      userName: authId,
                                      athena_lead_id: lead.athenaLeadId,
                                      agentName: name,
                                      user_id: uid,
                                      branch_id: branchId,
                                      auth_id: authId,
                                      client_lead_id: lead.athenaLeadId,
                                      gpslat: location_lat,
                                      gpslong: location_long,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstant.whiteBackColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Start Biometrics',
                                          style: TextStyle(
                                            color: AppConstant.darkButton,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Icon(
                                          Icons.fingerprint_outlined,
                                          size: 15,
                                          color: AppConstant.iconColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : lead.clientId == "89"
                              ? lead.serviceId == "1"
                                    ? ElevatedButton(
                                        onPressed: () async {
                                          Get.to(
                                            () => DocumentScreenTest(
                                              clientName: lead.clientName,
                                              leadId: lead.leadId,
                                              clientId: lead.clientId,
                                              userName: name,
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppConstant.whiteBackColor,
                                          shadowColor:
                                              Colors.black, // 🔥 Black shadow
                                          elevation: 1, // shadow की depth
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Select doc',
                                                style: TextStyle(
                                                  color: AppConstant.iconColor,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Icon(
                                                Icons.file_copy_outlined,
                                                color: AppConstant.iconColor,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: () {
                                          // _launchInBrowser('https://fms.bizipac.com/apinew/secureapi/icici_pre_paid_card_gen.php?user_id=$user_id&branch_id=$branchId#!/');
                                          _launchInBrowser(
                                            'https://fms.bizipac.com/apinew/dynamic_form/executive_add_form.php?user_id=$user_id&lead_id=${lead.leadId}#!/',
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppConstant.whiteBackColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Add Details',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: AppConstant.darkButton,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'impact',
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              Icon(
                                                Icons.add,
                                                size: 15,
                                                color: AppConstant.iconColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                              : lead.clientId == "38"
                              ? ElevatedButton(
                                  onPressed: () async {
                                    String name = '';
                                    String uid = '';
                                    String branchId = '';
                                    String authId = '';
                                    String userToken = '';
                                    final SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    setState(() {
                                      name = prefs.getString('name') ?? '';
                                      uid = prefs.getString('uid') ?? '';
                                      branchId =
                                          prefs.getString('branchId') ?? '';
                                      userToken =
                                          prefs.getString('userToken') ?? '';
                                      authId = prefs.getString('authId') ?? '';
                                    });
                                    String? sessionid;
                                    sessionid = await ApiService.getSessionId(
                                      authId,
                                    );
                                    if (authId.isNotEmpty &&
                                        (sessionid?.isNotEmpty ?? false)) {
                                      _callNativeMethod(
                                        clientId: lead.clientId,
                                        leadId: lead.leadId,
                                        sessionId: sessionid!,
                                        amzAppID: lead.athenaLeadId,
                                        customerName: lead.customerName,
                                        banID: authId,
                                        userName: authId,
                                        athena_lead_id: lead.athenaLeadId,
                                        agentName: name,
                                        user_id: uid,
                                        branch_id: branchId,
                                        auth_id: authId,
                                        client_lead_id: lead.athenaLeadId,
                                        gpslat: location_lat,
                                        gpslong: location_long,
                                      );
                                    } else {
                                      Get.snackbar(
                                        "Message",
                                        "Your auth_id expire please contact to head office!",
                                        icon: Image.asset(
                                          "assets/logo/cmp_logo.png",
                                          height: 30,
                                          width: 30,
                                        ),
                                        shouldIconPulse: true,
                                        // Small animation on the icon
                                        backgroundColor:
                                            AppConstant.appSnackBarBackground,
                                        colorText: AppConstant.appTextColor,
                                        snackPosition: SnackPosition.BOTTOM,
                                        // or TOP
                                        borderRadius: 15,
                                        margin: const EdgeInsets.all(12),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        duration: const Duration(seconds: 3),
                                        isDismissible: true,
                                        forwardAnimationCurve:
                                            Curves.easeOutBack,
                                      );
                                    }
                                    // openNXTServices();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstant.whiteBackColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Open Client App',
                                          style: TextStyle(
                                            color: AppConstant.iconColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Icon(
                                          Icons.app_shortcut,
                                          size: 15,
                                          color: AppConstant.iconColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : lead.clientId == "28"
                              ? ElevatedButton(
                                  onPressed: () async {
                                    String name = '';
                                    String uid = '';
                                    String branchId = '';
                                    String authId = '';
                                    String userToken = '';
                                    final SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    setState(() {
                                      name = prefs.getString('name') ?? '';
                                      uid = prefs.getString('uid') ?? '';
                                      branchId =
                                          prefs.getString('branchId') ?? '';
                                      userToken =
                                          prefs.getString('userToken') ?? '';
                                      authId = prefs.getString('authId') ?? '';
                                    });
                                    String? sessionid;
                                    sessionid = await ApiService.getSessionId(
                                      authId,
                                    );
                                    if (authId.isNotEmpty &&
                                        (sessionid?.isNotEmpty ?? false)) {
                                      _callNativeMethod(
                                        clientId: lead.clientId,
                                        leadId: lead.leadId,
                                        sessionId: sessionid!,
                                        amzAppID: lead.athenaLeadId,
                                        customerName: lead.customerName,
                                        banID: authId,
                                        userName: authId,
                                        athena_lead_id: lead.athenaLeadId,
                                        agentName: name,
                                        user_id: uid,
                                        branch_id: branchId,
                                        auth_id: authId,
                                        client_lead_id: lead.athenaLeadId,
                                        gpslat: location_lat,
                                        gpslong: location_long,
                                      );
                                    } else {
                                      Get.snackbar(
                                        "Message",
                                        "Your auth_id expire please contact head office!",
                                        icon: Image.asset(
                                          "assets/logo/cmp_logo.png",
                                          height: 30,
                                          width: 30,
                                        ),
                                        shouldIconPulse: true,
                                        // Small animation on the icon
                                        backgroundColor:
                                            AppConstant.appSnackBarBackground,
                                        colorText: AppConstant.appTextColor,
                                        snackPosition: SnackPosition.BOTTOM,
                                        // or TOP
                                        borderRadius: 15,
                                        margin: const EdgeInsets.all(12),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        duration: const Duration(seconds: 3),
                                        isDismissible: true,
                                        forwardAnimationCurve:
                                            Curves.easeOutBack,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstant.whiteBackColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Open Client App',
                                          style: TextStyle(
                                            color: AppConstant.darkButton,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Icon(
                                          Icons.food_bank_rounded,
                                          size: 15,
                                          color: AppConstant.iconColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () async {
                                    String name = '';
                                    String uid = '';
                                    String branchId = '';
                                    String authId = '';
                                    String userToken = '';
                                    final SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    setState(() {
                                      name = prefs.getString('name') ?? '';
                                      uid = prefs.getString('uid') ?? '';
                                      branchId =
                                          prefs.getString('branchId') ?? '';
                                      userToken =
                                          prefs.getString('userToken') ?? '';
                                      authId = prefs.getString('authId') ?? '';
                                    });
                                    String? sessionid;
                                    sessionid = await ApiService.getSessionId(
                                      authId,
                                    );
                                    if (authId.isNotEmpty &&
                                        (sessionid?.isNotEmpty ?? false)) {
                                      _callNativeMethod(
                                        clientId: lead.clientId,
                                        leadId: lead.leadId,
                                        sessionId: sessionid!,
                                        amzAppID: lead.athenaLeadId,
                                        customerName: lead.customerName,
                                        banID: authId,
                                        userName: authId,
                                        athena_lead_id: lead.athenaLeadId,
                                        agentName: name,
                                        user_id: uid,
                                        branch_id: branchId,
                                        auth_id: authId,
                                        client_lead_id: lead.athenaLeadId,
                                        gpslat: location_lat,
                                        gpslong: location_long,
                                      );
                                    } else {
                                      Get.snackbar(
                                        "Message",
                                        "Your auth_id expire please contact head office!",
                                        icon: Image.asset(
                                          "assets/logo/cmp_logo.png",
                                          height: 30,
                                          width: 30,
                                        ),
                                        shouldIconPulse: true,
                                        // Small animation on the icon
                                        backgroundColor:
                                            AppConstant.appSnackBarBackground,
                                        colorText: AppConstant.appTextColor,
                                        snackPosition: SnackPosition.BOTTOM,
                                        // or TOP
                                        borderRadius: 15,
                                        margin: const EdgeInsets.all(12),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        duration: const Duration(seconds: 3),
                                        isDismissible: true,
                                        forwardAnimationCurve:
                                            Curves.easeOutBack,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstant.appBattonBack,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Open ICICI App',
                                          style: TextStyle(
                                            color: AppConstant.darkButton,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Icon(
                                          Icons.app_registration_outlined,
                                          size: 18,
                                          color: AppConstant.iconColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                        : lead.client_mobile_app == "2"
                        ? lead.fiData == 1
                              ? ElevatedButton(
                                  onPressed: () async {
                                    //Get.snackbar("client mobile", "2 fidata-1");
                                    //await DocumentController.fetchDocument();
                                    Get.to(
                                      () => DocumentScreenTest(
                                        clientName: lead.clientName,
                                        leadId: lead.leadId,
                                        clientId: lead.clientId,
                                        userName: name,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstant.whiteBackColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Select Doc',
                                          style: TextStyle(
                                            color: AppConstant.darkButton,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Icon(
                                          Icons.file_copy_outlined,
                                          size: 15,
                                          color: AppConstant.iconColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ) //Select Doc
                              : lead.clientId == lead.clientId
                              ? ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => WebViewScreen(
                                          url:
                                              "${lead.cpv_url_new}${lead.leadId}#!/",
                                          customerName: lead.customerName,
                                          client: lead.clientName,
                                          leadid: lead.leadId,
                                          //fidatal: lead.fiData,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstant.whiteBackColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'CPV',
                                          style: TextStyle(
                                            color: AppConstant.darkButton,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Icon(
                                          Icons.person_outline_outlined,
                                          size: 15,
                                          color: AppConstant.iconColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => WebViewScreen(
                                          url:
                                              "https://fms.bizipac.com/fi/index.php?lead_id=${lead.leadId}#!/",
                                          customerName: lead.customerName,
                                          client: lead.clientName,
                                          leadid: lead.leadId,
                                          //fidatal: lead.fiData,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstant.whiteBackColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'CPV',
                                          style: TextStyle(
                                            color: AppConstant.darkButton,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Icon(
                                          Icons.person_outline_outlined,
                                          color: AppConstant.iconColor,
                                          size: 15,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                        : lead.client_mobile_app == "3"
                        ? ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstant.whiteBackColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Open fi url',
                                style: TextStyle(
                                  color: AppConstant.darkButton,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () async {
                              Get.to(
                                () => DocumentScreenTest(
                                  clientName: lead.clientName,
                                  leadId: lead.leadId,
                                  clientId: lead.clientId,
                                  userName: name,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstant.whiteBackColor,
                              shadowColor: Colors.black, // 🔥 Black shadow
                              elevation: 1, // shadow की depth
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Select doc',
                                    style: TextStyle(
                                      color: AppConstant.iconColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.file_copy_outlined,
                                    color: AppConstant.iconColor,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ), //select Doc
                    lead.clientId == "49"
                        ? Text(
                            "Message (Bank Bazar staus ${lead.surrogate})",
                            style: TextStyle(
                              color: AppConstant.darkHeadingColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : SizedBox.shrink(),

                    (lead.client_mobile_app == "2" && lead.fiData == 1) ||
                            (lead.client_mobile_app == '1' &&
                                lead.clientId == "89") ||
                            (lead.client_mobile_app == "0" && lead.fiData == 0)
                        ? ElevatedButton(
                            onPressed: () async {
                              _showConfirmDialog(context, lead.leadId, user_id);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstant.darkButton,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Final Submit Lead',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.mark_chat_read_outlined,
                                    color: AppConstant.whiteBackColor,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SizedBox.shrink(),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: Text("No lead found."));
          }
        },
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, String leadId, String user_id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Complete Lead"),
        content: const Text("Are you sure you want to complete this lead?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // ❌ No
            },
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await CompleteLeadServices().completeLead(
                loginId: user_id,
                leadId: leadId,
              );
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(
                "collectedDocs",
              ); // ya prefs.setString("collectedDocs", "[]");

              // 2️⃣ Local list clear (UI refresh ke liye)
              setState(() {
                collectedDocs.clear();
              });

              if (result.success == 1) {
                Get.offAll(() => DashboardScreen());
                Get.snackbar(
                  "Final",
                  "${result.message}",
                  icon: Image.asset(
                    "assets/logo/cmp_logo.png",
                    height: 30,
                    width: 30,
                  ),
                  shouldIconPulse: true,
                  backgroundColor: AppConstant.snackBackColor,
                  colorText: AppConstant.snackFontColor,
                  snackPosition: SnackPosition.BOTTOM,
                  borderRadius: 15,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  duration: const Duration(seconds: 3),
                  isDismissible: true,
                  forwardAnimationCurve: Curves.easeOutBack,
                );
              } else {
                Navigator.of(context).pop(true);
                // ❌ अगर fail हुआ तो error message दिखा दो
                Get.snackbar(
                  "Error",
                  result.message.isNotEmpty
                      ? result.message
                      : "Please uploads the documents!",
                  backgroundColor: AppConstant.snackBackColor,
                  colorText: AppConstant.snackFontColor,
                  snackPosition: SnackPosition.BOTTOM,
                  borderRadius: 15,
                  margin: const EdgeInsets.all(12),
                  duration: const Duration(seconds: 3),
                );
              }
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }
}

/// Helper for dialog info rows
Widget _infoText(String title, String value, {int maxLines = 2}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            "$title:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppConstant.darkButton,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: AppConstant.appTextColor),
          ),
        ),
      ],
    ),
  );
}

/// Small inline widget for label + value
Widget _infoRow(String label, String value, {int maxLines = 2}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 125,
          child: Text(
            "$label: ",
            style: TextStyle(
              fontSize: 12,
              color: AppConstant.darkButton,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: const TextStyle(
              fontSize: 12,
              color: AppConstant.appTextColor,
            ),
          ),
        ),
      ],
    ),
  );
}
