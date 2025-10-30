import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:peckme/controller/update_password_controller.dart';

import '../../utils/app_constant.dart';
import 'login.dart';

class NewPasswordScreen extends StatefulWidget {
  final String userId;
  final String otp; // OTP जो backend/msg91 से आया है

  NewPasswordScreen({super.key, required this.userId, required this.otp});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();

  void _updatePassword() async {
    String userOtp = otpController.text.trim();
    String newPassword = newPassController.text.trim();

    // ✅ 1. Check if OTP empty
    if (userOtp.isEmpty) {
      Get.snackbar(
        "Error !!",
        "Please enter OTP ❌",
        icon: Image.asset("assets/logo/cmp_logo.png", height: 30, width: 30),
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
      return;
    }

    // ✅ 2. Check if password empty
    if (newPassword.isEmpty) {
      Get.snackbar(
        "Error !!",
        "Please enter new password ❌",
        icon: Image.asset("assets/logo/cmp_logo.png", height: 30, width: 30),
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
      return;
    }

    // ✅ 3. Check if OTP wrong
    if (userOtp != widget.otp) {
      Get.snackbar(
        "Invalid OTP !!",
        "Your OTP does not match ❌",
        icon: Image.asset("assets/logo/cmp_logo.png", height: 30, width: 30),
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
      return;
    }

    // ✅ 4. अगर सब ठीक है → API call
    final result = await UpdateAuthService.login(
      mobile: widget.userId,
      newPassword: newPassword,
      otp: userOtp,
      context: context,
    );

    if (result['success'] == true) {
      Get.to(() => Login());
      Get.snackbar(
        "Success!!!",
        "Password updated successfully ✅",
        icon: Image.asset("assets/logo/cmp_logo.png", height: 30, width: 30),
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
    } else {
      Get.snackbar(
        "Failed!",
        result['message'] ?? "Something went wrong ❌",
        icon: Image.asset("assets/logo/cmp_logo.png", height: 30, width: 30),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: AppConstant.iconColor),
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(height: 30),
              Text(
                'New Password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),

              // OTP Field
              TextFormField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'Enter OTP',
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
              SizedBox(height: 15),

              // New Password Field
              TextFormField(
                controller: newPassController,
                obscureText: true,
                maxLength: 12,
                decoration: InputDecoration(
                  labelText: 'Enter the new password',
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
                    _updatePassword();
                    Get.offAll(() => Login());
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
                        'Update Password',
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
            ],
          ),
        ),
      ),
    );
  }
}
