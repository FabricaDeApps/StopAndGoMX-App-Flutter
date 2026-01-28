import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/network/api_client.dart';
import 'package:stopandgo/core/services/notification_service.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/firebase_messaging_background.dart';

late FirebaseAnalytics firebaseAnalytics;
late FirebaseAnalyticsObserver firebaseObserver;

typedef AppWidgetBuilder = Widget Function();

class AppBootstrap {
  static Future<void> run({
    required FirebaseOptions firebaseOptions,
    required void Function() initFlavorConfig,
    required AppWidgetBuilder appBuilder,
    String localeTag = 'es_MX',
    String sentryDsn =
        'https://492035ed33b2bfbfaf2b07a1871f910d@o4510723899129856.ingest.us.sentry.io/4510723974037504',
    double sentryTracesSampleRate = 0.0,
  }) async {
    SentryWidgetsFlutterBinding.ensureInitialized();
    initFlavorConfig();
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = FlavorConfig.I.flavor.name;
        options.tracesSampleRate = sentryTracesSampleRate;
        options.sendDefaultPii = false;
      },
      appRunner: () async {
        await Firebase.initializeApp(options: firebaseOptions);
        await initializeDateFormatting(localeTag, null);
        await AppStorage.init();

        firebaseAnalytics = FirebaseAnalytics.instance;
        firebaseObserver = FirebaseAnalyticsObserver(
          analytics: firebaseAnalytics,
        );

        await firebaseAnalytics.setUserProperty(
          name: 'flavor',
          value: FlavorConfig.I.flavor.name,
        );

        final orgId = FlavorConfig.I.organizationId;
        if (orgId != null) {
          await firebaseAnalytics.setUserProperty(
            name: 'organization_id',
            value: orgId.toString(),
          );
        }

        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );

        await NotificationService.initialize();
        await ApiClient.init();

        runApp(appBuilder());
      },
    );
  }
}
