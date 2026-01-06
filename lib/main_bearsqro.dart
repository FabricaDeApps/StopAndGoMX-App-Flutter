import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:stopandgo/app_binding.dart';
import 'package:stopandgo/core/services/notification_service.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/theme/theme_controller.dart';
import 'package:stopandgo/firebase_messaging_background.dart';
import 'package:stopandgo/firebase_options_bearsqro.dart';
import 'package:stopandgo/routes/app_routes.dart';
import 'core/config/flavor_config.dart';
import 'core/network/api_client.dart';

late FirebaseAnalytics firebaseAnalytics;
late FirebaseAnalyticsObserver firebaseObserver;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es_MX', null);
  await AppStorage.init();
  FlavorConfig.init(
    flavor: AppFlavor.bearsqro,
    appName: 'Bears Querétaro',
    bundleId: 'app.stopandgomx.bearsqro',
    organizationId: 18,
  );

  firebaseAnalytics = FirebaseAnalytics.instance;
  firebaseObserver = FirebaseAnalyticsObserver(analytics: firebaseAnalytics);

  await firebaseAnalytics.setUserProperty(
    name: 'flavor',
    value: FlavorConfig.I.flavor.name,
  );

  if (FlavorConfig.I.organizationId != null) {
    await firebaseAnalytics.setUserProperty(
      name: 'organization_id',
      value: FlavorConfig.I.organizationId.toString(),
    );
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();
  await ApiClient.init();

  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

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
        locale: const Locale('es', 'MX'),
        fallbackLocale: const Locale('en', 'US'),
        supportedLocales: const [Locale('es', 'MX'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      );
    });
  }
}
