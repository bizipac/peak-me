import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:peckme/services/fcm_service.dart';
import 'package:peckme/services/notification_service.dart';
import 'package:peckme/view/notification/send_notification_screen.dart';
import 'package:peckme/view/profile_screen.dart';
import 'package:peckme/view/received_lead_screen.dart';
import 'package:peckme/view/self_lead_alloter_screen.dart';
import 'package:peckme/view/today_completed_lead_screen.dart';
import 'package:peckme/view/today_transferd_lead_screen.dart';
import 'package:peckme/view/transfer_lead_screen.dart';
import 'package:peckme/view/widget/get_notification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/dashboard_counts_controller.dart';
import '../controller/lead_status_services.dart';
import '../model/dashboard_response_model.dart';
import '../services/get_server_key.dart';
import '../utils/app_constant.dart';
import 'auth/login.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Connectivity _connectivity = Connectivity();
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  bool _isDialogShowing = false; // track karega dialog chal raha hai ya nahi

  String name = '';
  String mobile = '';
  String uid = '';
  String rolename = '';
  String roleId = '';
  String branchId = '';
  String branch_name = '';
  String authId = '';
  String image = '';
  String address = '';

  void openIciciActivity() async {
    final intent = AndroidIntent(
      componentName: 'com.bcpl.icici.IciciActivity', // AAR वाली Activity
      package: 'com.example.peckme', // ⚠️ यह आपके app का packageName होना चाहिए
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    await intent.launch();
  }

  Future<DashboardResponse>? _dashboardFuture;
  final _service = DashboardService();

  void loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? '';
      mobile = prefs.getString('mobile') ?? '';
      uid = prefs.getString('uid') ?? '';
      rolename = prefs.getString('rolename') ?? '';
      roleId = prefs.getString('roleId') ?? '';
      branchId = prefs.getString('branchId') ?? '';
      branch_name = prefs.getString('branch_name') ?? '';
      authId = prefs.getString('authId') ?? '';
      image = prefs.getString('image') ?? '';
      address = prefs.getString('address') ?? '';
      // Pehle local data check karo
      final localData = _service.getStoredDashboard();
      if (localData != null) {
        // Agar local data hai to usko future bana ke assign karo
        _dashboardFuture = Future.value(localData);

        // Saath hi API call background me karo
        _service.fetchDashboardCounts(uid: uid).then((freshData) {
          setState(() {
            _dashboardFuture = Future.value(freshData);
          });
        });
      } else {
        // Agar local data nahi hai to direct API call karo
        _dashboardFuture = DashboardService().fetchDashboardCounts(uid: uid);
      }
    });
  }

  DateTime _currentTime = DateTime.now();

  // A Timer variable to control the  periodic updates.
  late Timer _timer;

  //user permission allow
  NotificationService notificationService = NotificationService();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    notificationService.requestNotificationPermission();
    FCMService.firebaseInit();
    notificationService.firebaseInit(context);
    notificationService.setupInteractMessage(context);

    loadUserData();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
    _checkConnection();
    // Listen continuously
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;

      setState(() {
        _connectionStatus = result;
      });

      if (result == ConnectivityResult.none) {
        _showNoInternetDialog();
      } else {
        _closeDialogIfOpen();
      }
    });
  }

  Future<void> _checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    setState(() {
      _connectionStatus = result as ConnectivityResult;
    });

    if (result == ConnectivityResult.none) {
      _showNoInternetDialog();
    }
  }

  void _launchInBrowser(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showNoInternetDialog() {
    if (!_isDialogShowing && mounted) {
      _isDialogShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text("No Internet"),
            content: const Text(
              "Your internet is off. Please check WiFi or Mobile Data.",
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  _isDialogShowing = false;
                  Navigator.of(context).pop();

                  // ✅ Close the app
                  if (Platform.isAndroid) {
                    SystemNavigator.pop(); // Android style close
                  } else if (Platform.isIOS) {
                    exit(
                      0,
                    ); // iOS में यह Apple guideline के खिलाफ है, लेकिन काम करेगा
                  } else {
                    exit(0); // fallback
                  }
                },
                child: const Text("Retry & Exit"),
              ),
            ],
          );
        },
      ).then((_) {
        _isDialogShowing = false;
      });
    }
  }

  void _closeDialogIfOpen() {
    if (_isDialogShowing && Navigator.canPop(context)) {
      Navigator.of(context).pop(); // close dialog
      _isDialogShowing = false;
    }
  }

  String getConnectionType() {
    switch (_connectionStatus) {
      case ConnectivityResult.wifi:
        return "✅ Connected via WiFi";
      case ConnectivityResult.mobile:
        return "✅ Connected via Mobile Data";
      case ConnectivityResult.none:
        return "❌ No Internet";
      default:
        return "Unknown";
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String timeString =
        '${_currentTime.hour.toString().padLeft(2, '0')}:'
        '${_currentTime.minute.toString().padLeft(2, '0')}:'
        '${_currentTime.second.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: AppConstant.appBarColor,
        title: Text(
          "Peak Me ",
          style: TextStyle(color: AppConstant.appBarWhiteColor),
        ),
        actions: [
          mobile.isEmpty
              ? IconButton(
                  onPressed: null,
                  icon: Icon(
                    Icons.message_outlined,
                    color: AppConstant.appBarWhiteColor,
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('message')
                      .doc(
                        mobile.isEmpty ? 'temp' : mobile,
                      ) // avoid invalid doc
                      .collection('notifications')
                      .where('status', isEqualTo: 'unread')
                      .orderBy('sentTime', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = 0;
                    if (snapshot.hasData) {
                      // 🔹 Filter only today's notifications
                      final now = DateTime.now();
                      final todayDocs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['sentTime'] == null) return false;

                        try {
                          final sentTime = DateTime.parse(data['sentTime']);
                          return sentTime.year == now.year &&
                              sentTime.month == now.month &&
                              sentTime.day == now.day;
                        } catch (e) {
                          return false;
                        }
                      }).toList();

                      count = todayDocs.length;
                    }

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () {
                            Get.to(() => GetNotificationScreen());
                          },
                          icon: Icon(
                            Icons.message_outlined,
                            color: AppConstant.appBarWhiteColor,
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 15,
                                minHeight: 10,
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

          IconButton(
            onPressed: () {
              Get.to(() => ProfileScreen());
            },
            icon: Icon(Icons.person_pin, color: AppConstant.appBarWhiteColor),
          ),
          IconButton(
            onPressed: () async {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(
                    "Logout",
                    style: TextStyle(
                      fontSize: 20,
                      color: AppConstant.whiteBackColor,
                    ),
                  ),
                  content: Text(
                    "are you sure you want to logout of your account?",
                    style: TextStyle(color: AppConstant.whiteBackColor),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                      icon: Text(
                        'No',
                        style: TextStyle(color: AppConstant.whiteBackColor),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        Get.offAll(() => Login());
                      },
                      icon: Text(
                        'Yes',
                        style: TextStyle(color: AppConstant.whiteBackColor),
                      ),
                    ),
                  ],
                  elevation: 10,
                  backgroundColor: AppConstant.darkButton,
                ),
              );
            },
            icon: Icon(Icons.logout, color: AppConstant.appBarWhiteColor),
            onLongPress: () async {
              // 1️⃣ Fetch server key first
              GetServerKey getServerKey = GetServerKey();
              String? serverKey = await getServerKey.getServerKeyToken();
              print("----------------------");
              print(serverKey);
              print("------------------------");

              // 2️⃣ Show password dialog
              TextEditingController _passwordController =
                  TextEditingController();
              bool passwordCorrect = false;

              await showDialog(
                context: context,
                barrierDismissible: false, // user must tap OK or Cancel
                builder: (context) {
                  return AlertDialog(
                    title: Text("Enter Password"),
                    content: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(hintText: "Password"),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Cancel pressed
                        },
                        child: Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_passwordController.text.trim() == "#8090#") {
                            passwordCorrect = true;
                            Navigator.of(context).pop();
                          } else {
                            // Optional: show error
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Incorrect password")),
                            );
                          }
                        },
                        child: Text("OK"),
                      ),
                    ],
                  );
                },
              );

              // 3️⃣ Navigate only if password correct
              if (passwordCorrect) {
                Get.to(() => SendMessageScreen(serverKeys: serverKey));
              }
            },
          ),
        ],
      ),
      // drawer: AdminDrawerWidget(),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white24,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      height: 125,
                      width: 150,
                      decoration: BoxDecoration(
                        color: AppConstant.whiteBackColor,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: AppConstant.borderColor,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          Get.to(() => ReceivedLeadScreen());
                        },
                        child: Stack(
                          children: [
                            // Inner shadow overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.orange.withOpacity(0.16),
                                      // inner shadow feel
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Actual content
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.dashboard,
                                    size: 30,
                                    color: AppConstant.iconColor,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Pending Lead's",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppConstant.darkHeadingColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 125,
                      width: 150,
                      decoration: BoxDecoration(
                        color: AppConstant.whiteBackColor,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: AppConstant.borderColor,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () async {
                          Get.to(() => TransferLeadScreen());
                        },
                        child: Stack(
                          children: [
                            // Inner shadow overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.orange.withOpacity(0.16),
                                      // inner shadow feel
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Actual content
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.transfer_within_a_station_outlined,
                                    size: 30,
                                    color: AppConstant.iconColor,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Transfer Lead's",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppConstant.darkHeadingColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      height: 125,
                      width: 150,
                      decoration: BoxDecoration(
                        color: AppConstant.whiteBackColor,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: AppConstant.borderColor,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          Get.to(
                            () => LeadCheckScreen(uid: uid, branchId: branchId),
                          );
                        },
                        child: Stack(
                          children: [
                            // Inner shadow overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.orange.withOpacity(0.16),
                                      // inner shadow feel
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Actual content
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.wallet,
                                    size: 30,
                                    color: AppConstant.iconColor,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Self Lead's Alloter",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppConstant.darkHeadingColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 125,
                      width: 150,
                      decoration: BoxDecoration(
                        color: AppConstant.whiteBackColor,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: AppConstant.borderColor,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () async {
                          _launchInBrowser(
                            'https://fms.bizipac.com/apinew/secureapi/icici_pre_paid_card_gen.php?user_id=$uid&branch_id=$branchId#!/',
                          );
                        },
                        child: Stack(
                          children: [
                            // Inner shadow overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.orange.withOpacity(0.16),
                                      // inner shadow feel
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Actual content
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.card_travel_outlined,
                                    size: 30,
                                    color: AppConstant.iconColor,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Submission's",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppConstant.darkHeadingColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      height: 125,
                      width: 150,
                      decoration: BoxDecoration(
                        color: AppConstant.whiteBackColor,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: AppConstant.borderColor,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          final service = LeadService(
                            baseUrl: "https://fms.bizipac.com/apinew/ws_new",
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LeadStatusScreen(
                                uid: uid,
                                branchId: branchId,
                                service: service,
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            // Inner shadow overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.orange.withOpacity(0.16),
                                      // inner shadow feel
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Actual content
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.file_copy_outlined,
                                    size: 30,
                                    color: AppConstant.iconColor,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Today's Completed \nLead's",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppConstant.darkHeadingColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 125,
                      width: 150,
                      decoration: BoxDecoration(
                        color: AppConstant.whiteBackColor,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: AppConstant.borderColor,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () async {
                          Get.to(
                            () => TodayTransferredScreen(uid: uid.toString()),
                          );
                        },
                        child: Stack(
                          children: [
                            // Inner shadow overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.orange.withOpacity(0.16),
                                      // inner shadow feel
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Actual content
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.transfer_within_a_station_outlined,
                                    size: 30,
                                    color: AppConstant.iconColor,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Today Transfer \n Lead's",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppConstant.darkHeadingColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Center(
                        child: Text(
                          "Dashboard",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final localData = _service.getStoredDashboard();
                          if (localData != null) {
                            // Agar local data hai to usko future bana ke assign karo
                            _dashboardFuture = Future.value(localData);

                            // Saath hi API call background me karo
                            _service.fetchDashboardCounts(uid: uid).then((
                              freshData,
                            ) {
                              setState(() {
                                _dashboardFuture = Future.value(freshData);
                              });
                            });
                          } else {
                            // Agar local data nahi hai to direct API call karo
                            _dashboardFuture = DashboardService()
                                .fetchDashboardCounts(uid: uid);
                          }
                        },
                        icon: Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Divider(),
                ),
                FutureBuilder<DashboardResponse>(
                  future: _dashboardFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else if (snapshot.hasData &&
                        snapshot.data!.success == 1 &&
                        snapshot.data!.data != null) {
                      final data = snapshot.data!.data!;
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Table(
                          border: TableBorder.all(
                            color: AppConstant.borderColor,
                            width: 2,
                          ),
                          // optional border
                          columnWidths: const {
                            0: FlexColumnWidth(2), // first column (label)
                            1: FlexColumnWidth(1), // second column (value)
                          },
                          children: [
                            TableRow(
                              children: [
                                TableCell(
                                  child: Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "Pending Leads",
                                          style: TextStyle(
                                            color: AppConstant.darkButton,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      // Inner shadow overlay
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                                  Colors.transparent,
                                                  Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                                ],
                                                stops: [0.0, 0.5, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TableCell(
                                  child: Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Center(
                                          child: Text(
                                            "${data.totalPending}",
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                                  Colors.transparent,
                                                  Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                                ],
                                                stops: [0.0, 0.5, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            TableRow(
                              children: [
                                TableCell(
                                  child: Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "MTD Completed Leads",
                                          style: TextStyle(
                                            color: AppConstant.darkButton,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                                  Colors.transparent,
                                                  Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                                ],
                                                stops: [0.0, 0.5, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TableCell(
                                  child: Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Center(
                                          child: Text(
                                            "${data.totalMTD}",
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                                  Colors.transparent,
                                                  Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                                ],
                                                stops: [0.0, 0.5, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            TableRow(
                              children: [
                                TableCell(
                                  child: Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "EOD Completed Leads",
                                          style: TextStyle(
                                            color: AppConstant.darkButton,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                                  Colors.transparent,
                                                  Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                                ],
                                                stops: [0.0, 0.5, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TableCell(
                                  child: Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Center(
                                          child: Text(
                                            "${data.totalCompleted}",
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                                  Colors.transparent,
                                                  Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                                ],
                                                stops: [0.0, 0.5, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    } else {
                      return const Center(child: Text("No data found"));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 👇 Time Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Current Time : ".toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  timeString,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.normal,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(Icons.access_time, size: 10, color: AppConstant.iconColor),
              ],
            ),

            // 👇 Version Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Version : ",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  AppConstant.appVersion,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.normal,
                    color: AppConstant.appIconColor,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.verified_outlined,
                  size: 10,
                  color: AppConstant.iconColor,
                ),
              ],
            ),

            // 👇 Copyright Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Copyrights © 2025 All Rights Reserved by - ",
                          maxLines: 2,
                          style: TextStyle(fontSize: 9),
                        ),
                        Text(
                          "Bizipac Couriers Pvt. Ltd.",
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 9,
                            color: AppConstant.darkButton,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 👇 Postpone Lead Button
          ],
        ),
      ),
    );
  }
}
