import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

class GetDeviceTokenController extends GetxController {
  String? userToken;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    getFcmToken();
  }

  void getFcmToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    userToken = token;
    print("FCM Token: $token");
  }
}
