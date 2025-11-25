import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:stopandgo/app_binding.dart';
import 'package:stopandgo/core/services/notification_service.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/theme/theme_controller.dart';
import 'package:stopandgo/firebase_messaging_background.dart';
import 'package:stopandgo/firebase_options_raidersqro.dart';
import 'package:stopandgo/routes/app_routes.dart';
import 'core/config/flavor_config.dart';
import 'core/network/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es_MX', null);
  await AppStorage.init();
  FlavorConfig.init(
    flavor: AppFlavor.raidersqro,
    appName: 'Raiders Qro',
    bundleId: 'app.stopandgomx.raidersqro',
    organizationId: 15,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();
  await ApiClient.init();

  runApp(ZorrosApp());
}

class ZorrosApp extends StatelessWidget {
  ZorrosApp({super.key});

  final themeController = Get.put(ThemeController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return GetMaterialApp(
        title: FlavorConfig.I.appName,
        theme: themeController.theme.value,
        debugShowCheckedModeBanner: false,
        initialBinding: AppBinding(),
        initialRoute: Routes.splash,
        getPages: AppPages.routes,
      );
    });
  }
}
