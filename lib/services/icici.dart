import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';

class IciciLauncher {
  final String authId;
  final String athenaLeadId;

  IciciLauncher({
    required this.authId,
    required this.athenaLeadId,
  });

  Future<void> openIciciApp({
    required String clientId,
    required String sessionValue,
    required String? sessionValue2,
  }) async {
    try {
      if (clientId.trim() == "38") {
        await _startIciciApp(
          packageName: "com.servo.icici.oapnxt",
          action: "com.servo.icici.oapnxt.OPENOAPNXT",
          sessionValue: sessionValue,
        );
      } else if (clientId.trim() == "28") {
        await _startIciciApp(
          packageName: "com.servo.icici.oapnxt.assisted",
          action: "com.servo.icici.oapnxt.OPENOAPNXTASSISTED",
          sessionValue: sessionValue2 ?? "",
        );
      } else if (clientId.trim() == "11") {
        debugPrint("➡ Open your IciciIntegration Flutter screen here");
      } else {
        debugPrint("❌ Unsupported clientId: $clientId");
      }
    } catch (e) {
      debugPrint("🚨 Error launching ICICI app: $e");
    }
  }

  Future<void> _startIciciApp({
    required String packageName,
    required String action,
    required String sessionValue,
  }) async {
    final intent = AndroidIntent(
      action: action,
      package: packageName,
      arguments: <String, dynamic>{
        "userName": authId,
        "sessionId": sessionValue,
        "appId": athenaLeadId,
        "sourcing_application": "com.bizipac",
      },
    );

    await intent.launch();
  }
}
