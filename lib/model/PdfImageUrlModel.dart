import 'dart:io';

class UploadResult {
  final File croppedImage;
  final String pdfUrl;

  UploadResult({required this.croppedImage, required this.pdfUrl});
}
