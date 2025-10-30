import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../../controller/auth_controller.dart';
import '../../controller/get_device_token_controller.dart';
import '../../controller/otp_controller.dart';
import '../../utils/app_constant.dart';
import 'forgot.dart';

class Login extends StatefulWidget {
  Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final Connectivity _connectivity = Connectivity();
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  bool _isDialogShowing = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GetDeviceTokenController token = Get.put(GetDeviceTokenController());
  final AuthService _authService = Get.put(AuthService());
  late String userId;
  late String password;
  late String userOtp;
  bool _obscurePassword = true;

  String _deviceInfo = '';

  //genrate otp
  String genrateOtp() {
    var random = Random();
    int otp = 1000 + random.nextInt(9999);
    return otp.toString();
  }

  String _publicIp = "Fetching...";

  Future<String> getPublicIP() async {
    final response = await http.get(
      Uri.parse('https://api.ipify.org?format=json'),
    );

    if (response.statusCode == 200) {
      // Parse the JSON response
      var data = json.decode(response.body);
      return data['ip']; // Return the public IP address
    } else {
      throw Exception('Failed to load IP');
    }
  }

  Future<void> _loadIp() async {
    try {
      String ip = await getPublicIP();
      setState(() {
        _publicIp = ip;
      });
    } catch (e) {
      setState(() {
        _publicIp = "Error: $e";
      });
    }
  }

  //genrate IMEI id
  Future<void> _getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

    String info = '';

    if (Platform.isAndroid) {
      // Request runtime permission
      var status = await Permission.phone.request();

      if (status.isGranted) {
        AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
        info = androidInfo.id.toString();
      } else {
        info = 'Phone permission not granted';
      }
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      info =
          '''
      NAME: ${iosInfo.name}
      SYSTEM NAME: ${iosInfo.systemName}
      SYSTEM VERSION: ${iosInfo.systemVersion}
      MODEL: ${iosInfo.model}
      IDENTIFIER FOR VENDOR: ${iosInfo.identifierForVendor}
      ''';
    }

    setState(() {
      _deviceInfo = info;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _getDeviceInfo();
    _checkConnection();
    _loadIp();
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

  String responseMsg = '';

  void requestOtp() async {
    final mobile = userId.trim();
    final upassword = password.trim();

    if (mobile.isNotEmpty && upassword.isNotEmpty) {
      final result = await OtpService.getOtp(
        mobile: mobile,
        upassword: upassword,
      );
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      var docRef = firestore.collection("users").doc(userId);
      await docRef.set({
        "UserId": mobile,
        "Password": password,
        "OTP": result.message.toString(),
        "dateTime": DateTime.now(),
      });
      print('otp : ${result.message.toString()}');
      setState(() {
        if (result.success == 1) {
          Get.snackbar(
            "Send OTP!",
            "please enter the 4 digit !!!", //otp ${result.message.toString()}

            icon: Image.asset(
              "assets/logo/cmp_logo.png",
              height: 30,
              width: 30,
            ),
            shouldIconPulse: true,
            // Small animation on the icon
            backgroundColor: AppConstant.snackBackColor,
            colorText: AppConstant.snackFontColor,
            snackPosition: SnackPosition.BOTTOM,
            // or TOP
            borderRadius: 15,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            duration: const Duration(seconds: 3),
            isDismissible: true,
            forwardAnimationCurve: Curves.easeOutBack,
          );
          showCustomBottomSheet(
            userId,
            token.userToken.toString(),
            result.message.toString(),
          );
        } else {
          Get.snackbar(
            "Oops!",
            "your userId and password does not exist in my database so please connect to the office, Thank You!!",
            icon: Image.asset(
              "assets/logo/cmp_logo.png",
              height: 30,
              width: 30,
            ),
            shouldIconPulse: true,
            // Small animation on the icon
            backgroundColor: AppConstant.snackBackColor,
            colorText: AppConstant.snackFontColor,
            snackPosition: SnackPosition.TOP,
            // or TOP
            borderRadius: 5,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            duration: const Duration(seconds: 3),
            isDismissible: true,
            forwardAnimationCurve: Curves.easeOutBack,
          );
        }
      });
    } else {
      setState(() {
        responseMsg = 'Please enter both fields';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SafeArea(
            child: Stack(
              children: [
                SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            SizedBox(height: 30),
                            Container(
                              height: 200,
                              child: Image.asset(
                                'assets/logo/logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(height: 10),

                            //Text("Device ID: ${_deviceInfo.toString()}"),
                            //Text("Public IP: $_publicIp"),
                            Divider(thickness: 2, height: 40),
                            Row(
                              children: [
                                Text(
                                  'Login ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: AppConstant.appFontFamily,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(
                                  Icons.login_rounded,
                                  color: AppConstant.iconColor,
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              onChanged: (value) {
                                userId = value;
                              },
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'enter your password';
                                } else {
                                  return null;
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'UserId',
                                labelStyle: TextStyle(
                                  color: AppConstant.appTextColor,
                                  fontSize: 12,
                                ),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppConstant.borderColor,
                                  ), // border when not focused
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppConstant.borderColor,
                                    width: 2.0,
                                  ), // border when focused
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              keyboardType: TextInputType.text,
                              onChanged: (value) {
                                password = value;
                              },
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Enter your password';
                                } else {
                                  return null;
                                }
                              },
                              obscureText: _obscurePassword,
                              // 👈 use state variable
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                  color: AppConstant.appTextColor,
                                  fontSize: 12,
                                ),
                                border: const OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppConstant.borderColor,
                                  ), // border when not focused
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppConstant.borderColor,
                                    width: 2.0,
                                  ), // border when focused
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return ForgotPasswordScreen();
                                      },
                                    ),
                                  );
                                },
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: AppConstant.darkButton,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            InkWell(
                              onTap: () async {
                                if (_formKey.currentState!.validate()) {
                                  requestOtp();
                                } else {}
                              },
                              child: Container(
                                height: 50,
                                width: 330,
                                decoration: BoxDecoration(
                                  color: AppConstant.darkButton,
                                  borderRadius: BorderRadius.circular(10),
                                ),

                                child: Center(
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      color: AppConstant.darkTextColor,
                                      fontSize: 16,
                                      fontFamily: AppConstant.appTextFamily,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Copyrights © 2025 All Rights Reserved by - ",
                                        maxLines: 2,
                                        style: TextStyle(
                                          fontSize: 7,
                                          color: AppConstant.appTextColor,
                                        ),
                                      ),
                                      Text(
                                        "Bizipac Couriers Pvt. Ltd.",
                                        maxLines: 2,
                                        style: TextStyle(
                                          fontSize: 7,
                                          color: AppConstant.darkButton,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Version - ${AppConstant.appVersion}",
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showCustomBottomSheet(
    String userId,
    String userDiviceToken,
    String newOtp,
  ) {
    Get.bottomSheet(
      Container(
        height: Get.height / 0.5,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    Text(
                      'Send To :  +91-${userId.toString()}',
                      style: TextStyle(color: AppConstant.appTextColor),
                    ),
                    //Text('OTP : - ${newOtp}'),
                    // Text('Token: ${userDiviceToken.toString()}')
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 20.0,
                ),
                child: Container(
                  height: 55.0,
                  child: TextFormField(
                    onChanged: (value) {
                      userOtp = value;
                    },
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: 'Enter OTP',
                      labelStyle: TextStyle(
                        color: AppConstant.appTextColor,
                        fontSize: 12,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                      hintStyle: TextStyle(fontSize: 12),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppConstant.borderColor,
                        ), // border when not focused
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppConstant.borderColor,
                          width: 2.0,
                        ), // border when focused
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Material(
                  child: Container(
                    width: Get.width / 2.0,
                    height: Get.height / 10,

                    decoration: BoxDecoration(
                      color: AppConstant.darkButton,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: TextButton(
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: AppConstant.darkTextColor,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () async {
                        String otp = userOtp;
                        String message = '';
                        late String name;
                        if (otp == newOtp) {
                          final result = await AuthService.login(
                            mobile: userId.trim(),
                            password: password.trim(),
                            userToken: token.userToken.toString(),
                            // Normally from FCM
                            teamho: otp.toString(),
                            imeiNumber: _publicIp.toString(),
                            context: context, // Get from device_info
                          );
                          print(message.toString());
                          if (result['success'] == true) {
                            // ✅ Login success
                            Get.snackbar(
                              "Login success!!",
                              "You are logged in successfully ✅!",
                              icon: Image.asset(
                                "assets/logo/cmp_logo.png",
                                height: 30,
                                width: 30,
                              ),
                              shouldIconPulse: true,
                              backgroundColor: AppConstant.snackBackColor,
                              colorText: AppConstant.snackFontColor,
                              snackPosition: SnackPosition.BOTTOM,
                              borderRadius: 15,
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              duration: const Duration(seconds: 3),
                              isDismissible: true,
                              forwardAnimationCurve: Curves.easeOutBack,
                            );
                          } else {
                            Get.snackbar(
                              "Login Failed",
                              "something want wrong please contact head office!",
                              icon: const Icon(
                                Icons.error_outline,
                                color: Colors.black,
                                size: 28,
                              ),
                              shouldIconPulse: true,
                              backgroundColor: AppConstant.snackBackColor,
                              colorText: AppConstant.snackFontColor,
                              snackPosition: SnackPosition.TOP,
                              borderRadius: 15,
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              duration: const Duration(seconds: 4),
                              isDismissible: true,
                              forwardAnimationCurve: Curves.easeOutBack,
                            );
                            Get.to(() => Login());
                          }
                        } else {
                          Get.snackbar(
                            "Error !!",
                            "Your OTP does not match please check the otp ❌ !!",
                            icon: Image.asset(
                              "assets/logo/cmp_logo.png",
                              height: 30,
                              width: 30,
                            ),
                            shouldIconPulse: true,
                            backgroundColor: AppConstant.snackBackColor,
                            colorText: AppConstant.snackFontColor,
                            snackPosition: SnackPosition.TOP,
                            borderRadius: 15,
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            duration: const Duration(seconds: 3),
                            isDismissible: true,
                            forwardAnimationCurve: Curves.easeOutBack,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      elevation: 6,
    );
  }
}
