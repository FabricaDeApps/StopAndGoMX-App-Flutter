import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:stopandgo/app_binding.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/theme/theme_controller.dart';
import 'package:stopandgo/routes/app_routes.dart';
import 'package:stopandgo/bootstrap/app_bootstrap.dart'; // para firebaseObserver

class StopAndGoApp extends StatelessWidget {
  StopAndGoApp({super.key});

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
        navigatorObservers: [
          firebaseObserver,
          if (kReleaseMode) SentryNavigatorObserver(),
        ],
      );
    });
  }
}
