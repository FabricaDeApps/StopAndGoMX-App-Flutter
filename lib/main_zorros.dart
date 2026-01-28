import 'package:stopandgo/bootstrap/app_bootstrap.dart';
import 'package:stopandgo/firebase_options_zorros.dart';
import 'package:stopandgo/stopandgo_app.dart';
import 'core/config/flavor_config.dart';

Future<void> main() async {
  await AppBootstrap.run(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    initFlavorConfig: () {
      FlavorConfig.init(
        flavor: AppFlavor.zorros,
        appName: 'Zorros Football Academy',
        bundleId: 'app.stopandgomx.zorros',
        organizationId: 2,
      );
    },
    appBuilder: () => StopAndGoApp(),
  );
}
