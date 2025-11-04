import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peckme/view/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/refix_lead_controller.dart';
import '../model/reason_item_model.dart';
import '../model/time_slot_model.dart';
import '../services/reasom_services.dart';
import '../services/timeslot_service.dart';
import '../utils/app_constant.dart';

class RefixLeadScreen extends StatefulWidget {
  final String leadId;
  final String customer_name;

  RefixLeadScreen({
    super.key,
    required this.leadId,
    required this.customer_name,
  });

  @override
  State<RefixLeadScreen> createState() => _RefixLeadScreenState();
}

class _RefixLeadScreenState extends State<RefixLeadScreen> {
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

  //start time slot dropdown
  List<Timeslot> timeslotList = [];
  String? selectedTimeslot;

  void loadTimeslots() async {
    try {
      final data = await TimeslotService.fetchTimeSlots();
      setState(() {
        timeslotList = data;
      });
    } catch (e) {
      print("Error fetching timeslots: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load timeslots")));
    }
  }

  //end timeslot dropdown
  String currentDate = "";

  Future<void> dateTime() async {
    DateTime? datePickerd = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 2)),
    );

    if (datePickerd != null) {
      setState(() {
        currentDate =
            '${datePickerd.day}-${datePickerd.month}-${datePickerd.year}';
      });
    }
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
    loadReasons();
    loadTimeslots();
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Select the date and time you want to Refix Appointment : *',
                style: GoogleFonts.poppins(
                  // 👈 changed font family
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppConstant
                      .darkHeadingColor, // 👈 changed color (you can also use AppConstant.appTextColor)
                ),
              ),
            ),
            // 👇 Button तभी दिखे जब currentDate empty हो
            currentDate.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          dateTime(); // Date picker open
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppConstant.darkButton, // 👈 button color
                          foregroundColor:
                              AppConstant.whiteBackColor, // 👈 text color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12,
                            ), // 👈 rounded corners
                          ),
                          elevation: 4, // 👈
                        ),
                        child: Container(
                          width: 150,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Select Date',
                                style: GoogleFonts.poppins(
                                  color: AppConstant.whiteBackColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(
                                Icons.date_range_outlined,
                                color: AppConstant.whiteBackColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppConstant.borderColor,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currentDate,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // दोबारा date picker open करो
                              dateTime();
                            },
                            icon: Icon(
                              Icons.calendar_today_outlined,
                              color: AppConstant.iconColor,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Choose Time Slot :',
                style: GoogleFonts.poppins(
                  color: AppConstant.darkHeadingColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            timeslotList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedTimeslot,
                        items: timeslotList.map((slot) {
                          return DropdownMenuItem<String>(
                            value: slot.timeslot,
                            child: Text(
                              slot.timeslot,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTimeslot = value;
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
                  ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Select the location where you want to Refix Appointment : *',
                style: GoogleFonts.poppins(
                  color: AppConstant.darkHeadingColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Column(
              children: [
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppConstant.borderColor, // Orange border color
                      width: 2, // Border width (adjust as needed)
                    ),
                  ),
                  child: RadioListTile<String>(
                    title: Text(
                      'Office',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppConstant.iconColor,
                      ),
                    ),
                    activeColor: AppConstant.iconColor,
                    // 👈 custom color
                    value: 'Office',
                    groupValue: _location,
                    onChanged: (value) {
                      setState(() {
                        _location = value!;
                      });
                    },
                  ),
                ),
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.orange, // Orange border color
                      width: 2, // Border width (adjust as needed)
                    ),
                  ),
                  child: RadioListTile<String>(
                    title: Text(
                      'Residence',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppConstant.iconColor,
                      ),
                    ),
                    activeColor: AppConstant.iconColor,
                    // 👈 custom color
                    value: 'Residence',
                    groupValue: _location,
                    onChanged: (value) {
                      setState(() {
                        _location = value!;
                      });
                    },
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Select reason for Refix Appointment : *',
                style: GoogleFonts.poppins(
                  color: AppConstant.darkHeadingColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            reasons.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButtonFormField<String>(
                      value: selectedReason,
                      hint: Text(
                        'Select Reason',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppConstant.darkHeadingColor,
                        ),
                      ),
                      items: reasons.map((item) {
                        return DropdownMenuItem<String>(
                          value: item.reason,
                          child: Text(
                            item.reason,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
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
                        labelText: "Reason",
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppConstant.darkButton,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
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

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Enter remarks for Refix Appointment :',
                style: GoogleFonts.poppins(
                  color: AppConstant.darkHeadingColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
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
                    color: AppConstant.darkHeadingColor,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
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
            width: double.infinity, // 👈 full width
            height: 50, // 👈 fixed height
            child: ElevatedButton(
              onPressed: () async {
                print(remark.text);
                if (_location.isEmpty ||
                    selectedReason == null ||
                    currentDate.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please fill all required fields")),
                  );
                  return;
                }

                // ✅ Show loader
                EasyLoading.show(status: 'Please wait...');

                try {
                  final response = await RefixLeadService.submitRefixLead(
                    loginId: uid.toString(),
                    leadId: widget.leadId,
                    newDate: currentDate,
                    newTime: selectedTimeslot ?? "",
                    location: _location,
                    reason: selectedReason!,
                    remark: remark.text,
                  );

                  EasyLoading.dismiss(); // ✅ Hide loader

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(response.message)));

                  if (response.success == 1) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DashboardScreen(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  }
                } catch (e) {
                  EasyLoading.dismiss(); // ✅ Hide loader on error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Something went wrong!")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstant.darkButton, // 👈 button color
                foregroundColor: AppConstant.appTextColor, // 👈 text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // 👈 rounded corners
                ),
                elevation: 4, // 👈 shadow
              ),
              child: Text(
                "Refix Appointment",
                style: GoogleFonts.poppins(
                  fontSize: 15,
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
