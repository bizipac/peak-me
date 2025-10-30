import 'dart:io';
import 'dart:ui' as ui;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class AadhaarMaskService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  final RegExp aadhaarRegex = RegExp(
    r'(?:(?:\d{4}\s?\d{4}\s?\d{4})|(?:\d{4}-?\d{4}-?\d{4})|\d{12})',
  );

  Future<File?> pickImage(ImageSource source) async {
    final XFile? xfile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (xfile == null) return null;
    return File(xfile.path);
  }

  Future<AadhaarMaskResult> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final fullText = recognizedText.text;
    final match = aadhaarRegex.firstMatch(fullText);

    if (match == null) {
      return AadhaarMaskResult(
        maskedAadhaar: "Aadhaar number not found",
        redactRects: [],
        image: await _loadUiImage(imageFile),
      );
    }

    // Clean Aadhaar number
    String raw = match.group(0)!.replaceAll(RegExp(r'[\s-]'), '');
    if (raw.length != 12) {
      return AadhaarMaskResult(
        maskedAadhaar: "Invalid Aadhaar detected",
        redactRects: [],
        image: await _loadUiImage(imageFile),
      );
    }

    // Mask first 8 digits
    String masked = '**** **** ${raw.substring(8)}';

    // Collect digit elements
    List<Map<String, dynamic>> digitElements = [];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final elText = element.text.replaceAll(RegExp(r'[\s-]'), '');
          if (RegExp(r'^\d+$').hasMatch(elText)) {
            digitElements.add({'text': elText, 'box': element.boundingBox});
          }
        }
      }
    }

    // Sort elements by their X position (left to right)
    digitElements.sort(
      (a, b) =>
          (a['box'] as ui.Rect).left.compareTo((b['box'] as ui.Rect).left),
    );

    // Mask first 8 digits exactly
    int digitsMasked = 0;
    List<ui.Rect> redactRects = [];
    for (final el in digitElements) {
      final elText = el['text'] as String;
      final elBox = el['box'] as ui.Rect;

      if (digitsMasked < 8) {
        digitsMasked += elText.length;
        redactRects.add(elBox);
      } else {
        break;
      }
    }

    final img = await _loadUiImage(imageFile);
    return AadhaarMaskResult(
      maskedAadhaar: masked,
      redactRects: redactRects,
      image: img,
    );
  }

  Future<ui.Image> _loadUiImage(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class AadhaarMaskResult {
  final String maskedAadhaar;
  final List<ui.Rect> redactRects;
  final ui.Image image;

  AadhaarMaskResult({
    required this.maskedAadhaar,
    required this.redactRects,
    required this.image,
  });
}
