// SmartAttend — Camera Bridge Stub (Non-Web / Android / iOS)
import 'package:flutter/material.dart';

class WebCameraBridge {
  static bool get isSupported => false;
  static Widget buildView(String viewType) => const SizedBox.shrink();
  static Future<bool> initCamera(String viewType) async => false;
  static void stopCamera() {}
  static String? captureFrameBase64() => null;
}
