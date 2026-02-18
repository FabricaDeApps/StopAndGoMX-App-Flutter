import 'package:stopandgo/bootstrap/app_bootstrap.dart';
import 'package:stopandgo/firebase_options_bearsqro.dart';
import 'package:stopandgo/stopandgo_app.dart';
import 'core/config/flavor_config.dart';

Future<void> main() async {
  await AppBootstrap.run(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    initFlavorConfig: () {
      FlavorConfig.init(
        flavor: AppFlavor.bearsqro,
        appName: 'Bears Querétaro',
        bundleId: 'app.stopandgomx.bearsqro',
        isCustom: true,
        organizationId: 18,
        paymentProvider: 'mercadopago',
      );
    },
    appBuilder: () => StopAndGoApp(),
  );
}
