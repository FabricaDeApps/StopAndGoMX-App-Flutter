import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:stopandgo/app_binding.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/routes/app_routes.dart';
import 'core/config/flavor_config.dart';
import 'core/network/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX', null);
  await AppStorage.init();
  FlavorConfig.init(
    flavor: AppFlavor.main,
    appName: 'StopAndGoMX',
    bundleId: 'app.stopandgomx.main',
    organizationId: 1,
  );

  await ApiClient.init();

  runApp(const StopAndGoApp());
}

class StopAndGoApp extends StatelessWidget {
  const StopAndGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: FlavorConfig.I.appName,
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(),
      initialRoute: Routes.splash,
      getPages: AppPages.routes,
    );
  }
}
