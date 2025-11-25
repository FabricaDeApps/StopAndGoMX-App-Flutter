import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import 'package:stopandgo/core/storage/app_storage.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1) Permisos FCM (Android/iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    developer.log(
      '🔐 Permisos de notifs: ${settings.authorizationStatus}',
      name: 'FCM',
    );

    // 2) Inicialización LOCAL notifications (Android + iOS)

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      // Si quieres manejar taps en notifs locales:
      // onDidReceiveLocalNotification: ...
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _local.initialize(
      initSettings,
      // onDidReceiveNotificationResponse: (NotificationResponse response) {
      //   // Aquí podrías navegar según payload, etc.
      // },
    );

    // 3) Mensajes en FOREGROUND
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 4) Cuando abren la app desde una notif
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      developer.log(
        '📲 App abierta desde notif: ${message.messageId}',
        name: 'FCM',
      );
      // Aquí navegas si quieres, según message.data
    });

    // 5) Token FCM
    final token = await _messaging.getToken();
    developer.log('🔥 TOKEN FCM: $token', name: 'FCM');

    await AppStorage.setTokenDevice(token);

    // Ejemplo: suscribirse a topic por organización
    // await _messaging.subscribeToTopic('org_${FlavorConfig.I.organizationId}');
  }

  static void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final android = message.notification?.android;

    developer.log(
      '🔔 (FG) Notif: ${notification.title} - ${notification.body}',
      name: 'FCM',
    );

    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Notificaciones',
          importance: Importance.high,
          priority: Priority.high,
          icon: android?.smallIcon,
        ),
      ),
    );
  }
}
