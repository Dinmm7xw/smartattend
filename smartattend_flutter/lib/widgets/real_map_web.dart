// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/platform_helper.dart';

class RealCollegeMapView extends StatefulWidget {
  const RealCollegeMapView({super.key});

  @override
  State<RealCollegeMapView> createState() => _RealCollegeMapViewState();
}

class _RealCollegeMapViewState extends State<RealCollegeMapView> {
  static bool _registered = false;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      if (!_registered) {
        WebPlatformHelper.registerIframe('aitu-real-college-map', 'map_mobile.html?embedded=1');
        _registered = true;
      }
    } else {
      // Mobile (Android / iOS)
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFF8FAFC))
        ..loadRequest(Uri.parse('http://10.0.2.2:8585/map_mobile.html?embedded=1'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const HtmlElementView(viewType: 'aitu-real-college-map');
    }
    if (_webViewController != null) {
      return WebViewWidget(controller: _webViewController!);
    }
    return const Center(child: CircularProgressIndicator());
  }
}
