import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:peckme/utils/app_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/receivedLead_controller.dart';
import '../model/new_lead_model.dart';
import 'child_executive_screen.dart';

class TransferLeadScreen extends StatefulWidget {
  const TransferLeadScreen({super.key});

  @override
  State<TransferLeadScreen> createState() => _TransferLeadScreenState();
}

class _TransferLeadScreenState extends State<TransferLeadScreen> {
  ReceivedLeadController receivedLeadController = ReceivedLeadController();
  List<Lead> leadsList = [];
  bool isLoading = true;

  String uid = '';
  String branchId = '';
  String appVersion = '40';
  String appType = '';

  List<Lead> selectedLeads = [];
  List<int> selectedIndexes = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      appType = Platform.isIOS ? 'ios' : 'android';
      uid = prefs.getString('uid') ?? '';
      branchId = prefs.getString('branchId') ?? '';

      List<Lead> fetchedLeads = await receivedLeadController.fetchLeads(
        uid: uid,
        start: 0,
        end: 10,
        branchId: branchId,
        app_version: appVersion,
        appType: appType,
      );

      setState(() {
        leadsList = fetchedLeads;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching leads: $e');
    }
  }

  void toggleSelection(int index) {
    setState(() {
      final lead = leadsList[index];

      if (selectedIndexes.contains(index)) {
        selectedIndexes.remove(index);
        selectedLeads.removeWhere((l) => l.leadId == lead.leadId);
      } else {
        selectedIndexes.add(index);
        selectedLeads.add(lead);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstant.appBarColor,
        title: Text(
          'Transfer Lead',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color: AppConstant.whiteBackColor,
          ),
        ),
        iconTheme: const IconThemeData(color: AppConstant.whiteBackColor),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : leadsList.isEmpty
          ? const Center(child: Text('No leads found.'))
          : ListView.builder(
              itemCount: leadsList.length,
              itemBuilder: (context, index) {
                final lead = leadsList[index];
                final isSelected = selectedIndexes.contains(index);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Card(
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0,
                      ),
                      title: Text(
                        lead.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppConstant.darkHeadingColor,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Text(
                              "LeadId : ${lead.leadId},  ",
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 10,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                "${lead.clientname}",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (_) => toggleSelection(index),
                        activeColor: AppConstant.iconColor,
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          onPressed: selectedLeads.isNotEmpty
              ? () async {
                  // 1. Create a list to hold the formatted lead data
                  List<Map<String, dynamic>> leadData = [];

                  // 2. Iterate through the selectedLeads and format each one
                  for (var lead in selectedLeads) {
                    leadData.add({
                      "leadid": lead.leadId,
                      // Get the lead ID from the current lead object
                    });
                  }

                  // 3. Wrap the list in the final parent map
                  Map<String, dynamic> finalPayload = {"lead_id": leadData};

                  // Print the final payload to verify the structure
                  print(finalPayload);
                  Get.to(() => ChildExecutiveScreen(data: finalPayload));
                  //Get.to(()=>ChildExecutiveScreen(user_id:uid,lead_id: selectedLeads.first.leadId,));
                  // Now, make the API call
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstant.darkButton,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          child: Text(
            'CONTINUE (${selectedLeads.length})',
            style: TextStyle(color: AppConstant.whiteBackColor),
          ),
        ),
      ),
    );
  }
}
