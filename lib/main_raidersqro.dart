import 'package:stopandgo/bootstrap/app_bootstrap.dart';
import 'package:stopandgo/firebase_options_raidersqro.dart';
import 'package:stopandgo/stopandgo_app.dart';
import 'core/config/flavor_config.dart';

Future<void> main() async {
  await AppBootstrap.run(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    initFlavorConfig: () {
      FlavorConfig.init(
        flavor: AppFlavor.raidersqro,
        appName: 'Raiders Qro',
        bundleId: 'app.stopandgomx.raidersqro',
        isCustom: true,
        organizationId: 15,
        paymentProvider: 'mercadopago',
      );
    },
    appBuilder: () => StopAndGoApp(),
  );
}
