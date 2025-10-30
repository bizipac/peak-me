import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peckme/utils/app_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class IciciPrePaidCardScreen extends StatefulWidget {
  final String? userId;
  final String? branchId;
  final String? bizipacLeadId;
  final String? clientLeadId;
  final String? gpsLat;
  final String? gpsLng;

  const IciciPrePaidCardScreen({
    super.key,
    this.userId,
    this.branchId,
    this.bizipacLeadId,
    this.clientLeadId,
    this.gpsLat,
    this.gpsLng,
  });

  @override
  State<IciciPrePaidCardScreen> createState() => _IciciPrePaidCardScreenState();
}

class _IciciPrePaidCardScreenState extends State<IciciPrePaidCardScreen> {
  late final WebViewController _controller;
  late String url;
  static const platform = MethodChannel('com.example.peckme/file_picker');

  // File picker
  final ImagePicker _picker = ImagePicker();

  Future<String> getPreference(String key, {String fallback = '0'}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? fallback;
  }

  Future<void> setupUrlAndWebView() async {
    final userId = widget.userId ?? await getPreference('uid', fallback: '0');
    final branchId =
        widget.branchId ?? await getPreference('branch_id', fallback: '0');
    final bizipacLeadId = widget.bizipacLeadId ?? '0';
    final clientLeadId = widget.clientLeadId ?? '0';
    final gpsLat = widget.gpsLat ?? '0.0';
    final gpsLng = widget.gpsLng ?? '0.0';

    debugPrint(
      "userId: $userId | branchId: $branchId | bizipacLeadId: $bizipacLeadId | clientLeadId: $clientLeadId | gps: $gpsLat, $gpsLng",
    );

    url =
        "https://fms.bizipac.com/apinew/secureapi/icici_pre_paid_card_gen.php?user_id=$userId&branch_id=$branchId#!/";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FileChannel',
        onMessageReceived: (message) async {
          final String filePath = await _pickFileFromNative();
          if (filePath.isNotEmpty) {
            final base64 = await _readAsBase64(filePath);
            _controller.runJavaScript("handleFileUpload('$base64')");
          }
        },
      )
      ..loadRequest(
        Uri.parse(
          'https://fms.bizipac.com/apinew/secureapi/icici_pre_paid_card_gen.php?user_id=7494&branch_id=53#!/',
        ),
      );
    // setupUrlAndWebView();
  }

  Future<String> _pickFileFromNative() async {
    try {
      final result = await platform.invokeMethod('pickFile');
      return result ?? '';
    } on PlatformException catch (e) {
      print("Platform error: $e");
      return '';
    }
  }

  Future<String> _readAsBase64(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: AppConstant.appBarColor,
        title: const Text(
          "ICICI Prepaid Card",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
