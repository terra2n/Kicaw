import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'realtime_service.dart';
import 'settings_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final notif = message.notification;
  if (notif != null) {
    final plugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(const InitializationSettings(android: android));
    await plugin.show(
      message.messageId.hashCode,
      notif.title ?? 'Smart Room',
      notif.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fcm_high',
          'FCM Alerts',
          channelDescription: 'Push notifications from FCM',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final RealtimeService _rt = RealtimeService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SettingsService? _settings;
  StreamSubscription? _occupancySub;
  StreamSubscription? _onMessageSub;
  StreamSubscription? _onMessageOpenedAppSub;
  bool _localEnabled = true;
  bool _pushEnabled = true;
  bool _wasOccupied = false;

  bool get localEnabled => _localEnabled;
  bool get pushEnabled => _pushEnabled;

  Future<void> init(SettingsService settings) async {
    _settings = settings;
    _localEnabled = await settings.getBool('local_notif', true);
    _pushEnabled = await settings.getBool('push_notif', true);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    NotificationSettings perm = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (perm.authorizationStatus == AuthorizationStatus.authorized ||
        perm.authorizationStatus == AuthorizationStatus.provisional) {
      try {
        final token = await _fcm.getToken().timeout(const Duration(seconds: 10));
        if (token != null) {
          await _firestore
              .collection('fcm_tokens')
              .doc(token.hashCode.toString())
              .set({'token': token, 'updated_at': DateTime.now().toIso8601String()});
        }
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }
    }

    _listenOccupancy();
    _listenFCM();
  }

  void _listenOccupancy() {
    _occupancySub = _rt.occupancyStream.listen((occupied) {
      if (!_localEnabled) return;
      if (occupied == _wasOccupied) return;
      _wasOccupied = occupied;

      final title = occupied ? 'Room Occupied' : 'Room Empty';
      final body = occupied
          ? 'Motion detected — light turning on'
          : 'No motion for 1s — light turning off';

      _local.show(
        DateTime.now().millisecondsSinceEpoch,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'occupancy',
            'Occupancy Alerts',
            channelDescription: 'Room occupancy change notifications',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    });
  }

  void _listenFCM() {
    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!_pushEnabled) return;
      final notif = message.notification;
      if (notif != null) {
        _local.show(
          message.messageId.hashCode,
          notif.title ?? 'Smart Room',
          notif.body ?? '',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'fcm_high',
              'FCM Alerts',
              channelDescription: 'Push notifications from FCM',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // handle tap, e.g., navigate to specific page
    });

    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        // handle notification that opened app from terminated state
      }
    });
  }

  Future<void> setLocalEnabled(bool v) async {
    _localEnabled = v;
    await _settings?.setBool('local_notif', v);
    if (v) {
      _occupancySub?.resume();
    } else {
      _occupancySub?.pause();
    }
  }

  Future<void> setPushEnabled(bool v) async {
    _pushEnabled = v;
    await _settings?.setBool('push_notif', v);
  }

  void dispose() {
    _occupancySub?.cancel();
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
  }
}
