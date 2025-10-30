import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../services/get_server_key.dart';
import '../../utils/app_constant.dart';

class SendMessageScreen extends StatefulWidget {
  final String serverKeys;

  SendMessageScreen({super.key, required this.serverKeys});

  @override
  State<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  String? selectedBranch;
  String? selectedUser;
  bool isImage = false;
  File? image;

  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  List<Map<String, dynamic>> selectedUsers = [];

  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  /// 🔹 Firestore से सभी users load करना
  void _loadUsers() {
    FirebaseFirestore.instance.collection('users').snapshots().listen((snap) {
      setState(() {
        allUsers = snap.docs
            .map((doc) => doc.data())
            .toList()
            .cast<Map<String, dynamic>>();
        filteredUsers = allUsers;
      });
    });
  }

  /// 🔹 Branch filter
  void _filterUsersByBranch(String branch) {
    setState(() {
      selectedBranch = branch;
      filteredUsers = allUsers
          .where((u) => u['branch_name'] == branch)
          .toList();
      selectedUsers.clear();
    });
  }

  /// 🔹 Multiple Users को message भेजना
  Future<void> _sendMessage() async {
    if (selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select at least one user")),
      );
      return;
    }

    for (var user in selectedUsers) {
      String token = user['userToken'];
      await sendFcmMessageWithOAuth(
        token,
        titleController.text,
        bodyController.text,
      );
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Message Sent!")));
  }

  /// 🔹 FCM Notification Send Function
  Future<void> sendFcmMessageWithOAuth(
    String token,
    String title,
    String body,
  ) async {
    GetServerKey getServerKey = GetServerKey();
    String? serverKey = await getServerKey.getServerKeyToken();
    final response = await http.post(
      Uri.parse(
        "https://fcm.googleapis.com/v1/projects/bizipac-6bb00/messages:send",
      ),
      headers: {
        "Authorization": "Bearer $serverKey",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "message": {
          "token": token,
          "notification": {"title": title, "body": body},
        },
      }),
    );
    print("FCM Response (v1 OAuth): ${response.body}");
  }

  Future pickImage(ImageSource source) async {
    setState(() => isImage = true);
    final img = await _pickAndUploadImage(source);
    setState(() {
      isImage = false;
      if (img != null) {
        image = img;
      }
    });
  }

  Future<File?> _pickAndUploadImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return null;
      File? img = File(image.path);
      // // Wait for cropped image from CustomCropScreen
      return img;
    } catch (e) {
      print("❌ Error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstant.appBarColor,
        title: Text(
          "Send Message",
          style: TextStyle(color: AppConstant.whiteBackColor),
        ),
        iconTheme: IconThemeData(color: AppConstant.whiteBackColor),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 🔹 Branch Filter Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Select Branch",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  value: selectedBranch,
                  items: allUsers
                      .map((u) => (u['branch_name'] ?? '').toString())
                      .toSet()
                      .map(
                        (branch) => DropdownMenuItem<String>(
                          value: branch,
                          child: Text(branch),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => _filterUsersByBranch(value!),
                ),
              ),

              // 🔹 Select All / Clear Buttons + Users List
              if (selectedBranch != null && selectedBranch!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                selectedUsers = List.from(filteredUsers);
                              });
                            },
                            child: const Text(
                              "Select All",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                selectedUsers.clear();
                              });
                            },
                            child: const Text(
                              "Clear",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView(
                          children: filteredUsers.map((u) {
                            final userId = (u['UserId'] ?? '').toString();
                            bool isSelected = selectedUsers.any(
                              (sel) => (sel['UserId'] ?? '') == userId,
                            );
                            return CheckboxListTile(
                              title: Text(
                                "$userId - ${u['branch_name'] ?? ''}",
                                style: TextStyle(fontSize: 12),
                              ),
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    if (!selectedUsers.any(
                                      (sel) => (sel['UserId'] ?? '') == userId,
                                    )) {
                                      selectedUsers.add(u);
                                    }
                                  } else {
                                    selectedUsers.removeWhere(
                                      (sel) => (sel['UserId'] ?? '') == userId,
                                    );
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

              // 🔹 Message Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Message Title",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.title, color: Colors.blue),
                  ),
                ),
              ),

              // 🔹 Message Body
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: TextField(
                  controller: bodyController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Message Body",
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.message, color: Colors.blue),
                  ),
                ),
              ),

              // 🔹 Send Message Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _sendMessage,
                    icon: Icon(Icons.send, color: Colors.white),
                    label: Text(
                      "Send Message",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
