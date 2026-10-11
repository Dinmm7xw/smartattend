// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
// SmartAttend — Web Platform Helper
// Implementation for Web platform using dart:html & dart:js & dart:ui_web

import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

class WebPlatformHelper {
  static bool get isWeb => true;
  static bool get isPushSupported => html.Notification.supported;
  static String get pushPermission => html.Notification.permission ?? 'default';

  static Future<bool> requestPushPermission() async {
    if (!html.Notification.supported) return false;
    try {
      final perm = await html.Notification.requestPermission();
      return perm == 'granted';
    } catch (_) {
      return false;
    }
  }

  static void sendNativePush(String title, String body) {
    try {
      html.Notification(
        title,
        body: body,
        icon: 'icons/Icon-192.png',
      );
    } catch (_) {}
  }

  static void showWebLoader(String lang, String text) {
    try {
      js.context.callMethod('showLoader', [lang, text]);
    } catch (_) {}
  }

  static void hideWebLoader() {
    try {
      js.context.callMethod('hideLoader', []);
    } catch (_) {}
  }

  static void pickWebImage(Function(String base64Data) onSelected) {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final reader = html.FileReader();
        reader.onLoadEnd.listen((e) {
          final res = reader.result as String?;
          if (res != null) {
            onSelected(res);
          }
        });
        reader.readAsDataUrl(files[0]);
      }
    });
  }

  static void pickWebTextFile(Function(String content) onContentRead) {
    final uploadInput = html.FileUploadInputElement()..accept = '.csv,.txt,.tsv';
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final reader = html.FileReader();
        reader.onLoadEnd.listen((e) {
          final res = reader.result as String?;
          if (res != null) {
            onContentRead(res);
          }
        });
        reader.readAsText(files[0]);
      }
    });
  }

  static void registerIframe(String viewType, String url) {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = '#F8FAFC';
        return iframe;
      },
    );
  }
}
