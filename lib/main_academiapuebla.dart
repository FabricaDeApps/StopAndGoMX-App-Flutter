import 'package:stopandgo/bootstrap/app_bootstrap.dart';
import 'package:stopandgo/firebase_options_academiapuebla.dart';
import 'package:stopandgo/stopandgo_app.dart';

import 'core/config/flavor_config.dart';

Future<void> main() async {
  await AppBootstrap.run(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    initFlavorConfig: () {
      FlavorConfig.init(
        flavor: AppFlavor.academiapuebla,
        appName: 'Academia Puebla FC MID',
        bundleId: 'app.stopandgomx.academiapuebla',
        isCustom: true,
        organizationId: 81,
      );
    },
    appBuilder: () => StopAndGoApp(),
  );
}
