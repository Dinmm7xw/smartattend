// Conditional export for WebCameraBridge
export 'camera_bridge_stub.dart'
    if (dart.library.html) 'camera_bridge_web.dart';
