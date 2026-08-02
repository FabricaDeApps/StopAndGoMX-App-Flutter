import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/routes/app_routes.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static int? _pendingGameId;
  static Map<String, dynamic>? _pendingBirthdayGreetingArgs;

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

    // 1.1) iOS: mostrar notifs en foreground también
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2) Inicialización LOCAL notifications (Android + iOS)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      // ya pedimos permiso arriba con FCM
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _local.initialize(
      initSettings,
      // onDidReceiveNotificationResponse: (NotificationResponse response) {}
    );

    // 3) Mensajes en FOREGROUND
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 4) Cuando abren la app desde una notif
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      developer.log(
        '📲 App abierta desde notif: ${message.messageId}',
        name: 'FCM',
      );
      _handleNavigationMessage(message);
    });

    // 4.1) Cuando la app estaba terminada y la abrieron desde notif
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      developer.log(
        '🚀 App iniciada desde notif: ${initialMessage.messageId}',
        name: 'FCM',
      );
      _handleNavigationMessage(initialMessage);
    }

    // 5) Token FCM. En iOS, APNs puede tardar en entregar su token
    // (y en el simulador puede no entregarlo), por lo que esto no debe
    // impedir que la aplicación arranque.
    try {
      final token = await _messaging.getToken();
      await AppStorage.setTokenDevice(token);
      await debugPrintFcmTokens();

      developer.log('📡 FCM TOKEN GUARDADO: $token', name: 'FCM');
    } on FirebaseException catch (error, stackTrace) {
      developer.log(
        'FCM todavía no está disponible: ${error.code}',
        name: 'FCM',
        error: error,
        stackTrace: stackTrace,
      );
    }

    // Ejemplo: suscripción a topic por organización (si luego quieres)
    // await _messaging.subscribeToTopic('org_${FlavorConfig.I.organizationId}');
  }

  /// 👇 OJO: static, para poder llamarla desde initialize()
  static Future<void> debugPrintFcmTokens() async {
    final fcmToken = await _messaging.getToken();
    final apnsToken = await _messaging.getAPNSToken();

    developer.log('🔥 iOS FCM TOKEN: $fcmToken', name: 'FCM');
    developer.log('🍎 APNS TOKEN: $apnsToken', name: 'FCM');
  }

  static void _onForegroundMessage(RemoteMessage message) {
    final handledByNavigation = _handleNavigationMessage(message);
    if (handledByNavigation) return;

    final notification = message.notification;
    if (notification == null) return;

    developer.log(
      '🔔 (FG) Notif: ${notification.title} - ${notification.body}',
      name: 'FCM',
    );

    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Notificaciones',
          importance: Importance.high,
          priority: Priority.high,
        ),
        // Si quieres también configuración específica para iOS:
        // iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static bool consumePendingNavigationIfAny() {
    final birthdayArgs = _pendingBirthdayGreetingArgs;
    if (birthdayArgs != null) {
      _pendingBirthdayGreetingArgs = null;
      _goToBirthdayGreeting(birthdayArgs);
      return true;
    }

    final gameId = _pendingGameId;
    if (gameId == null || gameId <= 0) return false;
    _pendingGameId = null;
    _goToGameDetail(gameId);
    return true;
  }

  static bool _handleNavigationMessage(RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return false;

    final type = (data['type'] ?? '').toString().trim().toLowerCase();

    if (!_isLoggedIn()) {
      developer.log(
        '🔕 Se ignoró $type porque no hay sesión activa',
        name: 'FCM',
      );
      return false;
    }

    if (type == 'game_today') {
      final gameId = int.tryParse((data['game_id'] ?? '').toString());
      if (gameId == null || gameId <= 0) return false;

      if (_canNavigateNow()) {
        _goToGameDetail(gameId);
      } else {
        _pendingGameId = gameId;
        developer.log(
          '🧭 game_today en cola para abrir al entrar a Home (game_id=$gameId)',
          name: 'FCM',
        );
      }
      return true;
    }

    if (type == 'birthday_greeting') {
      final birthdayArgs = _birthdayGreetingArgsFromMessage(message);
      if (_canNavigateNow()) {
        _goToBirthdayGreeting(birthdayArgs);
      } else {
        _pendingBirthdayGreetingArgs = birthdayArgs;
        developer.log(
          '🧭 birthday_greeting en cola para abrir al entrar a Home',
          name: 'FCM',
        );
      }
      return true;
    }

    return false;
  }

  static bool _isLoggedIn() => AppStorage.getUser() != null;

  static bool _canNavigateNow() => Get.key.currentState != null;

  static void _goToGameDetail(int gameId) {
    final currentRoute = Get.currentRoute;
    final currentArgs = Get.arguments;
    if (currentRoute == Routes.gameDetail &&
        currentArgs is Map &&
        currentArgs['id'] == gameId) {
      return;
    }

    Get.toNamed(Routes.gameDetail, arguments: {'id': gameId});
    developer.log(
      '🏟️ Navegando a game detail desde notif (id=$gameId)',
      name: 'FCM',
    );
  }

  static Map<String, dynamic> _birthdayGreetingArgsFromMessage(
    RemoteMessage message,
  ) {
    final data = message.data;
    final notification = message.notification;
    final user = AppStorage.getUser();

    return <String, dynamic>{
      'title': notification?.title?.trim().isNotEmpty == true
          ? notification!.title!.trim()
          : 'Feliz cumpleaños',
      'body': notification?.body?.trim() ?? '',
      'organization_name':
          data['organization_name']?.toString().trim() ??
          AppStorage.getOrganization()?.name ??
          '',
      'recipient_name':
          data['recipient_name']?.toString().trim() ??
          AppStorage.getSelectedPlayerName() ??
          user?.name ??
          '',
      'date': data['date']?.toString().trim() ?? '',
      'avatar_url': user?.photoUrl ?? '',
    };
  }

  static void _goToBirthdayGreeting(Map<String, dynamic> args) {
    if (Get.currentRoute == Routes.birthdayGreeting) {
      Get.offNamed(Routes.birthdayGreeting, arguments: args);
    } else {
      Get.toNamed(Routes.birthdayGreeting, arguments: args);
    }

    developer.log('🎂 Navegando a birthday greeting desde notif', name: 'FCM');
  }
}
