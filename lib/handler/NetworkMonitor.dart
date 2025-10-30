import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

// Optional: basic internet availability check (no plugin)
Future<bool> _hasInternet() async {
  try {
    final res = await InternetAddress.lookup('example.com')
        .timeout(const Duration(seconds: 5));
    return res.isNotEmpty && res.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

// Classify speed based on bits-per-second (bps)
String _classifySpeed(double bps) {
  // Adjust thresholds as you like
  if (bps < 200000) return 'very_slow';       // < 0.2 Mbps
  if (bps < 1000000) return 'slow';           // 0.2–1 Mbps
  if (bps < 5000000) return 'ok';             // 1–5 Mbps
  return 'good';                               // > 5 Mbps
}

String _labelForUser(String code) {
  switch (code) {
    case 'very_slow':
      return 'Internet is very slow';
    case 'slow':
      return 'Internet is slow';
    case 'ok':
      return 'Internet is okay';
    case 'good':
    default:
      return 'Your internet is good';
  }
}

// Show message via SnackBar if context diya hai, warna print
void _notifyStatus(String msg, {BuildContext? context}) {
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  } else {
    print(msg);
  }
}
