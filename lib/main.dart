import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart';
import 'package:peckme/services/notification_service.dart';
import 'package:peckme/utils/app_constant.dart';
import 'package:peckme/view/auth/login.dart';
import 'package:peckme/view/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controller/version_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GetStorage.init();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    runApp(MyApp());
  });
  final notificationService = NotificationService();
  notificationService.firebaseInit(context as BuildContext);
  notificationService.setupInteractMessage(context as BuildContext);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    return uid != null && uid.isNotEmpty;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final localVersion = AppConstant.appVersion; // e.g. v1.1.2
    print("App Version (local): $localVersion");

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Peak Me',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      builder: EasyLoading.init(),
      home: FutureBuilder<String?>(
        future: VersionService.fetchLatestVersion(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Unable to verify app version."));
          }

          final latestVersion = snapshot.data!;
          print("Latest Version (server): $latestVersion");

          if (localVersion != latestVersion) {
            // 🔴 Version mismatch → Show update message
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.system_update,
                        size: 80,
                        color: AppConstant.appBarColor,
                      ),
                      Text(
                        "You are using the current version ($localVersion)",
                        style: TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        "Please download the latest version ($latestVersion). \n Click on the download button and download the latest version.\n",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          // open Play Store link
                          launchUrl(
                            Uri.parse(
                              "https://drive.google.com/drive/folders/1cW5XkhTHqU-rZFnWnRra4DM5EJ6cgFOF?usp=drive_link",
                            ),
                          );
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            // prevent dismiss by tapping outside
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("Update Required"),
                                content: const Text(
                                  "Your app version is outdated.\n\n"
                                  "Please contact your Head Office and Branch Manager.\n"
                                  "Uninstall the old version and download the latest version.\n\n"
                                  "The app will now close.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      // Close the dialog first
                                      Navigator.of(context).pop();

                                      // Then close the app
                                      SystemNavigator.pop(); // safe way to close the app
                                    },
                                    child: const Text("OK"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text("Download"),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // ✅ Version matched → proceed to login/dashboard
          return FutureBuilder<bool>(
            future: isLoggedIn(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData && snapshot.data == true) {
                return DashboardScreen();
              } else {
                return Login();
              }
            },
          );
        },
      ),
    );
  }
}
