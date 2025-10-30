import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../utils/app_constant.dart';

class IciciWebviewWidget extends StatefulWidget {
  final String url;

  IciciWebviewWidget({super.key, required this.url});

  @override
  State<IciciWebviewWidget> createState() => _IciciWebviewWidgetState();
}

class _IciciWebviewWidgetState extends State<IciciWebviewWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstant.appBarColor,
        iconTheme: IconThemeData(color: AppConstant.appBarWhiteColor),
        title: Text("Onfield Prepaid Card"),
      ),
      body: SafeArea(child: WebViewWidget(controller: _controller)),
    );
  }
}
