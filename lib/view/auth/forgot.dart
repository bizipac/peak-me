import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:peckme/controller/forgot_otp_password.dart';
import 'package:peckme/view/auth/new_password.dart';

import '../../utils/app_constant.dart';
import 'login.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String userId;
  String responseMsg = '';

  void requestOtp() async {
    final mobile = userId.trim();
    if (mobile.isNotEmpty) {
      final result = await ForgotOtpPasswordService.getOtp(mobile: mobile);
      setState(() {
        if (result.success == 1) {
          Get.snackbar(
            "Success!",
            "OTP sent successfully (Send OTP: ${mobile})",
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
            borderRadius: 15,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            duration: const Duration(seconds: 3),
            isDismissible: true,
            forwardAnimationCurve: Curves.easeOutBack,
          );
          Get.to(
            () => NewPasswordScreen(userId: mobile, otp: result.otp ?? ''),
          );
          //showCustomBottomSheet(userId,token.userToken.toString(),result.message.toString());
        } else {
          Get.snackbar(
            "Failed!",
            "Something went wrong please connect to the office, Thank You!!",
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
            borderRadius: 15,
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
        responseMsg = 'Please enter the fields';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: AppConstant.iconColor),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: 30),
              Text(
                'Forget Password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              TextFormField(
                onChanged: (value) {
                  userId = value;
                },
                maxLength: 10,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'enter your number';
                  } else {
                    return null;
                  }
                },
                decoration: InputDecoration(
                  labelText: 'UserId',
                  hintText: 'Enter your userId',
                  hintStyle: TextStyle(fontSize: 12),
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
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: InkWell(
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      requestOtp();
                    }
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
                        'Forget',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: AppConstant.appTextFamily,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Spacer(),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have account? "),
                    GestureDetector(
                      onTap: () {
                        // Navigate to login screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return Login();
                            },
                          ),
                        );
                      },
                      child: Text(
                        "Log in",
                        style: TextStyle(
                          color: AppConstant.darkButton,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
