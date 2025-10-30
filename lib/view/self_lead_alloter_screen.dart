import 'package:flutter/material.dart';
import 'package:peckme/controller/self_lead_alloter.dart';

import '../handler/EncryptionHandler.dart';
import '../model/self_lead_model.dart';
import '../utils/app_constant.dart';

class LeadCheckScreen extends StatefulWidget {
  final String uid;
  final String branchId;

  const LeadCheckScreen({Key? key, required this.uid, required this.branchId})
    : super(key: key);

  @override
  State<LeadCheckScreen> createState() => _LeadCheckScreenState();
}

class _LeadCheckScreenState extends State<LeadCheckScreen> {
  final TextEditingController _mobileController = TextEditingController();
  SelfLeadResponse? _lead;
  bool _loading = false;
  SelfLeadAlloterService selfLeadAlloterService = SelfLeadAlloterService();

  Future<void> _checkLead() async {
    setState(() => _loading = true);

    try {
      final lead = await selfLeadAlloterService.checkLead(
        _mobileController.text.trim(),
        widget.branchId,
        widget.uid,
      );
      print(lead);

      setState(() {
        _lead = lead;
        _loading = false;
      });

      if (lead != null) {
        // ✅ Lead exists
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("")));
      } else {
        // ❌ Lead not found
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("❌ Lead not found ")));
      }
    } catch (e) {
      setState(() => _loading = false);

      // 🚨 API or service error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  Future<void> _assignLead() async {
    if (_lead == null) return;
    setState(() => _loading = true);
    final success = await selfLeadAlloterService.assignLead(
      _lead!.data.first.mobile,
      widget.uid,
      widget.branchId,
    );
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? "Lead assigned ✅" : "Failed to assign lead ❌"),
      ),
    );
    if (success) {
      setState(() => _lead = null);
      _mobileController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstant.appBarColor,
        title: Text(
          "Self Lead's Alloter",
          style: TextStyle(color: AppConstant.appBarWhiteColor, fontSize: 17),
        ),
        iconTheme: IconThemeData(color: AppConstant.appBarWhiteColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _mobileController,
              decoration: InputDecoration(
                labelText: "Enter Mobile Number",
                labelStyle: TextStyle(color: AppConstant.darkHeadingColor),
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
                suffixIcon: IconButton(
                  icon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.search, color: AppConstant.iconColor),
                  onPressed: _loading ? null : _checkLead,
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),

            // ✅ UI condition handling
            // ✅ UI condition handling
            if (_lead != null) ...[
              if (_lead!.data.isNotEmpty)
                Expanded(
                  // 👈 scroll support
                  child: ListView.builder(
                    itemCount: _lead!.data.length,
                    itemBuilder: (context, index) {
                      final leadItem = _lead!.data[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          // 🔹 rounded corners
                          side: BorderSide(
                            color: AppConstant.borderColor, // 🔹 border color
                            width: 2, // 🔹 border width
                          ),
                        ),
                        elevation: 4, // 🔹 shadow effect
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12), // 🔹 inner padding
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              decryptFMS(
                                leadItem.customerName,
                                "QWRTEfnfdys635",
                              ).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                // 🔹 bigger font
                                fontWeight: FontWeight.bold,
                                fontFamily: "Roboto",
                                // 🔹 custom font-family (change if needed)
                                color: AppConstant.darkHeadingColor,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  "Lead ID: ${leadItem.leadId}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  "Mobile: ${leadItem.mobile}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  "Status Id: ${leadItem.statusId}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  "Branch: ${leadItem.branchId}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstant.darkButton,
                                foregroundColor: AppConstant.whiteBackColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: _loading
                                  ? null
                                  : () async {
                                      setState(() => _loading = true);
                                      final success =
                                          await selfLeadAlloterService
                                              .assignLead(
                                                leadItem.mobile,
                                                widget.uid,
                                                widget.branchId,
                                              );
                                      setState(() => _loading = false);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? "Lead ${leadItem.leadId} assigned ✅"
                                                : "Failed to assign ❌",
                                          ),
                                        ),
                                      );
                                    },
                              child: const Text("Accept"),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                const Text(
                  "❌ No leads found",
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
