import 'package:flutter/material.dart';
import '../controller/search_lead_controller.dart';
import '../model/new_lead_model.dart';
import '../utils/app_constant.dart';

class SearchLeadScreen extends StatefulWidget {
  const SearchLeadScreen({Key? key}) : super(key: key);

  @override
  State<SearchLeadScreen> createState() => _SearchLeadScreenState();
}

class _SearchLeadScreenState extends State<SearchLeadScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchType = "lead_id"; // default search type
  List<Lead> searchedLeads = [];
  bool isLoading = false;

  void _searchLead() async {
    setState(() {
      isLoading = true;
      searchedLeads.clear();
    });

    final leads = await LeadService.searchLead(
      searchType,
      searchController.text.trim(),
    );

    setState(() {
      searchedLeads = leads;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstant.appInsideColor,
        title: Text(
          'Search Lead',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color:  AppConstant.appTextColor,
          ),
        ),
        iconTheme: IconThemeData(color: AppConstant.appIconColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔹 Dropdown to choose search type
            Row(
              children: [
                const Text("Search by: "),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: searchType,
                  items: const [
                    DropdownMenuItem(
                        value: "lead_id", child: Text("Lead ID",style: TextStyle(fontSize: 14,fontFamily: "impact"),)),
                    // DropdownMenuItem(
                    //     value: "mobile", child: Text("Mobile Number",style: TextStyle(fontSize: 14,),)),
                  ],
                  onChanged: (value) {
                    setState(() => searchType = value!);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 🔹 TextField
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: searchType == "lead_id"
                    ? "Enter Lead ID"
                    : "Enter Mobile Number",
                border: const OutlineInputBorder(),
              ),
              keyboardType: searchType == "lead_id"
                  ? TextInputType.number
                  : TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // 🔹 Search Button
            ElevatedButton(
              onPressed: _searchLead,
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                elevation: 5,
                shadowColor: Colors.black54,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.search, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Search",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(),

            // 🔹 Show Result
            if (isLoading) const CircularProgressIndicator(),
            if (!isLoading && searchedLeads.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: searchedLeads.length,
                  itemBuilder: (context, index) {
                    final lead = searchedLeads[index];
                    return Card(
                      child: ListTile(
                        title: Text(lead.customerName),
                        subtitle: Text(
                              "Lead ID: ${lead.leadId}\n"
                              "Client: ${lead.clientname}",
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (!isLoading && searchedLeads.isEmpty)
              const Text(
                "No lead found",
                style: TextStyle(color: Colors.black),
              ),
          ],
        ),
      ),
    );
  }
}
