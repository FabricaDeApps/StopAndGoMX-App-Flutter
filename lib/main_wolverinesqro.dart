import 'package:stopandgo/bootstrap/app_bootstrap.dart';
import 'package:stopandgo/firebase_options_wolverinesqro.dart';
import 'package:stopandgo/stopandgo_app.dart';
import 'core/config/flavor_config.dart';

Future<void> main() async {
  await AppBootstrap.run(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    initFlavorConfig: () {
      FlavorConfig.init(
        flavor: AppFlavor.wolverinesqro,
        appName: 'Wolverines',
        bundleId: 'app.stopandgomx.wolverinesqro',
        organizationId: 17,
      );
    },
    appBuilder: () => StopAndGoApp(),
  );
}
