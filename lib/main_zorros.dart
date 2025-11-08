import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/app_binding.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/theme/theme_controller.dart';
import 'package:stopandgo/routes/app_routes.dart';
import 'core/config/flavor_config.dart';
import 'core/network/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.init();
  FlavorConfig.init(
    flavor: AppFlavor.zorros,
    appName: 'Zorros Football Academy',
    bundleId: 'app.stopandgomx.zorros',
    organizationId: 2,
  );

  await ApiClient.init();

  runApp(ZorrosApp());
}

class ZorrosApp extends StatelessWidget {
  ZorrosApp({super.key});

  final themeController = Get.put(ThemeController());

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: FlavorConfig.I.appName,
      theme: themeController.theme.value,
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(),
      initialRoute: Routes.splash,
      getPages: AppPages.routes,
    );
  }
}
