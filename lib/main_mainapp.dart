import 'package:stopandgo/bootstrap/app_bootstrap.dart';
import 'package:stopandgo/firebase_options_mainapp.dart';
import 'package:stopandgo/stopandgo_app.dart';
import 'core/config/flavor_config.dart';

Future<void> main() async {
  await AppBootstrap.run(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    initFlavorConfig: () {
      FlavorConfig.init(
        flavor: AppFlavor.main,
        appName: 'StopAndGoMX',
        bundleId: 'app.stopandgomx.main',
        organizationId: 1,
        paymentProvider: 'mercadopago',
      );
    },
    appBuilder: () => StopAndGoApp(),
  );
}
