import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Request permission for iOS/Android 13+
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // TODO: Show local notification or snackbar
      }
    });

    // Background/Terminated messages handlers are usually in main.dart
  }

  static Future<void> registerToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint("FCM Token: $token");
        // Send token to backend
        await ApiClient().dio.patch('/users/fcm-token', data: {'fcmToken': token});
      }
    } catch (e) {
      debugPrint("FCM Token Registration Error: $e");
    }
  }
}
