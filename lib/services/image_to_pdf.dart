import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:peckme/services/save_complete_lead.dart';

import '../handler/EncryptionHandler.dart';

Future<String?> convertImageToPdfAndSave(
  File imageFile,
  String docname,
  String clientName,
  String leadId,
  String uid,
  String documentId,
  String userName,
) async {
  final compressedBytes = await FlutterImageCompress.compressWithList(
    await imageFile.readAsBytes(),
    quality: 75, // try 30-50 for smaller size
    minWidth: 800,
    minHeight: 1000,
  );

  final pdfImage = pw.MemoryImage(compressedBytes);
  final pdf = pw.Document();

  // 🔹 Get current location
  String latLongText = await _getCurrentLocation();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Stack(
          children: [
            // 🔹 Centered Image scaled to fit A4 without distortion
            pw.Positioned.fill(
              child: pw.FittedBox(
                fit: pw.BoxFit.contain, // 👈 contains inside A4
                child: pw.Image(
                  pdfImage,
                  width: PdfPageFormat.a4.width,
                  height: PdfPageFormat.a4.height,
                ),
              ),
            ),
            // 🔹 Overlay Info
            pw.Positioned(
              top: 450,
              left: 250,
              child: pw.Opacity(
                opacity: 0.5,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  color: PdfColors.black,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'To be used for : $clientName',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.white,
                        ),
                      ),
                      // pw.Text(
                      //   'Doc Name : $documentId',
                      //   style: pw.TextStyle(
                      //     fontSize: 12,
                      //     color: PdfColors.white,
                      //   ),
                      // ),
                      pw.Text(
                        '$userName',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        '$latLongText',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        '${DateTime.now()}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  print("User ID : $uid");
  int min = 1000;
  int max = 99999999;
  int number = min + Random().nextInt(max - min + 1); // always 6-digit
  final Uint8List pdfBytes = await pdf.save();

  print("📄 PDF Size: ${(pdfBytes.length / 1024).toStringAsFixed(2)} KB");

  // 🔹 Calculate PDF size
  int pdfSizeInBytes = pdfBytes.length;
  double pdfSizeInKB = pdfSizeInBytes / 1024;

  print("📄 PDF Size MB : ${pdfSizeInBytes.toStringAsFixed(2)} KB");
  print("📄 PDF Size Kb : ${pdfSizeInKB.toStringAsFixed(2)} KB");

  final String docName = docname;
  String newStr4 = docName.replaceAll(" ", "_");
  String newStr5 = newStr4.replaceAll("-", "_");
  print(newStr5);

  final String docCliName = clientName;
  String newStr6 = docName.replaceAll(" ", "_");
  String newStr7 = newStr6.replaceAll("-", "_");
  print(newStr7);

  // 🔹 Unique file name for S3
  final objectKey = "$docCliName-$docName-$leadId-$number.pdf";
  String newStr = objectKey.replaceAll(" ", "_");
  String newStr1 = newStr.replaceAll("-", "_");

  final res = await uploadPdfToS3(
    pdfFile: pdfBytes,
    bucket: "bizipac-walnut",
    objectKey: newStr1,
    leadID: leadId,
    clientName: newStr7,
    docName: newStr5,
    loginid: uid,
    // context: context,
  );
  // print("✅✅ PDF uploaded to: $uploadedUrl");
  return res;
}

/// Upload PDF AWS/MySQL Method
Future<String?> uploadPdfToS3({
  required Uint8List pdfFile,
  String region = 'ap-south-1',
  required String bucket,
  required String objectKey,
  required String leadID,
  required String clientName,
  required String docName,
  required String loginid,
  BuildContext? context, // 🔹 optional for SnackBar
}) async {
  // (Optional) upload se pehle quick internet check
  if (!await _hasInternet()) {
    _notifyStatus('No internet connection', context: context);
    return 'No internet connection';
  }
  // 🔹 Create S3 client
  String latLongText = await _getCurrentLocation();
  final s3 = S3(
    region: region,
    credentials: AwsClientCredentials(
      accessKey: decryptFMS(
        "TohPtOvObC8NnBOp/1BM30tSr97U803JZ+gqI3Jf4uM=",
        "QWRTEfnfdys635",
      ),
      secretKey: decryptFMS(
        "Exz2WIEt2w1JRVZREvtIPeRX5Jti2p2mcHqs7Hh87/47BQidFAUAkLOxlzYFlctw",
        "QWRTEfnfdys635",
      ),
    ),
  );

  // ⏱️ Measure upload time
  final sw = Stopwatch()..start();
  try {
    await s3
        .putObject(
          bucket: bucket,
          key: objectKey,
          body: pdfFile,
          contentLength: pdfFile.length,
          contentType: 'application/pdf',
          acl: ObjectCannedACL.publicRead,
        )
        .timeout(const Duration(minutes: 2)); // safety timeout
  } on TimeoutException {
    _notifyStatus(
      'Network is very slow or stalled (upload timeout)',
      context: context,
    );
    return 'Network is very slow or stalled (upload timeout)';
  } catch (e) {
    _notifyStatus('Upload failed: $e', context: context);
    rethrow;
  } finally {
    sw.stop();
  }

  // 📏 Calculate upload speed
  final seconds = sw.elapsedMilliseconds / 1000.0;
  final bits = pdfFile.length * 8; // bytes → bits
  final bps = bits / seconds; // bits per second
  final mbps = bps / 1e6; // Mbps

  final code = _classifySpeed(bps);
  final human = _labelForUser(code);

  // ✅ Always show internet status (slow / ok / fast)
  _notifyStatus(
    '$human • Upload speed: ${mbps.toStringAsFixed(2)} Mbps',
    context: context,
  );

  // ✅ Public URL
  final publicUrl = "https://$bucket.s3.$region.amazonaws.com/$objectKey";
  print("Uploaded file URL: $publicUrl");

  // 🔹 Save to your MySQL API
  final Uri api = Uri.parse(
    "https://fms.bizipac.com/apinew/ws_new/add_doc_simple.php",
  );
  final res = await saveCompletedLeadUrl(
    endpoint: api,
    loginid: loginid,
    leadid: leadID,
    doc_name: docName,
    address: "Bizipac Courires Pvt Ltd.",
    geoLocation: latLongText,
    doc_url: publicUrl,
  );

  if (res.success == 1) {
    _notifyStatus('Uploaded & saved successfully', context: context);
  } else {
    _notifyStatus('Upload OK, but DB save failed', context: context);
  }
  return publicUrl;
}

// Optional: basic internet availability check (no plugin)
Future<bool> _hasInternet() async {
  try {
    final res = await InternetAddress.lookup(
      'example.com',
    ).timeout(const Duration(seconds: 5));
    return res.isNotEmpty && res.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

// Classify speed based on bits-per-second (bps)
String _classifySpeed(double bps) {
  if (bps < 200000) return 'very_slow'; // <0.2 Mbps
  if (bps < 1000000) return 'slow'; // 0.2–1 Mbps
  if (bps < 5000000) return 'ok'; // 1–5 Mbps
  return 'good'; // >5 Mbps
}

String _labelForUser(String code) {
  switch (code) {
    case 'very_slow':
      return '⚠️ Internet is very slow';
    case 'slow':
      return '⚠️ Internet is slow';
    case 'ok':
      return '✅ Internet is okay';
    case 'good':
    default:
      return '🚀 Your internet is fast';
  }
}

// Show message via SnackBar if context diya hai, warna print
void _notifyStatus(String msg, {BuildContext? context}) {
  if (context != null) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info, size: 40, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                msg,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  } else {
    print(msg); // fallback: agar context null ho
  }
}

/// 🔹 Helper function: fetch current location
Future<String> _getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return "Location service disabled";
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return "Permission denied";
    }
  }
  if (permission == LocationPermission.deniedForever) {
    return "Permission permanently denied";
  }

  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  return "${position.latitude},${position.longitude}";
}
