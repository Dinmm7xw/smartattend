import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/platform_helper.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final String type; // 'ATTENDANCE', 'URGENT', 'DIRECTOR', 'LESSON'
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.type = 'DIRECTOR',
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'time': time.toIso8601String(),
        'type': type,
        'isRead': isRead,
      };
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    _initDefaultNotifications();
  }

  final ValueNotifier<List<AppNotification>> notificationsNotifier =
      ValueNotifier<List<AppNotification>>([]);

  int get unreadCount =>
      notificationsNotifier.value.where((n) => !n.isRead).length;

  void _initDefaultNotifications() {
    notificationsNotifier.value = [
      AppNotification(
        id: 'notif-1',
        title: '📢 Директор бұйрығы: Ашық сессия',
        body: 'Құрметті студенттер мен оқытушылар! Дүйсенбі күні SmartAttend инновациялық Face ID жүйесін қорғау сағат 10:00-де басталады.',
        time: DateTime.now().subtract(const Duration(minutes: 15)),
        type: 'DIRECTOR',
        isRead: false,
      ),
      AppNotification(
        id: 'notif-2',
        title: '⏰ Сабақ туралы ескерту',
        body: '13:00 - C1.3.241 аудиториясында «Мобильді қосымшалар әзірлеу» зертханалық жұмысы басталады. Кешікпеңіз!',
        time: DateTime.now().subtract(const Duration(minutes: 45)),
        type: 'LESSON',
        isRead: false,
      ),
      AppNotification(
        id: 'notif-3',
        title: '✅ Сабаққа қатысу расталды',
        body: 'БҚ2405 тобы: «Алгоритмдер және деректер құрылымы» пәніне қатысу Face ID арқылы 98.4% дәлдікпен сәтті бекітілді.',
        time: DateTime.now().subtract(const Duration(hours: 3)),
        type: 'ATTENDANCE',
        isRead: true,
      ),
    ];
  }

  /// Check if Browser / Mobile Push Notifications are supported
  bool get isPushSupported => WebPlatformHelper.isPushSupported;

  /// Current permission: 'granted', 'denied', or 'default'
  String get pushPermission => WebPlatformHelper.pushPermission;

  /// Request Push notification permission from user
  Future<bool> requestPushPermission() async {
    return await WebPlatformHelper.requestPushPermission();
  }

  /// Trigger a Notification (Both OS Push + In-App Notification Center)
  Future<void> sendNotification({
    required String title,
    required String body,
    String type = 'DIRECTOR',
  }) async {
    // 1. Add to In-App List
    final notif = AppNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      time: DateTime.now(),
      type: type,
      isRead: false,
    );

    final updated = List<AppNotification>.from(notificationsNotifier.value);
    updated.insert(0, notif);
    notificationsNotifier.value = updated;

    // 2. Send Real OS Push Notification if supported
    if (WebPlatformHelper.isPushSupported) {
      if (WebPlatformHelper.pushPermission == 'granted') {
        WebPlatformHelper.sendNativePush(title, body);
      } else if (WebPlatformHelper.pushPermission == 'default') {
        final perm = await WebPlatformHelper.requestPushPermission();
        if (perm) {
          WebPlatformHelper.sendNativePush(title, body);
        }
      }
    }
  }

  void markAllAsRead() {
    final updated = notificationsNotifier.value.map((n) {
      n.isRead = true;
      return n;
    }).toList();
    notificationsNotifier.value = updated;
  }

  void markAsRead(String id) {
    final updated = notificationsNotifier.value.map((n) {
      if (n.id == id) n.isRead = true;
      return n;
    }).toList();
    notificationsNotifier.value = updated;
  }

  void clearAll() {
    notificationsNotifier.value = [];
  }
}
