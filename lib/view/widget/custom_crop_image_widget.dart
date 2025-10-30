import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CustomCropWidget extends StatelessWidget {
  final File imageFile;
  final Function(File) onCropped; // 👈 return cropped file to parent
  final VoidCallback? onCancel;

  CustomCropWidget({
    Key? key,
    required this.imageFile,
    required this.onCropped,
    this.onCancel,
  }) : super(key: key);

  final CropController _controller = CropController();

  /// 🔹 Save cropped data as a new File
  Future<File> _saveCroppedData(Uint8List croppedData) async {
    final directory = await getTemporaryDirectory();
    final path =
        "${directory.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final file = File(path);
    await file.writeAsBytes(croppedData);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔹 Crop Area
        Expanded(
          child: Crop(
            controller: _controller,
            image: imageFile.readAsBytesSync(),
            withCircleUi: false,
            cornerDotBuilder: (size, edgeAlignment) =>
                const DotControl(color: Colors.white),
            aspectRatio: null,
            initialSize: 0.6,
            onCropped: (Uint8List bytes) async {
              final croppedFile = await _saveCroppedData(bytes);
              onCropped(croppedFile);
            },
          ),
        ),
        // 🔹 Bottom Toolbar
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Cancel
              ElevatedButton(
                onPressed: onCancel ?? () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              // Crop
              ElevatedButton(
                onPressed: () {
                  _controller.crop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Ok", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
