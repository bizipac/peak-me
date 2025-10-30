import 'package:flutter/material.dart';

import '../controller/lead_status_services.dart';
import '../model/lead_status_model.dart';
import '../utils/app_constant.dart';

class LeadStatusScreen extends StatefulWidget {
  final String uid;
  final String branchId;
  final LeadService service;

  const LeadStatusScreen({
    Key? key,
    required this.uid,
    required this.branchId,
    required this.service,
  }) : super(key: key);

  @override
  State<LeadStatusScreen> createState() => _LeadStatusScreenState();
}

class _LeadStatusScreenState extends State<LeadStatusScreen> {
  late Future<LeadStatusResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchLeads(widget.uid, widget.branchId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstant.appBarColor,
        title: Text(
          'Today Completed Lead',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
            color: AppConstant.appBarWhiteColor,
          ),
        ),
        iconTheme: IconThemeData(color: AppConstant.appBarWhiteColor),
      ),
      body: FutureBuilder<LeadStatusResponse>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
            return const Center(child: Text("No leads completed today"));
          }
          final result = snapshot.data!;

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      //Text("Total: ${result.total}"),
                      Text("✅ Completed: ${result.completedTotal}"),
                      //Text("⌛ Pending: ${result.pendingTotal}"),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  // ✅ filter only completed leads
                  itemCount: result.data
                      .where((lead) => lead.status == "Completed")
                      .length,
                  itemBuilder: (context, index) {
                    final completedLeads = result.data
                        .where((lead) => lead.status == "Completed")
                        .toList();
                    final lead = completedLeads[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(lead.customerName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("LeadId: ${lead.leadId}"),
                            Text("Date: ${lead.leadDate}"),
                            Text("Location: ${lead.location}"),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            lead.status,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
