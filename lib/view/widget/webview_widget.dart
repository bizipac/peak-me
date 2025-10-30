import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:peckme/utils/app_constant.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../received_lead_screen.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String customerName;
  final String leadid;
  final String client;

  WebViewScreen({
    Key? key,
    required this.customerName,
    required this.leadid,
    required this.client,
    required this.url,
  }) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = false; // overlay loader flag

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            print("✅ Page finished: $url");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _checkFiStatus() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final String apiUrl =
        "https://fms.bizipac.com/apinew/ws_new/new_lead_detail.php?lead_id=${widget.leadid}";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // ✅ Fix: extract from first element of "data"
        final firstItem = decoded["data"][0];
        int fiData = firstItem["fiData"] ?? 0;

        print("----------------");
        print("FIDATA : $fiData");
        print("----------------");

        if (fiData == 1) {
          Get.offAll(() => ReceivedLeadScreen());
          Get.rawSnackbar(
            message: "Upload the documents.!",
            backgroundColor: AppConstant.appBarColor,
            duration: const Duration(seconds: 3),
          );
        } else {
          Get.rawSnackbar(
            message: "Kindly complete FI Properly. Follow the instruction.!",
            backgroundColor: AppConstant.appBarColor,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        Get.rawSnackbar(
          message: "Server error: ${response.statusCode}.!",
          backgroundColor: AppConstant.appBarColor,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar("Error", "API error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: AppBar(
              backgroundColor: AppConstant.appBarColor,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow("CustomerName : ", widget.customerName),
                    _buildInfoRow("LeadId : ", widget.leadid),
                    _buildInfoRow("ClientName : ", widget.client),
                  ],
                ),
              ),
            ),
          ),
          body: SafeArea(child: WebViewWidget(controller: _controller)),

          // Document Upload Button
          floatingActionButton: InkWell(
            onTap: _isLoading ? null : _checkFiStatus,
            // disable tap while loading
            child: Container(
              height: 40,
              width: 111,
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey[300] : Colors.green[100],
                // dim color when loading
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.green,
                        ),
                      )
                    : const Text(
                        "Document Upload ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          resizeToAvoidBottomInset: false, // 👈 Stops FAB from floating up
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.white),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
