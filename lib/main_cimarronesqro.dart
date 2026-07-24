import 'package:stopandgo/bootstrap/app_bootstrap.dart';
import 'package:stopandgo/firebase_options_cimarronesqro.dart';
import 'package:stopandgo/stopandgo_app.dart';
import 'core/config/flavor_config.dart';

Future<void> main() async {
  await AppBootstrap.run(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    initFlavorConfig: () {
      FlavorConfig.init(
        flavor: AppFlavor.cimarronesqro,
        appName: 'Cimarrones Qro',
        bundleId: 'app.stopandgomx.cimarronesqro',
        isCustom: true,
        organizationId: 428,
      );
    },
    appBuilder: () => StopAndGoApp(),
  );
}
