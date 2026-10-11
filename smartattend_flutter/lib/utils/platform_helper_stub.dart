// SmartAttend — Web Platform Helper
// Default stub implementation for Android / iOS / Desktop (Non-web)

class WebPlatformHelper {
  static bool get isWeb => false;
  static bool get isPushSupported => false;
  static String get pushPermission => 'unsupported';
  static Future<bool> requestPushPermission() async => false;
  static void sendNativePush(String title, String body) {}
  static void showWebLoader(String lang, String text) {}
  static void hideWebLoader() {}
  static void pickWebImage(Function(String base64Data) onSelected) {}
  static void pickWebTextFile(Function(String content) onContentRead) {}
  static void registerIframe(String viewType, String url) {}
}
