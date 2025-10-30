import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_constant.dart';

class GetNotificationScreen extends StatefulWidget {
  const GetNotificationScreen({super.key});

  @override
  State<GetNotificationScreen> createState() => _GetNotificationScreenState();
}

class _GetNotificationScreenState extends State<GetNotificationScreen> {
  String mobile = '';

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  // 🔹 Helper function to format timestamp
  String formatDateTime(String sentTime) {
    try {
      DateTime dt = DateTime.parse(sentTime);
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }

  void loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      mobile = prefs.getString('mobile') ?? '';
    });
  }

  // 🔹 Getter for notificationsRef
  CollectionReference<Map<String, dynamic>> get notificationsRef {
    if (mobile.isEmpty) {
      // temporary empty collection to avoid null error
      return FirebaseFirestore.instance.collection('empty');
    }
    return FirebaseFirestore.instance
        .collection('message')
        .doc(mobile)
        .collection('notifications');
  }

  bool isToday(String sentTime) {
    try {
      final DateTime dt = DateTime.parse(sentTime);
      final now = DateTime.now();
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mobile.isEmpty) {
      // Waiting for SharedPreferences to load
      return Scaffold(
        appBar: AppBar(title: Text("Notifications")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstant.appBarColor,
        title: Text(
          'Today\'s Notifications',
          style: TextStyle(color: AppConstant.appBarWhiteColor, fontSize: 18),
        ),
        iconTheme: IconThemeData(color: AppConstant.appBarWhiteColor),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: notificationsRef
            .orderBy('sentTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🔹 Filter to show only today’s notifications
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            return data['sentTime'] != null && isToday(data['sentTime']);
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text("No notifications for today"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              bool isUnread = data['status'] == 'unread';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: isUnread
                      ? const BorderSide(color: Colors.orange, width: 2)
                      : BorderSide.none,
                ),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppConstant.appBarColor,
                    child: const Icon(
                      Icons.message_outlined,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    data['title'] ?? '',
                    style: TextStyle(
                      fontWeight: isUnread
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['body'] ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        data['sentTime'] != null
                            ? formatDateTime(data['sentTime'])
                            : '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: isUnread
                      ? const Icon(Icons.circle, color: Colors.red, size: 12)
                      : null,
                  // 🔹 Delete button removed
                  onTap: () async {
                    if (isUnread) {
                      await doc.reference.update({'status': 'read'});
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
