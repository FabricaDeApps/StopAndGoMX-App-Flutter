import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as developer;

/// Handler para mensajes en background.
/// IMPORTANTE: debe ser una función top-level o static.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log(
    '🔔 (BG) Mensaje FCM recibido: ${message.messageId}',
    name: 'FCM_BACKGROUND',
  );

  // Aquí podrías inicializar Firebase si quisieras hacer lógica extra
  // pero para logs básicos no es necesario.
}
