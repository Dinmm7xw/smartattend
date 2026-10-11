import 'package:flutter/foundation.dart';

/// In-memory session: JWT token + current user's avatar (shared by all dashboards).
class AppSession {
  static String? token;
  static final ValueNotifier<String?> avatarUrl = ValueNotifier<String?>(null);

  static void clear() {
    token = null;
    avatarUrl.value = null;
  }
}
