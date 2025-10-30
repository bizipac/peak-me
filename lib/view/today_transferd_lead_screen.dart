import 'package:flutter/material.dart';

import '../controller/today_transfer_controller.dart';
import '../model/today_transfer_lead_model.dart';
import '../utils/app_constant.dart';

class TodayTransferredScreen extends StatefulWidget {
  final String uid;

  TodayTransferredScreen({super.key, required this.uid});

  @override
  State<TodayTransferredScreen> createState() => _TodayTransferredScreenState();
}

class _TodayTransferredScreenState extends State<TodayTransferredScreen> {
  late Future<TodayTransferredResponse?> _future;

  @override
  void initState() {
    super.initState();

    _future = fetchTodayTransferred(widget.uid); // <-- Change UID as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: AppConstant.appBarWhiteColor),
        backgroundColor: AppConstant.appBarColor,
        title: Text(
          'Today\'s Transfers',
          style: TextStyle(
            color: AppConstant.appBarWhiteColor,
            fontWeight: FontWeight.normal,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<TodayTransferredResponse?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              snapshot.data == null ||
              !snapshot.data!.success) {
            return const Center(child: Text('No data found or API failed.'));
          }
          final dataList = snapshot.data!.data;
          print(dataList.toString());

          return ListView.builder(
            itemCount: dataList.length,
            itemBuilder: (context, index) {
              final item = dataList[index];
              return item == ''
                  ? Center(
                      child: Text(
                        "No data",
                        style: TextStyle(color: Colors.black, fontSize: 20),
                      ),
                    )
                  : Card(
                      elevation: 5,
                      color: AppConstant.whiteBackColor,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Rounded corners
                        side: BorderSide(
                          color: AppConstant.borderColor, // Border color
                          width: 2, // Border width
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          item.customerName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppConstant.darkButton,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  "Executive :",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppConstant.darkHeadingColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  // Fixes overflow
                                  child: Text(
                                    item.executive,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  "Total Transfered :",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppConstant.darkHeadingColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  // Fixes overflow
                                  child: Text(
                                    item.totalTransfered.toString(),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  "Total Refixed :",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppConstant.darkHeadingColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  // Fixes overflow
                                  child: Text(
                                    item.totalRefixed.toString(),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  "Total Postponed :",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppConstant.darkHeadingColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  // Fixes overflow
                                  child: Text(
                                    item.totalPostponed.toString(),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  "Total Collected :",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppConstant.darkHeadingColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  // Fixes overflow
                                  child: Text(
                                    item.totalCollected.toString(),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
            },
          );
        },
      ),
    );
  }
}
