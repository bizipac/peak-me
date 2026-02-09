=======API URL===========
BASE_URL="https://fms.bizipac.com/apinew/ws_new/";

#THIS IS USER AUTH URL
POST METHOD
'https://fms.bizipac.com/ws/userverification.php?mobile=6393539704&password=12345678'
RETURN OTP=1234

AFTER OTP ENTER THE THEN LOGIN USER AND FULL AUTHORISE
'https://fms.bizipac.com/ws/userauth.php?mobile=6393539704&password=123455674&userToken=DFDFGDFGD&teamho=1234&imeiNumber=GFRR34DF?'

IF YOU ARE SHOW THE ALL LEAD'S TO HIT THIS API
'https://fms.bizipac.com/apinew/ws_new/new_lead.php?uid=$uid&start=$start&end=$end&branch_id=$branchId&app_version=$app_version&app_type=$appType'

IF YOU ARE SHOW THE LEAD DETAILS BY LEAD TO HIT THIS API
"https://fms.bizipac.com/apinew/ws_new/new_lead_detail.php?lead_id=$leadId"

FETCH THE CHILD EXECUTIVE TO HIT THIS API
https://fms.bizipac.com/apinew/ws_new/childlist.php?parentid=$parentId //PARENTID IT MEANS USER ID

IF YOU ARE REFIX LEAD'S TO HIT THIS URL
"https://fms.bizipac.com/apinew/ws_new/refixlead.php?loginid=$loginId&leadid=$leadId&newdate=$newDate&location=$location&reason=$reason&newtime=$newTime&remark=$remark"

IF YOU ARE POSTPONED LEAD'S TO HIT THIS API
final uri = Uri.parse("https://fms.bizipac.com/apinew/ws_new/postponedlead.php");
final response = await http.post(
uri,
body: {
"loginid": loginId,
"leadid": leadId,
"remark": remark,
"location": location,
"reason": reason,
"newdate": newDate,
"newtime": newTime,
},
);

IF YOU ARE SINGLE LEAD'S TRANSER TO HIT THIS API
'https://fms.bizipac.com/apinew/ws_new/todaystransfered.php?uid=$uid'

IF YOU ARE MULTIPLE LEAD'S TRANSFER TO HIT THIS API
"https://fms.bizipac.com/apinew/ws_new/multipleLeadTransfer.php?leaddata=$payload""

IF ARE CHECK THE COMPLETED LEAD COUNT TO THE USER
'https://fms.bizipac.com/apinew/ws_new/today_completed_lead.php?uid=$uid&branch_id=$branchId'

THIS API USED TO FORGOT PASSWORD AND USER ENTER THE MOBILE NO EXIST OUR DATABASE MATCHING AND SEND
THE USER MOBILE NUMBER ON OTP
'https://fms.bizipac.com/apinew/ws_new/forgotPassword.php'

AFTER OTP PUT AND NEW PASSWORD ENTER THEN SUCCESSFULLY MESSAGE
'https://fms.bizipac.com/apinew/ws_new/userForgotPassword.php?'

ALL THE DOCUMENT HERE THIS API
"https://fms.bizipac.com/apinew/display/document.php"

IF YOU ARE CALLING FUCTION THEN THIS API GET A LEADID AND CALL
""https://fms.bizipac.com/apinew/ws_new/exotel_getnumber.php?lead_id=$leadId""

THIS API STORE THE DOCUMENT IN MYSQL DATABASE
""https://fms.bizipac.com/apinew/ws_new/add_doc_simple.php""

IF YOU ARE FETCH THE TIME_SLOT TO HIT THIS API
"https://fms.bizipac.com/apinew/ws_new/time_slot.php"

IF YOU ARE FETCH THE REASON SO CALL THIS API
"https://fms.bizipac.com/apinew/ws_new/reason.php?leadid=$leadId"

//------------------------main.dart app_version checking
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get_storage/get_storage.dart';
import 'package:peckme/utils/app_constant.dart';
import 'package:peckme/view/auth/login.dart';
import 'package:peckme/view/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.system_update,
                        size: 80,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Please download the latest version ($latestVersion)",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // open Play Store link
                          // e.g. launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=com.example.app"));
                        },
                        child: const Text("Update Now"),
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

//---------------------------------------------------------







