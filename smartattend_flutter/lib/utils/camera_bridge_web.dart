// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
// SmartAttend — Camera Bridge Web Implementation
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class WebCameraBridge {
  static bool get isSupported => true;
  static html.VideoElement? _videoElement;
  static html.MediaStream? _mediaStream;

  static Widget buildView(String viewType) {
    return HtmlElementView(viewType: viewType);
  }

  static Future<bool> initCamera(String viewType) async {
    try {
      if (_videoElement == null) {
        _videoElement = html.VideoElement()
          ..autoplay = true
          ..muted = true
          ..setAttribute('playsinline', 'true')
          ..setAttribute('webkit-playsinline', 'true')
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.borderRadius = '24px'
          ..style.transform = 'scaleX(-1)';

        ui_web.platformViewRegistry.registerViewFactory(
          viewType,
          (int viewId) => _videoElement!,
        );
      }

      final nav = html.window.navigator;
      if (nav.mediaDevices != null) {
        final stream = await nav.mediaDevices!.getUserMedia({'video': true});
        _mediaStream = stream;
        _videoElement!.srcObject = stream;
        await _videoElement!.play();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static void stopCamera() {
    try {
      _mediaStream?.getTracks().forEach((track) => track.stop());
      _videoElement?.pause();
      _videoElement?.srcObject = null;
    } catch (_) {}
  }

  static String? captureFrameBase64() {
    if (_videoElement == null) return null;
    try {
      final canvas = html.CanvasElement(
        width: _videoElement!.videoWidth > 0 ? _videoElement!.videoWidth : 640,
        height: _videoElement!.videoHeight > 0 ? _videoElement!.videoHeight : 480,
      );
      final ctx = canvas.context2D;
      ctx.translate(canvas.width!, 0);
      ctx.scale(-1, 1);
      ctx.drawImage(_videoElement!, 0, 0);
      return canvas.toDataUrl('image/jpeg', 0.85);
    } catch (e) {
      return null;
    }
  }
}
