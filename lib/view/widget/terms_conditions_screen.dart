import 'package:flutter/material.dart';
import 'package:peckme/utils/app_constant.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
          style: TextStyle(color: AppConstant.appBarWhiteColor, fontSize: 18),
        ),
        backgroundColor: AppConstant.appBarColor,
        iconTheme: IconThemeData(color: AppConstant.appBarWhiteColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Title & Version
            Center(
              child: Column(
                children: [
                  Text(
                    "Peak Me",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppConstant.appBarColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Version: ${AppConstant.appVersion}",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            Text(
              "Welcome to Peak Me",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "By using Peak Me, you agree to the following terms and conditions. "
              "Please read them carefully before using our services.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 20),

            Text(
              "1. Account Responsibility",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.",
            ),
            SizedBox(height: 10),

            Text(
              "2. Use of Service",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "You agree to use Peak Me only for lawful purposes and in accordance with all applicable laws. "
              "You may not misuse the app or attempt to gain unauthorized access to its systems.",
            ),
            SizedBox(height: 10),
            Text(
              "3. Data & Privacy",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "We respect your privacy. Your personal data will be collected, stored, and used in accordance with our Privacy Policy. "
              "Peak Me does not share your private information with third parties without your consent.",
            ),
            SizedBox(height: 10),

            Text(
              "4. Authorized by Google",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "Peak Me is authorized by Google as an Open App and complies with Google Play policies and guidelines.",
            ),
            SizedBox(height: 10),

            Text(
              "5. Modifications",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "We reserve the right to modify, update, or replace these terms at any time. "
              "Updated versions will be available within the app.",
            ),
            SizedBox(height: 10),

            Text(
              "6. Limitation of Liability",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "Peak Me will not be liable for any indirect, incidental, or consequential damages arising from the use or inability to use the app.",
            ),
            SizedBox(height: 30),

            Divider(),
            Center(
              child: Column(
                children: [
                  Text(
                    "© 2025 Peak Me. All rights reserved.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Company Name: Bizipac Couriers Pvt. Ltd.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Address: 337, Omkar Apartments, Shradhanand Road, Vile Parle East, Mumbai-400057, Maharashtra, India",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 2),

                  Text(
                    "Developed by: Shubham Gupta",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    "Email: info@teamunited.net",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 2),
                  SizedBox(height: 4),
                  Text(
                    "Authorized by Google as an Open App.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
