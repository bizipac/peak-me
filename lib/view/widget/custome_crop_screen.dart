import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'custom_crop_image_widget.dart';

class CustomCropScreen extends StatelessWidget {
  final File imageFile;

  const CustomCropScreen({Key? key, required this.imageFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomCropWidget(
          imageFile: imageFile,
          onCropped: (croppedFile) {
            Navigator.pop(context, croppedFile); // 👈 return File to caller
          },
          onCancel: () {
            Navigator.pop(context, null); // 👈 cancel return
          },
        ),
      ),
    );
  }
}
