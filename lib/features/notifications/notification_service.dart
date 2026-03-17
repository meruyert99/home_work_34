import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/logger.dart';
import '../../core/routes.dart';
import 'notification_settings_repository.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.info(
    'BG message received: id=${message.messageId}, data=${message.data}',
  );
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationSettingsRepository _settingsRepo =
      NotificationSettingsRepository();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermissions();
    await _initLocalNotifications();
    await _setupForegroundPresentation();
    await _saveInitialToken();
    _listenTokenRefresh();
    _listenForegroundMessages();
    _listenNotificationOpenFromBackground();
    await _handleInitialMessage();

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    AppLogger.info('Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final rawPayload = response.payload;
        AppLogger.info('Local notification tapped. payload=$rawPayload');

        if (rawPayload == null || rawPayload.isEmpty) return;

        final Map<String, dynamic> payload =
            Map<String, dynamic>.from(jsonDecode(rawPayload));

        _handlePayloadNavigation(payload);
      },
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'Used for foreground notifications',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _setupForegroundPresentation() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _listenForegroundMessages() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      AppLogger.info(
        'FG message received: id=${message.messageId}, '
        'title=${message.notification?.title}, '
        'body=${message.notification?.body}, '
        'data=${message.data}',
      );

      final enabled = await _settingsRepo.isEnabled();
      if (!enabled) {
        AppLogger.info('Foreground notification skipped: disabled by user');
        return;
      }

      await _showLocalNotificationFromRemoteMessage(message);
    });
  }

  void _listenNotificationOpenFromBackground() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.info(
        'Notification opened from background: id=${message.messageId}, data=${message.data}',
      );

      final payload = _messageToPayload(message);
      _handlePayloadNavigation(payload);
    });
  }

  Future<void> _handleInitialMessage() async {
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      AppLogger.info(
        'Notification opened from terminated state: '
        'id=${initialMessage.messageId}, data=${initialMessage.data}',
      );

      final payload = _messageToPayload(initialMessage);
      _handlePayloadNavigation(payload);
    }
  }

  Future<void> _showLocalNotificationFromRemoteMessage(
    RemoteMessage message,
  ) async {
    final payload = _messageToPayload(message);
    final payloadJson = jsonEncode(payload);

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Used for foreground notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? payload['title']?.toString() ?? 'Notification',
      message.notification?.body ?? payload['body']?.toString() ?? '',
      details,
      payload: payloadJson,
    );
  }

  Map<String, dynamic> _messageToPayload(RemoteMessage message) {
    return {
      'title': message.notification?.title ?? message.data['title'],
      'body': message.notification?.body ?? message.data['body'],
      'screen': message.data['screen'],
      'itemId': message.data['itemId'],
      'type': message.data['type'],
      'rawData': message.data,
    };
  }

  void _handlePayloadNavigation(Map<String, dynamic> payload) {
    final screen = payload['screen']?.toString();
    final itemId = payload['itemId']?.toString();

    AppLogger.info('Handle payload navigation: $payload');

    if (screen == 'item' && itemId != null && itemId.isNotEmpty) {
      navigatorKey.currentState?.pushNamed(
        AppRoutes.item,
        arguments: {'id': itemId},
      );
      return;
    }

    navigatorKey.currentState?.pushNamed(
      AppRoutes.notificationDetails,
      arguments: payload,
    );
  }

  Future<void> sendTestLocalNotification() async {
    final enabled = await _settingsRepo.isEnabled();
    if (!enabled) {
      AppLogger.info('Test local notification skipped: disabled by user');
      return;
    }

    final payload = {
      'title': 'Test notification',
      'body': 'Tap to open Notification Details',
      'screen': 'details',
      'type': 'test',
    };

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Used for foreground notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _localNotifications.show(
      999,
      'Test notification',
      'Tap to open Notification Details',
      details,
      payload: jsonEncode(payload),
    );

    AppLogger.info('Test local notification shown');
  }

  Future<void> _saveInitialToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _saveTokenToFirestore(token);
  }

  void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) async {
      AppLogger.info('FCM token refreshed');
      await _saveTokenToFirestore(token);
    });
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppLogger.info('Skip saving token: no authenticated user');
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('deviceTokens')
        .doc(token)
        .set({
      'token': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'updatedAt': FieldValue.serverTimestamp(),
      'uid': user.uid,
    }, SetOptions(merge: true));

    AppLogger.info('FCM token saved to Firestore');
  }
}
